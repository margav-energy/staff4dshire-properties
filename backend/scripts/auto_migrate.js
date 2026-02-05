/**
 * Auto-migration script
 * Runs database schema automatically if tables don't exist
 * This is safe to run multiple times - it checks if tables exist first
 */

const pool = require('../db');
const fs = require('fs');
const path = require('path');

async function checkTableExists(tableName) {
  try {
    const result = await pool.query(
      `SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = $1
      )`,
      [tableName]
    );
    return result.rows[0].exists;
  } catch (error) {
    return false;
  }
}

async function runSchema() {
  try {
    console.log('🔍 Checking if database schema needs to be created...');
    
    // Check if users table exists (main indicator)
    const usersTableExists = await checkTableExists('users');
    
    if (usersTableExists) {
      console.log('✅ Database schema already exists. Skipping migration.');
      return;
    }

    console.log('📄 Database schema not found. Running migration...');
    
    // Read schema file
    const schemaPath = path.join(__dirname, '../schema.sql');
    if (!fs.existsSync(schemaPath)) {
      console.log('⚠️  schema.sql not found. Skipping auto-migration.');
      return;
    }

    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Split by semicolons and execute each statement
    const statements = schema
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    let successCount = 0;
    let errorCount = 0;

    for (const statement of statements) {
      if (statement.trim().length === 0) continue;
      
      try {
        await pool.query(statement);
        successCount++;
      } catch (error) {
        // Ignore "already exists" errors
        if (error.message.includes('already exists') || 
            error.message.includes('duplicate') ||
            error.code === '42P07') { // duplicate_table
          // Table already exists, that's fine
          continue;
        }
        console.error(`⚠️  Error executing statement: ${error.message}`);
        errorCount++;
      }
    }

    if (errorCount === 0) {
      console.log(`✅ Database schema created successfully! (${successCount} statements executed)`);
    } else {
      console.log(`⚠️  Migration completed with ${errorCount} errors. Some tables may already exist.`);
    }

    // Verify users table was created
    const usersExists = await checkTableExists('users');
    if (usersExists) {
      console.log('✅ Users table verified. Schema migration complete!');
    } else {
      console.log('⚠️  Users table not found after migration. Manual intervention may be required.');
    }

  } catch (error) {
    console.error('❌ Error during auto-migration:', error.message);
    // Don't throw - allow server to continue
  }
}

module.exports = { runSchema };
