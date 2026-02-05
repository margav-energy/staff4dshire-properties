const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const { buildCompanyWhereClause, canAccessCompany } = require('../middleware/companyFilter');

// GET user photo by ID (must come before /:id route)
router.get('/:id/photo', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get user's photo_url
    const result = await pool.query(
      'SELECT photo_url FROM users WHERE id = $1',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const photoUrl = result.rows[0].photo_url;
    
    // If photo_url is a base64 data URL, return it directly
    if (photoUrl && photoUrl.startsWith('data:image')) {
      // Extract base64 data and mime type
      const matches = photoUrl.match(/^data:image\/(\w+);base64,(.+)$/);
      if (matches) {
        const mimeType = matches[1];
        const base64Data = matches[2];
        const buffer = Buffer.from(base64Data, 'base64');
        
        res.setHeader('Content-Type', `image/${mimeType}`);
        res.setHeader('Content-Length', buffer.length);
        res.setHeader('Cache-Control', 'public, max-age=31536000'); // Cache for 1 year
        return res.send(buffer);
      }
    }
    
    // If photo_url is a network URL, redirect to it
    if (photoUrl && (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))) {
      return res.redirect(photoUrl);
    }
    
    // If pref: URL or no photo, return 404
    return res.status(404).json({ error: 'Photo not found' });
  } catch (error) {
    console.error('Error fetching user photo:', error);
    res.status(500).json({ error: 'Failed to fetch photo' });
  }
});

