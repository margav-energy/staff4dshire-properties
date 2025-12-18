const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'staff4dshire',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

async function addCompanyIdColumn() {
  try {
    console.log('Connecting to database...');
    await pool.query('SELECT 1');
    console.log('Database connected successfully');

    // Check if column already exists
    const checkResult = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name='projects' AND column_name='company_id'
    `);

    if (checkResult.rows.length > 0) {
      console.log('✅ Column company_id already exists in projects table');
      await pool.end();
      return;
    }

    // Add company_id column
    console.log('Adding company_id column to projects table...');
    await pool.query(`
      ALTER TABLE projects 
      ADD COLUMN company_id UUID REFERENCES companies(id)
    `);

    console.log('✅ Successfully added company_id column to projects table!');
    
    await pool.end();
  } catch (error) {
    console.error('❌ Error:', error.message);
    await pool.end();
    process.exit(1);
  }
}

addCompanyIdColumn();


