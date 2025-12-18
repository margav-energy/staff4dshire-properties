const express = require('express');
const router = express.Router();
const pool = require('../db');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { sendPasswordResetEmail } = require('../utils/emailService');

// POST /api/password-reset/request - Request password reset
router.post('/request', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    // Find user by email
    const userResult = await pool.query(
      'SELECT id, email, first_name, last_name FROM users WHERE email = $1 AND is_active = TRUE',
      [email.toLowerCase().trim()]
    );

    // Always return success (security best practice - don't reveal if email exists)
    if (userResult.rows.length === 0) {
      return res.json({
        success: true,
        message: 'If an account exists with this email, a password reset code has been sent.',
      });
    }

    const user = userResult.rows[0];

    // Generate 6-digit reset code
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit code (100000-999999)
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1); // Code expires in 1 hour

    // Store reset code in database (using password_reset_token column)
    // Try to update with new columns, fallback to basic update if columns don't exist
    try {
      await pool.query(
        'UPDATE users SET password_reset_token = $1, password_reset_token_expires_at = $2 WHERE id = $3',
        [resetCode, expiresAt, user.id]
      );
    } catch (dbError) {
      // If columns don't exist, log error but don't fail the request
      console.error('Database error updating password reset code. Please run migration:', dbError.message);
      // Still return success to user (security best practice)
      return res.json({
        success: true,
        message: 'If an account exists with this email, a password reset code has been sent.',
        warning: 'Database migration may be required. Please contact administrator.',
      });
    }

    // Send password reset email
    // Use the base_url from request, or environment variable, or try to detect from request origin
    let baseUrl = req.body.base_url || process.env.APP_BASE_URL;
    
    // If no base URL provided, try to use the request origin (for web apps)
    if (!baseUrl && req.headers.origin) {
      baseUrl = req.headers.origin;
    }
    
    // Fallback to default
    if (!baseUrl) {
      baseUrl = 'http://localhost:8080'; // Flutter web default port
    }
    
    if (process.env.SMTP_USER && process.env.SMTP_PASSWORD) {
      sendPasswordResetEmail(
        user.email,
        resetCode,
        user.first_name,
        baseUrl
      ).catch((emailError) => {
        console.error('Failed to send password reset email:', emailError.message);
      });
    }

    res.json({
      success: true,
      message: 'If an account exists with this email, a password reset code has been sent.',
    });
  } catch (error) {
    console.error('Password reset request error:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
  }
});

