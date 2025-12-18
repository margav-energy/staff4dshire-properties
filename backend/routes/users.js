const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');
const { buildCompanyWhereClause, canAccessCompany } = require('../middleware/companyFilter');

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
            console.log('[USERS API] User has no company_id, returning empty list');
          }
        } else {
          console.log('[USERS API] Superadmin detected, returning all users');
        }
      } else {
        console.log('[USERS API] User not found for userId:', userId);
      }
    } else {
      console.log('[USERS API] No userId provided, returning all users');
    }
    
    query += ' ORDER BY created_at DESC';
    console.log('[USERS API] Final query:', query, 'Params:', params);
    const result = await pool.query(query, params);
    console.log('[USERS API] Returning', result.rows.length, 'users');
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
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

// GET user by email
router.get('/email/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching user by email:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// POST create new user
router.post('/', async (req, res) => {
  try {
    const {
      email,
      password_hash,
      first_name,
      last_name,
      role,
      phone_number,
      photo_url,
      is_active = true,
      company_id,
      is_superadmin = false
    } = req.body;

    if (!email || !password_hash || !first_name || !last_name || !role) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Determine company_id if not provided
    let finalCompanyId = company_id;
    const userId = req.query.userId || req.body.created_by_user_id;
    
    if (!finalCompanyId && userId) {
      // Get creator's company_id
      const creatorResult = await pool.query(
        'SELECT company_id FROM users WHERE id = $1',
        [userId]
      );
      if (creatorResult.rows.length > 0) {
        finalCompanyId = creatorResult.rows[0].company_id;
      }
    }
    
    // Validate: non-superadmin users must have a company_id
    if (role !== 'superadmin' && !is_superadmin && !finalCompanyId) {
      return res.status(400).json({ error: 'Company ID is required for non-superadmin users' });
    }

    const id = uuidv4();
    const result = await pool.query(
      `INSERT INTO users (id, email, password_hash, first_name, last_name, role, phone_number, photo_url, is_active, company_id, is_superadmin)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [id, email, password_hash, first_name, last_name, role, phone_number || null, photo_url || null, is_active, finalCompanyId || null, is_superadmin || role === 'superadmin']
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    if (error.code === '23505') { // Unique violation
      return res.status(409).json({ error: 'User with this email already exists' });
    }
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Failed to create user' });
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
      password_hash
    } = req.body;

    let updateFields = [];
    let values = [];
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

