// Quick script to add last_login column to users table
const pool = require('./db');

async function addLastLoginColumn() {
  try {
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP');
    console.log('✅ Successfully added last_login column to users table!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error adding column:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

addLastLoginColumn();



