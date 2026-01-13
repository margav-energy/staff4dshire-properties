const fs = require('fs');
const path = require('path');
const pool = require('../db');

async function runMigration() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const sqlFile = path.join(__dirname, 'alter_file_url_to_text.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    console.log('Running migration: alter_file_url_to_text.sql');
    await client.query(sql);
    
    await client.query('COMMIT');
    console.log('✅ Migration completed successfully');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration().catch(console.error);

