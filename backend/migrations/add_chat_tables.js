// Migration script to add chat tables
// Run with: node migrations/add_chat_tables.js

const pool = require('../db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('Starting chat tables migration...');
    
    // Read SQL file
    const sqlPath = path.join(__dirname, 'add_chat_tables.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Execute SQL
    await client.query(sql);
    
    await client.query('COMMIT');
    console.log('✅ Chat tables migration completed successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();


