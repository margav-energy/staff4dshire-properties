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
    
    // Split by semicolons and execute each statement
    // Better parsing: handle multi-line statements and comments
    const statements = schema
      .split(';')
      .map(s => {
        // Remove comments
        return s.split('\n')
          .map(line => {
            const commentIndex = line.indexOf('--');
            return commentIndex >= 0 ? line.substring(0, commentIndex) : line;
          })
          .join('\n')
          .trim();
      })
      .filter(s => s.length > 0 && !s.match(/^\s*$/));

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
            error.code === '42P07' || // duplicate_table
            error.code === '42710') { // duplicate_object
          // Table/object already exists, that's fine
          continue;
        }
        console.error(`⚠️  Error executing statement: ${error.message}`);
        console.error(`   Statement: ${statement.substring(0, 100)}...`);
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
