const pool = require('./db');
const fs = require('fs');
const path = require('path');

async function addPasswordResetFields() {
  try {
    console.log('🔄 Adding password reset and change password fields to users table...');
    
    const sql = fs.readFileSync(
      path.join(__dirname, 'migrations', 'add_password_reset_fields.sql'),
      'utf8'
    );
    
    await pool.query(sql);
    
    console.log('✅ Successfully added password reset fields to users table!');
    console.log('   - must_change_password (BOOLEAN)');
    console.log('   - password_reset_token (VARCHAR)');
    console.log('   - password_reset_token_expires_at (TIMESTAMP)');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error adding password reset fields:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  addPasswordResetFields()
    .then(() => {
      pool.end();
    })
    .catch((err) => {
      console.error(err);
      pool.end();
      process.exit(1);
    });
}

module.exports = addPasswordResetFields;

