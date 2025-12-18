const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { sendCredentialsEmail } = require('../utils/emailService');

// Generate a secure random password
function generatePassword(length = 12) {
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  const randomBytes = crypto.randomBytes(length);
  let password = '';
  for (let i = 0; i < length; i++) {
    password += charset[randomBytes[i] % charset.length];
  }
  return password;
}

// POST create invitation request and auto-create account
router.post('/', async (req, res) => {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const {
      email,
      first_name,
      last_name,
      company_name,
      phone_number,
      message,
    } = req.body;

    // Validate required fields
    if (!email || !first_name || !last_name) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: 'Email, first name, and last name are required'
      });
    }

    // Company name is now mandatory
    if (!company_name || typeof company_name !== 'string' || company_name.trim().length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: 'Company name is required. Please provide your company name to create an account.'
      });
    }

    const normalizedEmail = email.toLowerCase().trim();

    // Check if user with this email already exists
    const existingUser = await client.query(
      'SELECT id FROM users WHERE email = $1',
      [normalizedEmail]
    );

    if (existingUser.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: 'An account with this email already exists. Please log in instead.' 
      });
    }

    // Find or create company (company_name is now mandatory)
    const trimmedCompanyName = company_name.trim();
    let companyId = null;
    
    // Check if company with this name already exists (case-insensitive)
    const companyResult = await client.query(
      'SELECT id FROM companies WHERE LOWER(name) = LOWER($1)',
      [trimmedCompanyName]
    );

    if (companyResult.rows.length > 0) {
      // Company exists - use it
      companyId = companyResult.rows[0].id;
    } else {
      // Create new company with the provided name
      const newCompanyId = uuidv4();
      await client.query(
        `INSERT INTO companies (id, name, email, subscription_tier, max_users)
         VALUES ($1, $2, $3, $4, $5)`,
        [newCompanyId, trimmedCompanyName, normalizedEmail, 'basic', 50]
      );
      companyId = newCompanyId;
    }

    // Generate secure password
    const plainPassword = generatePassword(12);
    const passwordHash = await bcrypt.hash(plainPassword, 10);

    // Create user account (must_change_password = true for system-generated passwords)
    const userId = uuidv4();
    await client.query(
      `INSERT INTO users 
       (id, email, password_hash, first_name, last_name, role, phone_number, company_id, is_active, must_change_password)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [
        userId,
        normalizedEmail,
        passwordHash,
        first_name.trim(),
        last_name.trim(),
        'admin',
        phone_number?.trim() || null,
        companyId,
        true,
        true, // Force password change on first login
      ]
    );

    // Create invitation request record (marked as approved)
    const requestId = uuidv4();
    const result = await client.query(
      `INSERT INTO invitation_requests 
       (id, email, first_name, last_name, company_name, phone_number, message, status, approved_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP)
       RETURNING *`,
      [
        requestId,
        normalizedEmail,
        first_name.trim(),
        last_name.trim(),
        company_name?.trim() || null,
        phone_number?.trim() || null,
        message?.trim() || null,
        'approved',
      ]
    );

    const request = result.rows[0];

    await client.query('COMMIT');

    // Send credentials email (non-blocking)
    const baseUrl = req.body.base_url || process.env.APP_BASE_URL || 'http://localhost:3000';
    
    if (process.env.SMTP_USER && process.env.SMTP_PASSWORD) {
      sendCredentialsEmail(
        normalizedEmail,
        plainPassword,
        first_name,
        company_name || 'your company',
        baseUrl
      ).catch((emailError) => {
        console.error('Failed to send credentials email:', emailError.message);
      });
    }

    res.status(201).json({
      success: true,
      message: 'Your account has been created successfully! Check your email for your login credentials.',
      request: request,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating account:', error);
    res.status(500).json({ 
      error: 'Failed to create account',
      details: error.message 
    });
  } finally {
    client.release();
  }
});

// GET all invitation requests (for superadmins)
router.get('/', async (req, res) => {
  try {
    // TODO: Add authentication check to ensure only superadmins can access
    const { status } = req.query;

    let query = 'SELECT * FROM invitation_requests';
    const params = [];

    if (status) {
      query += ' WHERE status = $1';
      params.push(status);
    }

    query += ' ORDER BY created_at DESC';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching invitation requests:', error);
    res.status(500).json({ error: 'Failed to fetch invitation requests' });
  }
});

// PUT approve invitation request and create invitation
router.put('/:id/approve', async (req, res) => {
  try {
    // TODO: Add authentication check to ensure only superadmins can approve
    const { id } = req.params;
    const { company_id, role = 'admin', expires_in_days = 7 } = req.body;

    if (!company_id) {
      return res.status(400).json({ error: 'Company ID is required to approve request' });
    }

    // Get the request
    const requestResult = await pool.query(
      'SELECT * FROM invitation_requests WHERE id = $1',
      [id]
    );

    if (requestResult.rows.length === 0) {
      return res.status(404).json({ error: 'Invitation request not found' });
    }

    const request = requestResult.rows[0];

    if (request.status !== 'pending') {
      return res.status(400).json({ 
        error: `Cannot approve request with status: ${request.status}` 
      });
    }

    // Check if company exists
    const companyResult = await pool.query(
      'SELECT id, name FROM companies WHERE id = $1',
      [company_id]
    );

    if (companyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }

    // Generate invitation token (using same logic as company-invitations.js)
    function generateInvitationToken() {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      const part1 = Array.from({ length: 8 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
      const part2 = Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
      const part3 = Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
      return `${part1}-${part2}-${part3}`;
    }

    let token = generateInvitationToken();
    let tokenExists = true;
    let attempts = 0;
    
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

    // Create invitation
    const invitationId = uuidv4();
    const invitationResult = await pool.query(
      `INSERT INTO company_invitations 
       (id, company_id, email, invitation_token, role, invited_by, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        invitationId,
        company_id,
        request.email,
        token,
        role,
        req.body.approved_by || null, // ID of superadmin approving
        expiresAt,
      ]
    );

    const invitation = invitationResult.rows[0];

    // Update request status to approved
    await pool.query(
      'UPDATE invitation_requests SET status = $1, approved_at = CURRENT_TIMESTAMP WHERE id = $2',
      ['approved', id]
    );

    // Send invitation email
    const baseUrl = req.body.base_url || process.env.APP_BASE_URL || 'http://localhost:3000';
    
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
        console.error('❌ Failed to send invitation email:', emailError.message);
      });
    }

    res.json({
      success: true,
      message: 'Invitation request approved and invitation sent',
      invitation: invitation,
    });
  } catch (error) {
    console.error('Error approving invitation request:', error);
    res.status(500).json({ 
      error: 'Failed to approve invitation request',
      details: error.message 
    });
  }
});

// PUT reject invitation request
router.put('/:id/reject', async (req, res) => {
  try {
    // TODO: Add authentication check to ensure only superadmins can reject
    const { id } = req.params;
    const { rejection_reason } = req.body;

    const result = await pool.query(
      `UPDATE invitation_requests 
       SET status = $1, rejected_at = CURRENT_TIMESTAMP, rejection_reason = $2
       WHERE id = $3 AND status = 'pending'
       RETURNING *`,
      ['rejected', rejection_reason || null, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Invitation request not found or already processed' });
    }

    res.json({
      success: true,
      message: 'Invitation request rejected',
      request: result.rows[0],
    });
  } catch (error) {
    console.error('Error rejecting invitation request:', error);
    res.status(500).json({ error: 'Failed to reject invitation request' });
  }
});

module.exports = router;

