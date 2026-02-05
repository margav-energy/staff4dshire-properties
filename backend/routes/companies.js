const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');
const { canAccessCompany } = require('../middleware/companyFilter');

// GET all companies (superadmins get all, regular users get their own company)
router.get('/', async (req, res) => {
  try {
    const userId = req.query.userId;
    
    if (userId) {
      const userResult = await pool.query(
        'SELECT company_id, is_superadmin, role FROM users WHERE id = $1',
        [userId]
      );
      
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      
      const user = userResult.rows[0];
      
      // Superadmins get all companies
      if (user.is_superadmin || user.role === 'superadmin') {
        const result = await pool.query('SELECT * FROM companies ORDER BY created_at DESC');
        return res.json(result.rows);
      }
      
      // Regular users get only their own company
      if (user.company_id) {
        const result = await pool.query('SELECT * FROM companies WHERE id = $1', [user.company_id]);
        return res.json(result.rows); // Returns array with one company or empty array
      } else {
        // User has no company_id
        return res.json([]);
      }
    }
    
    // No userId provided - return all companies (for backward compatibility, but should require auth in production)
    const result = await pool.query('SELECT * FROM companies ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching companies:', error);
    res.status(500).json({ error: 'Failed to fetch companies' });
  }
});

// GET company by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.query.userId;
    
    const result = await pool.query('SELECT * FROM companies WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }
    
    // Check access permissions
    if (userId) {
      const userResult = await pool.query(
        'SELECT company_id, is_superadmin, role FROM users WHERE id = $1',
        [userId]
      );
      
      if (userResult.rows.length > 0) {
        const user = userResult.rows[0];
        req.user = user;
        
        if (!canAccessCompany(req, id)) {
          return res.status(403).json({ error: 'Access denied' });
        }
      }
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching company:', error);
    res.status(500).json({ error: 'Failed to fetch company' });
  }
});

// POST create new company (superadmins or admins without company)
router.post('/', async (req, res) => {
  try {
    const userId = req.query.userId || req.body.created_by_user_id;
    let isSuperadmin = false;
    let userHasCompany = false;
    
    if (userId) {
      const userResult = await pool.query(
        'SELECT is_superadmin, role, company_id FROM users WHERE id = $1',
        [userId]
      );
      
      if (userResult.rows.length > 0) {
        const user = userResult.rows[0];
        isSuperadmin = user.is_superadmin || user.role === 'superadmin';
        userHasCompany = user.company_id !== null;
        
        // Only superadmins or admins without a company can create companies
        if (!isSuperadmin && userHasCompany) {
          return res.status(403).json({ 
            error: 'Only superadmins or admins without a company can create companies',
            hint: 'If you are an admin, you can only create a company if you are not already assigned to one'
          });
        }
      }
    }
    
    const {
      name,
      domain,
      address,
      phone_number,
      email,
      subscription_tier = 'basic',
      max_users = 50
    } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Company name is required' });
    }

    // Check if companies table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'companies'
      )
    `);
    
    if (!tableCheck.rows[0].exists) {
      console.error('Companies table does not exist. Running migration...');
      // Try to create companies table
      try {
        await pool.query(`
          CREATE TABLE IF NOT EXISTS companies (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            domain VARCHAR(255),
            address TEXT,
            phone_number VARCHAR(20),
            email VARCHAR(255),
            is_active BOOLEAN DEFAULT TRUE,
            subscription_tier VARCHAR(50) DEFAULT 'basic',
            max_users INTEGER DEFAULT 50,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `);
        console.log('✅ Companies table created');
      } catch (createError) {
        console.error('Failed to create companies table:', createError.message);
        return res.status(500).json({ 
          error: 'Companies table does not exist. Please run migration first.',
          details: createError.message 
        });
      }
    }

    const id = uuidv4();
    const result = await pool.query(
      `INSERT INTO companies (id, name, domain, address, phone_number, email, subscription_tier, max_users)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [id, name, domain || null, address || null, phone_number || null, email || null, subscription_tier, max_users]
    );

    // If user is admin (not superadmin) and doesn't have a company, assign them to the new company
    if (userId && !isSuperadmin && !userHasCompany) {
      try {
        await pool.query(
          'UPDATE users SET company_id = $1 WHERE id = $2',
          [id, userId]
        );
        console.log(`✅ Assigned user ${userId} to newly created company ${id}`);
      } catch (assignError) {
        console.error('Failed to assign user to company:', assignError.message);
        // Don't fail the request - company was created successfully
      }
    }

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating company:', error);
    console.error('Error details:', error.message);
    console.error('Error code:', error.code);
    res.status(500).json({ 
      error: 'Failed to create company',
      details: error.message,
      code: error.code
    });
  }
});

// PUT update company (only superadmins or company admins)
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.query.userId;
    
    // Check permissions
    if (userId) {
      const userResult = await pool.query(
        'SELECT company_id, is_superadmin, role FROM users WHERE id = $1',
        [userId]
      );
      
      if (userResult.rows.length > 0) {
        const user = userResult.rows[0];
        
        // Superadmins can update any company, company admins can only update their own
        if (!user.is_superadmin && user.role !== 'superadmin' && user.company_id !== id) {
          return res.status(403).json({ error: 'Access denied' });
        }
      }
    }
    
    const {
      name,
      domain,
      address,
      phone_number,
      email,
      subscription_tier,
      max_users,
      is_active
    } = req.body;

    let updateFields = [];
    let values = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updateFields.push(`name = $${paramIndex++}`);
      values.push(name);
    }
    if (domain !== undefined) {
      updateFields.push(`domain = $${paramIndex++}`);
      values.push(domain);
    }
    if (address !== undefined) {
      updateFields.push(`address = $${paramIndex++}`);
      values.push(address);
    }
    if (phone_number !== undefined) {
      updateFields.push(`phone_number = $${paramIndex++}`);
      values.push(phone_number);
    }
    if (email !== undefined) {
      updateFields.push(`email = $${paramIndex++}`);
      values.push(email);
    }
    if (subscription_tier !== undefined) {
      updateFields.push(`subscription_tier = $${paramIndex++}`);
      values.push(subscription_tier);
    }
    if (max_users !== undefined) {
      updateFields.push(`max_users = $${paramIndex++}`);
      values.push(max_users);
    }
    if (is_active !== undefined) {
      updateFields.push(`is_active = $${paramIndex++}`);
      values.push(is_active);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    const result = await pool.query(
      `UPDATE companies SET ${updateFields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating company:', error);
    res.status(500).json({ error: 'Failed to update company' });
  }
});

// DELETE company (only superadmins)
router.delete('/:id', async (req, res) => {
  try {
    const userId = req.query.userId;
    
    if (userId) {
      const userResult = await pool.query(
        'SELECT is_superadmin, role FROM users WHERE id = $1',
        [userId]
      );
      
      if (userResult.rows.length === 0 || (!userResult.rows[0].is_superadmin && userResult.rows[0].role !== 'superadmin')) {
        return res.status(403).json({ error: 'Only superadmins can delete companies' });
      }
    }
    
    const { id } = req.params;
    const result = await pool.query('DELETE FROM companies WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Company not found' });
    }

    res.json({ message: 'Company deleted successfully', company: result.rows[0] });
  } catch (error) {
    console.error('Error deleting company:', error);
    res.status(500).json({ error: 'Failed to delete company' });
  }
});

module.exports = router;



