// Create a test admin user for login testing
const pool = require('./db');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');

async function createTestAdmin() {
  try {
    const email = 'admin@test.com';
    const password = 'password123';
    
    // Check if user already exists
    const existing = await pool.query('SELECT id, email FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      console.log(`⚠️  User ${email} already exists with ID: ${existing.rows[0].id}`);
      console.log('   Updating password...');
      
      const passwordHash = await bcrypt.hash(password, 10);
      
      // Get or create default company
      let companyResult = await pool.query('SELECT id FROM companies LIMIT 1');
      let companyId = companyResult.rows.length > 0 ? companyResult.rows[0].id : null;
      
      if (!companyId) {
        // Create default company
        companyId = uuidv4();
        await pool.query(
          'INSERT INTO companies (id, name, is_active) VALUES ($1, $2, $3)',
          [companyId, 'Default Company', true]
        );
        console.log('✅ Created default company');
      }
      
      await pool.query(
        'UPDATE users SET password_hash = $1, role = $2, is_superadmin = $3, company_id = $4, is_active = TRUE WHERE email = $5',
        [passwordHash, 'admin', false, companyId, email]
      );
      console.log('✅ Password updated!');
    } else {
      // Create new user
      const passwordHash = await bcrypt.hash(password, 10);
      const userId = uuidv4();
      
      // Get default company
      const companyResult = await pool.query('SELECT id FROM companies LIMIT 1');
      const companyId = companyResult.rows.length > 0 ? companyResult.rows[0].id : null;
      
      await pool.query(
        `INSERT INTO users (id, email, password_hash, first_name, last_name, role, is_active, company_id, is_superadmin)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [userId, email, passwordHash, 'Admin', 'User', 'admin', true, companyId, false]
      );
      console.log('✅ Test admin user created!');
    }
    
    console.log('\n📧 Login Credentials:');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${password}`);
    console.log('\n💡 You can now use these credentials to login!');
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await pool.end();
    process.exit(1);
  }
}

createTestAdmin();

