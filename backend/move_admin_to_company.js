const pool = require('./db');

async function moveAdmin() {
  try {
    // Elarh Adu's user ID
    const userId = 'c3feb1b2-b22d-4621-b1ec-3d0d45bc3f07';
    
    // Get the company ID for "123 Group of Companies"
    const companyResult = await pool.query(
      "SELECT id FROM companies WHERE name = '123 Group of Companies'"
    );
    
    if (companyResult.rows.length === 0) {
      console.log('Company "123 Group of Companies" not found');
      process.exit(1);
    }
    
    const companyId = companyResult.rows[0].id;
    
    // Update user's company
    await pool.query(
      'UPDATE users SET company_id = $1 WHERE id = $2',
      [companyId, userId]
    );
    
    console.log('✅ Successfully moved Elarh Adu to "123 Group of Companies"');
    console.log('\nNow when you log in as elarhadu@gmail.com, you should see 0 users');
    console.log('(since no other users are in that company yet)');
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

moveAdmin();
