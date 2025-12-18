// Show which users have passwords (for debugging - don't use in production!)
const pool = require('./db');

async function showUsers() {
  try {
    const result = await pool.query(`
      SELECT 
        id, 
        email, 
        first_name, 
        last_name, 
        role, 
        is_active,
        password_hash IS NOT NULL as has_password,
        company_id,
        is_superadmin
      FROM users 
      ORDER BY created_at DESC 
      LIMIT 10
    `);
    
    console.log(`\n📋 Found ${result.rows.length} users:\n`);
    
    result.rows.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email}`);
      console.log(`   Name: ${user.first_name} ${user.last_name}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Active: ${user.is_active ? '✅' : '❌'}`);
      console.log(`   Has Password: ${user.has_password ? '✅' : '❌'}`);
      console.log(`   Company ID: ${user.company_id || 'None'}`);
      console.log(`   Superadmin: ${user.is_superadmin ? '✅' : '❌'}`);
      console.log('');
    });
    
    console.log('💡 To test login, use one of the emails above that has a password.');
    console.log('   (You may need to reset the password if you don\'t know it)');
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await pool.end();
    process.exit(1);
  }
}

showUsers();



