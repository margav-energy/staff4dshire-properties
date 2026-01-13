const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'staff4dshire',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

async function checkAdminCompany() {
  try {
    const result = await pool.query(
      "SELECT id, email, first_name, last_name, role, company_id, is_superadmin FROM users WHERE email = 'aduelarh@gmail.com'"
    );
    
    if (result.rows.length === 0) {
      console.log('Admin user not found');
      await pool.end();
      return;
    }
    
    const admin = result.rows[0];
    console.log('Admin user:', admin);
    
    if (admin.company_id) {
      const projects = await pool.query(
        'SELECT id, name, company_id FROM projects WHERE company_id = $1',
        [admin.company_id]
      );
      console.log(`\nProjects for company ${admin.company_id}: ${projects.rows.length}`);
      projects.rows.forEach(p => console.log(' -', p.name));
      
      const users = await pool.query(
        'SELECT id, email, first_name, last_name, role FROM users WHERE company_id = $1',
        [admin.company_id]
      );
      console.log(`\nUsers for company ${admin.company_id}: ${users.rows.length}`);
      users.rows.forEach(u => console.log(' -', u.email, `(${u.role})`));
    } else {
      console.log('\nAdmin user has no company_id!');
    }
    
    await pool.end();
  } catch (e) {
    console.error('Error:', e.message);
    await pool.end();
    process.exit(1);
  }
}

checkAdminCompany();





