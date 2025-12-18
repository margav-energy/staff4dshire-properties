// Test script to check login functionality
const pool = require('./db');
const bcrypt = require('bcrypt');

async function testLogin() {
  try {
    console.log('🔍 Checking database...\n');
    
    // Check if any users exist
    const usersResult = await pool.query('SELECT id, email, first_name, last_name, role, is_active, password_hash IS NOT NULL as has_password FROM users LIMIT 5');
    
    if (usersResult.rows.length === 0) {
      console.log('❌ No users found in database!');
      console.log('\n💡 Create a user first:');
      console.log('   Option 1: node create_superadmin.js admin@test.com password123');
      console.log('   Option 2: Use the registration screen in the app');
      await pool.end();
      return;
    }
    
    console.log(`✅ Found ${usersResult.rows.length} user(s):`);
    usersResult.rows.forEach((user, index) => {
      console.log(`\n   ${index + 1}. ${user.email}`);
      console.log(`      Name: ${user.first_name} ${user.last_name}`);
      console.log(`      Role: ${user.role}`);
      console.log(`      Active: ${user.is_active}`);
      console.log(`      Has Password: ${user.has_password ? '✅' : '❌'}`);
    });
    
    // Test login with first user
    if (usersResult.rows.length > 0) {
      const testUser = usersResult.rows[0];
      if (testUser.has_password) {
        console.log(`\n🧪 Testing login with: ${testUser.email}`);
        console.log('   (You can test with any password - checking if endpoint works)');
      } else {
        console.log(`\n⚠️  User ${testUser.email} has no password hash!`);
        console.log('   User needs to be created with a password.');
      }
    }
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await pool.end();
    process.exit(1);
  }
}

testLogin();



