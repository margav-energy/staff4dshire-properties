const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'staff4dshire',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

async function updateProjectsCompanyId() {
  try {
    console.log('Connecting to database...');
    await pool.query('SELECT 1');
    console.log('Database connected successfully');

    // Get all projects without company_id
    const projectsResult = await pool.query(`
      SELECT id FROM projects WHERE company_id IS NULL
    `);

    console.log(`Found ${projectsResult.rows.length} projects without company_id`);

    if (projectsResult.rows.length === 0) {
      console.log('✅ All projects already have company_id');
      await pool.end();
      return;
    }

    // Get the default company or first company
    const companyResult = await pool.query(`
      SELECT id FROM companies ORDER BY created_at LIMIT 1
    `);

    if (companyResult.rows.length === 0) {
      console.log('⚠️  No companies found in database. Cannot assign company_id to projects.');
      await pool.end();
      return;
    }

    const defaultCompanyId = companyResult.rows[0].id;
    console.log(`Using company_id: ${defaultCompanyId}`);

    // Update all projects without company_id to use the default company
    // NOTE: In production, you might want to assign projects to the correct company
    // based on who created them or other business logic
    const updateResult = await pool.query(`
      UPDATE projects 
      SET company_id = $1 
      WHERE company_id IS NULL
    `, [defaultCompanyId]);

    console.log(`✅ Updated ${updateResult.rowCount} projects with company_id: ${defaultCompanyId}`);
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await pool.end();
    process.exit(1);
  }
}

updateProjectsCompanyId();