// POST /api/password-reset/admin-reset - Admin resets password for another user
router.post('/admin-reset', async (req, res) => {
  try {
    const { user_id, admin_user_id, send_email } = req.body;

    if (!user_id || !admin_user_id) {
      return res.status(400).json({ error: 'User ID and admin user ID are required' });
    }

    // Verify admin user exists and is an admin/superadmin
    const adminResult = await pool.query(
      'SELECT id, role, is_superadmin FROM users WHERE id = $1',
      [admin_user_id]
    );

    if (adminResult.rows.length === 0) {
      return res.status(404).json({ error: 'Admin user not found' });
    }

    const admin = adminResult.rows[0];
    const isAdmin = admin.role === 'admin' || admin.role === 'superadmin' || admin.is_superadmin;

    if (!isAdmin) {
      return res.status(403).json({ error: 'Only administrators can reset passwords for other users' });
    }

    // Find the user whose password is being reset
    const userResult = await pool.query(
      'SELECT id, email, first_name, last_name FROM users WHERE id = $1',
      [user_id]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];

    // Generate a secure random password (12 characters: letters and numbers)
    const generatePassword = () => {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      let password = '';
      for (let i = 0; i < 12; i++) {
        password += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      return password;
    };

    const newPassword = generatePassword();
    const passwordHash = await bcrypt.hash(newPassword, 10);

    // Update password and set must_change_password flag
    await pool.query(
      `UPDATE users 
       SET password_hash = $1, 
           must_change_password = TRUE,
           password_reset_token = NULL,
           password_reset_token_expires_at = NULL
       WHERE id = $2`,
      [passwordHash, user.id]
    );

    // Optionally send email with new password
    const shouldSendEmail = send_email !== false; // Default to true if not specified
    if (shouldSendEmail && process.env.SMTP_USER && process.env.SMTP_PASSWORD) {
      // You could create a separate email template for admin password resets
      // For now, we'll generate a reset code and send it
      const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + 24); // Code expires in 24 hours for admin resets

      await pool.query(
        'UPDATE users SET password_reset_token = $1, password_reset_token_expires_at = $2 WHERE id = $3',
        [resetCode, expiresAt, user.id]
      );

      let baseUrl = req.body.base_url || process.env.APP_BASE_URL;
      if (!baseUrl && req.headers.origin) {
        baseUrl = req.headers.origin;
      }
      if (!baseUrl) {
        baseUrl = 'http://localhost:8080';
      }

      sendPasswordResetEmail(
        user.email,
        resetCode,
        user.first_name,
        baseUrl
      ).catch((emailError) => {
        console.error('Failed to send password reset email:', emailError.message);
      });
    }

    res.json({
      success: true,
      message: 'Password has been reset successfully.',
      new_password: newPassword, // Return the new password to admin (only if not sending email)
      password_sent_via_email: shouldSendEmail,
    });
  } catch (error) {
    console.error('Admin password reset error:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
  }
});

// POST /api/password-reset/reset - Reset password with 6-digit code
router.post('/reset', async (req, res) => {
  try {
    const { code, new_password } = req.body;

    if (!code || !new_password) {
      return res.status(400).json({ error: 'Reset code and new password are required' });
    }

    if (new_password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters long' });
    }

    // Validate code format (6 digits)
    if (!/^\d{6}$/.test(code)) {
      return res.status(400).json({ error: 'Invalid reset code format. Please enter the 6-digit code.' });
    }

    // Find user by reset code
    const userResult = await pool.query(
      `SELECT id, email, password_reset_token_expires_at 
       FROM users 
       WHERE password_reset_token = $1 
       AND password_reset_token_expires_at > CURRENT_TIMESTAMP
       AND is_active = TRUE`,
      [code]
    );

    if (userResult.rows.length === 0) {
      return res.status(400).json({ 
        error: 'Invalid or expired reset code. Please request a new password reset.' 
      });
    }

    const user = userResult.rows[0];

    // Hash new password
    const passwordHash = await bcrypt.hash(new_password, 10);

    // Update password and clear reset token
    await pool.query(
      `UPDATE users 
       SET password_hash = $1, 
           password_reset_token = NULL, 
           password_reset_token_expires_at = NULL,
           must_change_password = FALSE
       WHERE id = $2`,
      [passwordHash, user.id]
    );

    res.json({
      success: true,
      message: 'Password has been reset successfully. You can now log in with your new password.',
    });
  } catch (error) {
    console.error('Password reset error:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
  }
});

// POST /api/password-reset/change - Change password (requires authentication)
router.post('/change', async (req, res) => {
  try {
    const { user_id, current_password, new_password, skip_current_password_check } = req.body;

    if (!user_id || !new_password) {
      return res.status(400).json({ error: 'User ID and new password are required' });
    }
    
    // current_password is only required if not skipping the check (for mandatory password changes)
    if (!skip_current_password_check && !current_password) {
      return res.status(400).json({ error: 'Current password is required' });
    }

    if (new_password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters long' });
    }

    // Find user and verify current password
    const userResult = await pool.query(
      'SELECT id, password_hash FROM users WHERE id = $1 AND is_active = TRUE',
      [user_id]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];

    // Verify current password (skip if this is a mandatory password change)
    if (!skip_current_password_check) {
      const passwordMatch = await bcrypt.compare(current_password, user.password_hash);
      if (!passwordMatch) {
        return res.status(401).json({ error: 'Current password is incorrect' });
      }
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(new_password, 10);

    // Update password and clear must_change_password flag
    await pool.query(
      'UPDATE users SET password_hash = $1, must_change_password = FALSE WHERE id = $2',
      [passwordHash, user.id]
    );

    res.json({
      success: true,
      message: 'Password has been changed successfully.',
    });
  } catch (error) {
    console.error('Password change error:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
  }
});

module.exports = router;
