const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');
const { sendInvitationEmail } = require('../utils/emailService');

// Generate a unique invitation token
function generateInvitationToken() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const part1 = Array.from({ length: 8 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  const part2 = Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  const part3 = Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `${part1}-${part2}-${part3}`;
}

// POST create invitation for a company
router.post('/', async (req, res) => {
  try {
    // Check if company_invitations table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'company_invitations'
      )
    `);
    
    if (!tableCheck.rows[0].exists) {
      console.error('company_invitations table does not exist. Running migration...');
      // Try to create table
      try {
        const schemaPath = require('path').join(__dirname, '../schema_company_invitations.sql');
        const fs = require('fs');
        if (fs.existsSync(schemaPath)) {
          const schema = fs.readFileSync(schemaPath, 'utf8');
          // Replace uuid_generate_v4() with gen_random_uuid() for compatibility
          const schemaFixed = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
          await pool.query(schemaFixed);
          console.log('✅ company_invitations table created');
        } else {
          // Create table manually
          await pool.query(`
            CREATE TABLE IF NOT EXISTS company_invitations (
              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
              company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
              email VARCHAR(255) NOT NULL,
              invitation_token VARCHAR(255) UNIQUE NOT NULL,
              role VARCHAR(50) NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'supervisor', 'staff')),
              invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
              expires_at TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
              used_at TIMESTAMP NULL,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
          `);
          await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_company_invitations_token ON company_invitations(invitation_token);
            CREATE INDEX IF NOT EXISTS idx_company_invitations_email ON company_invitations(email);
            CREATE INDEX IF NOT EXISTS idx_company_invitations_company_id ON company_invitations(company_id);
          `);
          console.log('✅ company_invitations table created manually');
        }
      } catch (createError) {
        console.error('Failed to create company_invitations table:', createError.message);
        return res.status(500).json({ 
          error: 'company_invitations table does not exist. Please run migration first.',
          details: createError.message 
        });
      }
    }

    const {
      company_id,
      email,
      role = 'admin',
      invited_by,
      expires_in_days = 7
    } = req.body;

    if (!company_id || !email) {
      return res.status(400).json({ error: 'Company ID and email are required' });
    }

    // Validate role
    const validRoles = ['admin', 'supervisor', 'staff'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({ 
        error: `Invalid role. Must be one of: ${validRoles.join(', ')}`,
        received: role 
      });
    }

    // Check if company exists
    const companyResult = await pool.query('SELECT id, name FROM companies WHERE id = $1', [company_id]);
    if (companyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }

    // Check if invitation already exists for this email and company
    const existingInvitation = await pool.query(
      'SELECT * FROM company_invitations WHERE company_id = $1 AND email = $2 AND used_at IS NULL',
      [company_id, email.toLowerCase()]
    );

    if (existingInvitation.rows.length > 0) {
      // Return existing invitation
      return res.json(existingInvitation.rows[0]);
    }

    // Generate unique token
    let token = generateInvitationToken();
    let tokenExists = true;
    let attempts = 0;
    
    // Ensure token is unique
    while (tokenExists && attempts < 10) {
      const tokenCheck = await pool.query(
        'SELECT id FROM company_invitations WHERE invitation_token = $1',
        [token]
      );
      tokenExists = tokenCheck.rows.length > 0;
      if (tokenExists) {
        token = generateInvitationToken();
        attempts++;
      }
    }

    if (tokenExists) {
      return res.status(500).json({ error: 'Failed to generate unique invitation token' });
    }

    // Calculate expiration date
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + expires_in_days);

    // Create invitation - generate UUID for id
    const invitationId = uuidv4();
    const result = await pool.query(
      `INSERT INTO company_invitations 
       (id, company_id, email, invitation_token, role, invited_by, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [invitationId, company_id, email.toLowerCase(), token, role, invited_by || null, expiresAt]
    );

    const invitation = result.rows[0];

    // Send invitation email (non-blocking - don't fail if email fails)
    // Use base_url from request, or role-specific URL, or APP_BASE_URL, or default to localhost for dev
    // Admin invitations go to admin app, supervisor/staff go to staff app
    const defaultUrl = role === 'admin' 
      ? (process.env.ADMIN_APP_BASE_URL || process.env.APP_BASE_URL || 'http://localhost:3000')
      : (process.env.STAFF_APP_BASE_URL || process.env.APP_BASE_URL || 'http://localhost:3000');
    const baseUrl = req.body.base_url || defaultUrl;
    
    // Only send email if SMTP is configured
    if (process.env.SMTP_USER && process.env.SMTP_PASSWORD) {
      sendInvitationEmail(
        invitation.email,
        invitation.invitation_token,
        companyResult.rows[0].name,
        invitation.role,
        invitation.expires_at,
        baseUrl
      ).then(() => {
        console.log(`✅ Invitation email sent to ${invitation.email}`);
      }).catch((emailError) => {
        console.error('❌ Failed to send invitation email (invitation still created):', emailError.message);
        // Don't throw - invitation is created successfully even if email fails
        // Admin can still use the invitation code/link manually
      });
    } else {
      console.warn('⚠️  Email not configured (SMTP_USER/SMTP_PASSWORD not set). Invitation created but email not sent.');
      console.warn('   To enable email sending, configure SMTP settings in .env file. See EMAIL_SETUP.md');
    }

    res.status(201).json(invitation);
  } catch (error) {
    console.error('Error creating invitation:', error);
    console.error('Error details:', error.message);
    console.error('Error stack:', error.stack);
    res.status(500).json({ 
      error: 'Failed to create invitation',
      details: error.message 
    });
  }
});

// GET invitation by token
router.get('/token/:token', async (req, res) => {
  try {
    const { token } = req.params;
    
    const result = await pool.query(
      `SELECT 
        ci.*,
        c.name as company_name,
        c.email as company_email,
        c.phone_number as company_phone,
        c.address as company_address
       FROM company_invitations ci
       JOIN companies c ON ci.company_id = c.id
       WHERE ci.invitation_token = $1`,
      [token.toUpperCase()]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Invitation not found' });
    }

    const invitation = result.rows[0];
    
    // Check if invitation is expired
    if (new Date(invitation.expires_at) < new Date()) {
      return res.status(410).json({ error: 'Invitation has expired' });
    }

    // Check if invitation is already used
    if (invitation.used_at) {
      return res.status(410).json({ error: 'Invitation has already been used' });
    }

    res.json(invitation);
  } catch (error) {
    console.error('Error fetching invitation:', error);
    res.status(500).json({ error: 'Failed to fetch invitation' });
  }
});

// GET invitations for a company
router.get('/company/:companyId', async (req, res) => {
  try {
    const { companyId } = req.params;
    
    const result = await pool.query(
      `SELECT ci.*, u.first_name as invited_by_name, u.last_name as invited_by_last_name
       FROM company_invitations ci
       LEFT JOIN users u ON ci.invited_by = u.id
       WHERE ci.company_id = $1
       ORDER BY ci.created_at DESC`,
      [companyId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching invitations:', error);
    res.status(500).json({ error: 'Failed to fetch invitations' });
  }
});

// PUT mark invitation as used
router.put('/:id/use', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'UPDATE company_invitations SET used_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Invitation not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error marking invitation as used:', error);
    res.status(500).json({ error: 'Failed to mark invitation as used' });
  }
});

// POST resend invitation email
router.post('/:id/resend', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get invitation to determine role
    const invitationResult = await pool.query(
      `SELECT ci.*, c.name as company_name
       FROM company_invitations ci
       JOIN companies c ON ci.company_id = c.id
       WHERE ci.id = $1`,
      [id]
    );

    if (invitationResult.rows.length === 0) {
      return res.status(404).json({ error: 'Invitation not found' });
    }

    const invitation = invitationResult.rows[0];

    // Check if invitation is already used
    if (invitation.used_at) {
      return res.status(400).json({ error: 'Cannot resend used invitation' });
    }

    // Check if invitation is expired
    if (new Date(invitation.expires_at) < new Date()) {
      return res.status(400).json({ error: 'Cannot resend expired invitation' });
    }

    // Determine baseUrl based on invitation role
    const invitationRole = invitation.role || 'admin';
    const defaultUrl = invitationRole === 'admin'
      ? (process.env.ADMIN_APP_BASE_URL || process.env.APP_BASE_URL || 'http://localhost:3000')
      : (process.env.STAFF_APP_BASE_URL || process.env.APP_BASE_URL || 'http://localhost:3000');
    const baseUrl = req.body.base_url || defaultUrl;

    // Send invitation email
    await sendInvitationEmail(
      invitation.email,
      invitation.invitation_token,
      invitation.company_name,
      invitation.role,
      invitation.expires_at,
      baseUrl
    );

    res.json({ message: 'Invitation email resent successfully' });
  } catch (error) {
    console.error('Error resending invitation email:', error);
    res.status(500).json({ error: 'Failed to resend invitation email', details: error.message });
  }
});

// DELETE invitation
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'DELETE FROM company_invitations WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Invitation not found' });
    }

    res.json({ message: 'Invitation deleted successfully' });
  } catch (error) {
    console.error('Error deleting invitation:', error);
    res.status(500).json({ error: 'Failed to delete invitation' });
  }
});

module.exports = router;

