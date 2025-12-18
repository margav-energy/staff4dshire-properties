const pool = require('./db');

async function listUsers() {
  try {
    const result = await pool.query(`
      SELECT 
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.role,
        COALESCE(c.name, '(No Company)') as company_name
      FROM users u
      LEFT JOIN companies c ON u.company_id = c.id
      ORDER BY u.created_at
    `);

    console.log('\n=== ALL USERS ===\n');
    result.rows.forEach((user, index) => {
      console.log(`${index + 1}. ${user.first_name} ${user.last_name} (${user.email})`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Company: ${user.company_name}`);
      console.log(`   ID: ${user.id}`);
      console.log('');
    });

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

listUsers();
