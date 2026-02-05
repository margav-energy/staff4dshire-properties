// Migration script to add password reset columns to users table
// Run with: node migrations/add_password_reset_columns.js

const pool = require('../db');

async function runMigration() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('🔄 Adding password reset columns to users table...');
    
    // Add columns
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT FALSE,
      ADD COLUMN IF NOT EXISTS password_reset_token VARCHAR(255),
      ADD COLUMN IF NOT EXISTS password_reset_token_expires_at TIMESTAMP;
    `);
    
    console.log('✅ Columns added successfully!');
    
    // Create index
    try {
      await client.query(`
        CREATE INDEX IF NOT EXISTS idx_users_password_reset_token 
        ON users(password_reset_token) 
        WHERE password_reset_token IS NOT NULL;
      `);
      console.log('✅ Index created successfully!');
    } catch (indexError) {
      // Index might already exist, that's okay
      if (indexError.message.includes('already exists')) {
        console.log('ℹ️  Index already exists, skipping...');
      } else {
        throw indexError;
      }
    }
    
    await client.query('COMMIT');
    console.log('✅ Migration completed successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error.message);
    throw error;
  } finally {
    client.release();
  }
}

runMigration()
  .then(() => {
    console.log('Migration script completed.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Migration script failed:', error);
    process.exit(1);
  });
