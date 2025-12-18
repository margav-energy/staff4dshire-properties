const pool = require('./db');

async function checkUsersAndCompanies() {
  try {
    // Get all companies
    const companiesResult = await pool.query('SELECT id, name, created_at FROM companies ORDER BY created_at');
    console.log('\n=== COMPANIES ===');
    console.log(`Total companies: ${companiesResult.rows.length}`);
    companiesResult.rows.forEach((company, index) => {
      console.log(`${index + 1}. ${company.name} (ID: ${company.id})`);
    });

    // Get users grouped by company
    const usersResult = await pool.query(`
      SELECT 
        u.id, 
        u.email, 
        u.first_name, 
        u.last_name, 
        u.role, 
        u.company_id,
        c.name as company_name
      FROM users u
      LEFT JOIN companies c ON u.company_id = c.id
      ORDER BY u.company_id, u.created_at
    `);
    
    console.log('\n=== USERS BY COMPANY ===');
    let currentCompanyId = null;
    usersResult.rows.forEach((user) => {
      if (user.company_id !== currentCompanyId) {
        currentCompanyId = user.company_id;
        console.log(`\n--- Company: ${user.company_name || '(No Company)'} (${user.company_id || 'NULL'}) ---`);
      }
      console.log(`  - ${user.first_name} ${user.last_name} (${user.email}) - Role: ${user.role}`);
    });

    // Count users per company
    const countResult = await pool.query(`
      SELECT 
        COALESCE(c.name, 'No Company') as company_name,
        u.company_id,
        COUNT(*) as user_count
      FROM users u
      LEFT JOIN companies c ON u.company_id = c.id
      GROUP BY u.company_id, c.name
      ORDER BY user_count DESC
    `);
    
    console.log('\n=== USER COUNT BY COMPANY ===');
    countResult.rows.forEach((row) => {
      console.log(`${row.company_name}: ${row.user_count} users`);
    });

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkUsersAndCompanies();