// GET all users (filtered by company unless superadmin)
router.get('/', async (req, res) => {
  try {
    // TODO: Set req.user from authentication middleware
    // For now, allow query param to specify user context
    const userId = req.query.userId; // Temporary: get from query param
    
    console.log('[USERS API] GET /users - userId:', userId);
    
    let query = 'SELECT * FROM users';
    let params = [];
    
    if (userId) {
      // Get user's company_id and superadmin status
      const userResult = await pool.query(
        'SELECT company_id, is_superadmin, role FROM users WHERE id = $1',
        [userId]
      );
      
      if (userResult.rows.length > 0) {
        const user = userResult.rows[0];
        req.user = user; // Set for middleware
        
        console.log('[USERS API] User found:', {
          userId,
          company_id: user.company_id,
          is_superadmin: user.is_superadmin,
          role: user.role
        });
        
        // Superadmins can see all users
        if (!user.is_superadmin && user.role !== 'superadmin') {
          // Regular users can only see users from their company
          // Only filter if company_id exists (non-null)
          if (user.company_id) {
            // Explicitly exclude users with NULL company_id and filter by matching company_id
            query += ' WHERE company_id IS NOT NULL AND company_id = $1';
            params = [user.company_id];
            console.log('[USERS API] Filtering by company_id:', user.company_id, '(excluding NULL company_id)');
          } else {
            // User has no company_id - return empty list
            query += ' WHERE 1=0'; // Always false condition
            params = [];
            console.log('[USERS API] User has no company_id - returning empty list');
          }
        } else {
          console.log('[USERS API] Superadmin detected - returning all users');
        }
      } else {
        console.log('[USERS API] User not found for userId:', userId);
      }
    } else {
      console.log('[USERS API] No userId provided - returning all users');
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await pool.query(query, params);
    
    console.log(`[USERS API] Returning ${result.rows.length} users`);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Failed to fetch users', message: error.message });
  }
});

// GET user by email (helper endpoint)
router.get('/by-email/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const normalizedEmail = email.toLowerCase().trim();
    
    // Check which columns exist
    const columnCheck = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name IN ('company_id', 'is_superadmin')
    `);
    const existingColumns = columnCheck.rows.map(row => row.column_name);
    const hasCompanyId = existingColumns.includes('company_id');
    const hasIsSuperadmin = existingColumns.includes('is_superadmin');
    
    // Build select query based on available columns
    let selectColumns = ['id', 'email', 'first_name', 'last_name', 'role', 'is_active'];
    if (hasCompanyId) {
      selectColumns.push('company_id');
    }
    if (hasIsSuperadmin) {
      selectColumns.push('is_superadmin');
    }
    
    const result = await pool.query(
      `SELECT ${selectColumns.join(', ')} FROM users WHERE LOWER(TRIM(email)) = $1`,
      [normalizedEmail]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Add null values for missing columns
    const user = result.rows[0];
    if (!hasCompanyId) {
      user.company_id = null;
    }
    if (!hasIsSuperadmin) {
      user.is_superadmin = false;
    }
    
    res.json(user);
  } catch (error) {
    console.error('Error fetching user by email:', error);
    res.status(500).json({ error: 'Failed to fetch user', message: error.message });
  }
});

// GET user by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// POST create user
router.post('/', async (req, res) => {
  try {
    const {
      email,
      password,
      password_hash, // Allow pre-hashed passwords
      first_name,
      last_name,
      role,
      phone_number,
      photo_url,
      is_active = true,
      company_id,
      created_by_user_id, // User ID of the admin creating this user (for company context)
    } = req.body;

    // Validate required fields
    if (!email || !first_name || !last_name || !role) {
      return res.status(400).json({ error: 'Missing required fields: email, first_name, last_name, role' });
    }

    // Check if password or password_hash is provided
    if (!password && !password_hash) {
      return res.status(400).json({ error: 'Either password or password_hash must be provided' });
    }

    // Hash password if provided (not already hashed)
    let hashedPassword;
    if (password) {
      const saltRounds = 10;
      hashedPassword = await bcrypt.hash(password.trim(), saltRounds);
      console.log('[USERS API] Password hashed successfully');
    } else {
      hashedPassword = password_hash;
      console.log('[USERS API] Using provided password_hash');
    }

    // Determine company_id
    let finalCompanyId = company_id;
    
    // If company_id not provided, try to get it from the creating user
    if (!finalCompanyId && created_by_user_id) {
      const creatorResult = await pool.query(
        'SELECT company_id FROM users WHERE id = $1',
        [created_by_user_id]
      );
      if (creatorResult.rows.length > 0 && creatorResult.rows[0].company_id) {
        finalCompanyId = creatorResult.rows[0].company_id;
        console.log('[USERS API] Using creator\'s company_id:', finalCompanyId);
      }
    }
    
    // Also check req.query.userId as fallback
    if (!finalCompanyId && req.query.userId) {
      const creatorResult = await pool.query(
        'SELECT company_id FROM users WHERE id = $1',
        [req.query.userId]
      );
      if (creatorResult.rows.length > 0 && creatorResult.rows[0].company_id) {
        finalCompanyId = creatorResult.rows[0].company_id;
        console.log('[USERS API] Using query userId\'s company_id:', finalCompanyId);
      }
    }

    const id = uuidv4();
    const result = await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name, role, phone_number, photo_url, is_active, company_id, is_superadmin)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [id, email, hashedPassword, first_name, last_name, role, phone_number || null, photo_url || null, is_active, finalCompanyId || null, is_superadmin || role === 'superadmin']
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    if (error.code === '23505') { // Unique constraint violation
      return res.status(400).json({ error: 'Email already exists' });
    }
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Failed to create user', message: error.message });
  }
});

// PUT assign user to company (for admins without company)
router.put('/:id/assign-company', async (req, res) => {
  try {
    const { id } = req.params;
    const { company_id } = req.body;
    
    if (!company_id) {
      return res.status(400).json({ error: 'company_id is required' });
    }
    
    // Check if company_id column exists
    const columnCheck = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'company_id'
    `);
    
    if (columnCheck.rows.length === 0) {
      // Column doesn't exist, try to add it
      console.log('⚠️  company_id column does not exist. Attempting to add it...');
      try {
        // First check if companies table exists
        const companiesTableCheck = await pool.query(`
          SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'companies'
          )
        `);
        
        if (companiesTableCheck.rows[0].exists) {
          // Add company_id column with foreign key
          await pool.query(`
            ALTER TABLE users 
            ADD COLUMN company_id UUID REFERENCES companies(id) ON DELETE CASCADE
          `);
          console.log('✅ Added company_id column to users table');
        } else {
          // Add company_id column without foreign key (companies table doesn't exist yet)
          await pool.query(`
            ALTER TABLE users 
            ADD COLUMN company_id UUID
          `);
          console.log('✅ Added company_id column to users table (without foreign key)');
        }
      } catch (addColumnError) {
        console.error('Failed to add company_id column:', addColumnError.message);
        return res.status(500).json({ 
          error: 'company_id column does not exist and could not be created',
          message: addColumnError.message,
          hint: 'Please run the migration endpoint: POST /api/admin/migrate'
        });
      }
    }
    
    // Verify company exists
    const companyResult = await pool.query('SELECT id, name FROM companies WHERE id = $1', [company_id]);
    if (companyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }
    
    // Update user's company_id
    const result = await pool.query(
      'UPDATE users SET company_id = $1 WHERE id = $2 RETURNING id, email, first_name, last_name, role, company_id',
      [company_id, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({
      success: true,
      message: `User assigned to company: ${companyResult.rows[0].name}`,
      user: result.rows[0]
    });
  } catch (error) {
    console.error('Error assigning user to company:', error);
    res.status(500).json({ error: 'Failed to assign user to company', message: error.message });
  }
});

// PUT update user
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      email,
      first_name,
      last_name,
      role,
      phone_number,
      photo_url,
      is_active,
      password_hash,
    } = req.body;

    const updateFields = [];
    const values = [];
    let paramIndex = 1;

    if (email !== undefined) {
      updateFields.push(`email = $${paramIndex++}`);
      values.push(email);
    }
    if (first_name !== undefined) {
      updateFields.push(`first_name = $${paramIndex++}`);
      values.push(first_name);
    }
    if (last_name !== undefined) {
      updateFields.push(`last_name = $${paramIndex++}`);
      values.push(last_name);
    }
    if (role !== undefined) {
      updateFields.push(`role = $${paramIndex++}`);
      values.push(role);
    }
    if (phone_number !== undefined) {
      updateFields.push(`phone_number = $${paramIndex++}`);
      values.push(phone_number);
    }
    if (photo_url !== undefined) {
      updateFields.push(`photo_url = $${paramIndex++}`);
      values.push(photo_url);
    }
    if (is_active !== undefined) {
      updateFields.push(`is_active = $${paramIndex++}`);
      values.push(is_active);
    }
    if (password_hash !== undefined) {
      updateFields.push(`password_hash = $${paramIndex++}`);
      values.push(password_hash);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    const result = await pool.query(
      `UPDATE users SET ${updateFields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

// DELETE user
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ message: 'User deleted successfully', user: result.rows[0] });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

module.exports = router;
