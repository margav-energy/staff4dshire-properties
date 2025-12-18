const express = require('express');
const router = express.Router();
const pool = require('../db');
const bcrypt = require('bcrypt');

// POST /api/auth/login - Authenticate user with email and password
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Normalize email (trim whitespace and convert to lowercase)
    const normalizedEmail = String(email).toLowerCase().trim();
    console.log(`[AUTH] Login attempt - email: "${email}" (normalized: "${normalizedEmail}")`);
    
    // Find user by email (case-insensitive search)
    const userResult = await pool.query(
      'SELECT * FROM users WHERE LOWER(TRIM(email)) = $1 AND is_active = TRUE',
      [normalizedEmail]
    );

    if (userResult.rows.length === 0) {
      // Check if user exists but is inactive
      const inactiveUserResult = await pool.query(
        'SELECT email, is_active, role FROM users WHERE LOWER(TRIM(email)) = $1',
        [normalizedEmail]
      );
      if (inactiveUserResult.rows.length > 0) {
        console.log(`[AUTH] Login failed - User "${normalizedEmail}" exists but is_active = ${inactiveUserResult.rows[0].is_active}`);
      } else {
        console.log(`[AUTH] Login failed - User "${normalizedEmail}" not found in database`);
      }
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = userResult.rows[0];
    console.log(`[AUTH] User found: ${user.email}, role: ${user.role}, company_id: ${user.company_id}`);

    // Verify password
    if (!user.password_hash) {
      console.log(`[AUTH] Login failed - User "${normalizedEmail}" has no password_hash`);
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    console.log(`[AUTH] Password match: ${passwordMatch}`);

    if (!passwordMatch) {
      console.log(`[AUTH] Login failed - Password mismatch for user "${normalizedEmail}"`);
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    
    console.log(`[AUTH] Login successful for user "${normalizedEmail}" (${user.role})`);

    // Update last login timestamp (if column exists)
    try {
      await pool.query(
        'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
        [user.id]
      );
    } catch (err) {
      // Column might not exist - ignore error
      console.warn('Could not update last_login (column may not exist):', err.message);
    }

    // Return user data (without password_hash)
    const { password_hash, ...userWithoutPassword } = user;

    res.json({
      success: true,
      user: {
        id: userWithoutPassword.id,
        email: userWithoutPassword.email,
        first_name: userWithoutPassword.first_name,
        last_name: userWithoutPassword.last_name,
        role: userWithoutPassword.role,
        phone_number: userWithoutPassword.phone_number,
        photo_url: userWithoutPassword.photo_url,
        is_active: userWithoutPassword.is_active,
        company_id: userWithoutPassword.company_id,
        is_superadmin: userWithoutPassword.is_superadmin,
        last_login: userWithoutPassword.last_login || null,
        created_at: userWithoutPassword.created_at,
        must_change_password: userWithoutPassword.must_change_password || false,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
  }
});

// POST /api/auth/verify - Verify token/session (for future use)
router.post('/verify', async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    const userResult = await pool.query(
      'SELECT * FROM users WHERE id = $1 AND is_active = TRUE',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'User not found or inactive' });
    }

    const user = userResult.rows[0];
    const { password_hash, ...userWithoutPassword } = user;

    res.json({
      success: true,
      user: {
        id: userWithoutPassword.id,
        email: userWithoutPassword.email,
        first_name: userWithoutPassword.first_name,
        last_name: userWithoutPassword.last_name,
        role: userWithoutPassword.role,
        phone_number: userWithoutPassword.phone_number,
        photo_url: userWithoutPassword.photo_url,
        is_active: userWithoutPassword.is_active,
        company_id: userWithoutPassword.company_id,
        is_superadmin: userWithoutPassword.is_superadmin,
        last_login: userWithoutPassword.last_login || null,
      },
    });
  } catch (error) {
    console.error('Verify error:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
  }
});

module.exports = router;

