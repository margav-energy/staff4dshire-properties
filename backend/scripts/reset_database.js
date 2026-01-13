// Script to clear all database data and create a superadmin user
// Run with: node scripts/reset_database.js

const pool = require('../db');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');

async function resetDatabase() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('🗑️  Starting database reset...');
    
    // Disable foreign key checks temporarily (PostgreSQL doesn't have this, but we'll delete in order)
    // Delete in reverse order of dependencies to avoid foreign key violations
    
    console.log('Deleting data from tables...');
    
    // Delete from tables that reference other tables first
    await client.query('DELETE FROM audit_logs');
    console.log('✅ Cleared audit_logs');
    
    await client.query('DELETE FROM toolbox_talk_attendance');
    console.log('✅ Cleared toolbox_talk_attendance');
    
    await client.query('DELETE FROM rams_signoffs');
    console.log('✅ Cleared rams_signoffs');
    
    await client.query('DELETE FROM fit_to_work_declarations');
    console.log('✅ Cleared fit_to_work_declarations');
    
    await client.query('DELETE FROM documents');
    console.log('✅ Cleared documents');
    
    await client.query('DELETE FROM time_entries');
    console.log('✅ Cleared time_entries');
    
    await client.query('DELETE FROM inductions');
    console.log('✅ Cleared inductions');
    
    await client.query('DELETE FROM notifications');
    console.log('✅ Cleared notifications');
    
    // Delete chat-related tables if they exist
    try {
      await client.query('DELETE FROM messages');
      console.log('✅ Cleared messages');
    } catch (e) {
      // Table might not exist yet
    }
    
    try {
      await client.query('DELETE FROM conversation_participants');
      console.log('✅ Cleared conversation_participants');
    } catch (e) {
      // Table might not exist yet
    }
    
    try {
      await client.query('DELETE FROM conversations');
      console.log('✅ Cleared conversations');
    } catch (e) {
      // Table might not exist yet
    }
    
    // Delete project-related data
    await client.query('DELETE FROM projects');
    console.log('✅ Cleared projects');
    
    // Delete invitation-related data
    try {
      await client.query('DELETE FROM company_invitations');
      console.log('✅ Cleared company_invitations');
    } catch (e) {
      // Table might not exist yet
    }
    
    try {
      await client.query('DELETE FROM invitation_requests');
      console.log('✅ Cleared invitation_requests');
    } catch (e) {
      // Table might not exist yet
    }
    
    // Delete users (this will cascade to related data if CASCADE is set)
    await client.query('DELETE FROM users');
    console.log('✅ Cleared users');
    
    // Delete companies
    await client.query('DELETE FROM companies');
    console.log('✅ Cleared companies');
    
    await client.query('COMMIT');
    
    console.log('✅ Database cleared successfully!');
    console.log('');
    console.log('👤 Creating superadmin user...');
    
    // Create superadmin user
    const superadminEmail = 'admin@staff4dshire.com';
    const superadminPassword = 'admin123';
    const passwordHash = await bcrypt.hash(superadminPassword, 10);
    
    const superadminId = uuidv4();
    
    await client.query('BEGIN');
    
    // Check if users table has is_superadmin column
    const columnCheck = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name='users' AND column_name='is_superadmin'
    `);
    
    const hasIsSuperadmin = columnCheck.rows.length > 0;
    
    // Check if users table has company_id column (it might be nullable)
    const companyColumnCheck = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name='users' AND column_name='company_id'
    `);
    
    const hasCompanyId = companyColumnCheck.rows.length > 0;
    
    let insertQuery;
    let insertParams;
    
    if (hasIsSuperadmin && hasCompanyId) {
      insertQuery = `
        INSERT INTO users (id, email, password_hash, first_name, last_name, role, is_superadmin, company_id, is_active)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id, email, first_name, last_name, role, is_superadmin
      `;
      insertParams = [
        superadminId,
        superadminEmail,
        passwordHash,
        'Super',
        'Admin',
        'admin',
        true,
        null, // Superadmin doesn't belong to a company
        true,
      ];
    } else if (hasIsSuperadmin) {
      insertQuery = `
        INSERT INTO users (id, email, password_hash, first_name, last_name, role, is_superadmin, is_active)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id, email, first_name, last_name, role, is_superadmin
      `;
      insertParams = [
        superadminId,
        superadminEmail,
        passwordHash,
        'Super',
        'Admin',
        'admin',
        true,
        true,
      ];
    } else if (hasCompanyId) {
      insertQuery = `
        INSERT INTO users (id, email, password_hash, first_name, last_name, role, company_id, is_active)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id, email, first_name, last_name, role
      `;
      insertParams = [
        superadminId,
        superadminEmail,
        passwordHash,
        'Super',
        'Admin',
        'superadmin', // Use superadmin as role if is_superadmin column doesn't exist
        null,
        true,
      ];
    } else {
      insertQuery = `
        INSERT INTO users (id, email, password_hash, first_name, last_name, role, is_active)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id, email, first_name, last_name, role
      `;
      insertParams = [
        superadminId,
        superadminEmail,
        passwordHash,
        'Super',
        'Admin',
        'superadmin',
        true,
      ];
    }
    
    const result = await client.query(insertQuery, insertParams);
    const user = result.rows[0];
    
    await client.query('COMMIT');
    
    console.log('✅ Superadmin user created successfully!');
    console.log('');
    console.log('📋 Credentials:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`📧 Email:    ${superadminEmail}`);
    console.log(`🔑 Password: ${superadminPassword}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('');
    console.log('✅ Database reset complete!');
    console.log('');
    console.log('💡 You can now log in with the credentials above.');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error resetting database:', error);
    console.error('Error details:', error.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

resetDatabase();


