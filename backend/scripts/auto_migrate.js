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
    
    // First, test database connection
    try {
      await pool.query('SELECT NOW()');
      console.log('✅ Database connection verified');
    } catch (connError) {
      console.error('❌ Database connection failed:', connError.message);
      throw new Error('Cannot connect to database. Check connection settings.');
    }
    
    // Check if users table exists (main indicator)
    const usersTableExists = await checkTableExists('users');
    
    if (usersTableExists) {
      console.log('✅ Database schema already exists. Skipping migration.');
      return true;
    }

    console.log('📄 Database schema not found. Running migration...');
    
    // Read schema file
    const schemaPath = path.join(__dirname, '../schema.sql');
    if (!fs.existsSync(schemaPath)) {
      console.log('⚠️  schema.sql not found. Skipping auto-migration.');
      return false;
    }

    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Execute the entire schema as one query
    // PostgreSQL can handle multiple statements separated by semicolons
    console.log('📝 Executing database schema (full file)...');
    try {
      await pool.query(schema);
      console.log('✅ Database schema executed successfully!');
    } catch (error) {
      // If full execution fails, it might be because some objects already exist
      // Try to continue anyway and verify tables were created
      console.log(`⚠️  Schema execution had errors: ${error.message.substring(0, 200)}`);
      console.log('🔍 Verifying if tables were created despite errors...');
      
      // Check if critical tables exist
      const criticalTables = ['users', 'projects', 'time_entries'];
      let tablesExist = 0;
      for (const table of criticalTables) {
        if (await checkTableExists(table)) {
          tablesExist++;
        }
      }
      
      if (tablesExist === criticalTables.length) {
        console.log('✅ All critical tables exist. Schema migration successful!');
      } else {
        console.log(`⚠️  Only ${tablesExist}/${criticalTables.length} critical tables exist.`);
        throw error; // Re-throw to trigger retry
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
      return true;
    } else {
      console.log('⚠️  Users table not found after migration. Manual intervention may be required.');
      console.log('💡 You can manually run the schema using Render database connection tools.');
      return false;
    }

  } catch (error) {
    console.error('❌ Error during auto-migration:', error.message);
    console.error('   Full error:', error);
    // Don't throw - allow server to continue, but return false
    return false;
  }
}

module.exports = { runSchema };
