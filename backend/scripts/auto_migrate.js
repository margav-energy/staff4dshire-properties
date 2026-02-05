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
    
    // Split schema into parts: tables, functions, triggers
    // This avoids issues with dollar-quoted strings in functions
    const lines = schema.split('\n');
    let currentSection = [];
    const sections = [];
    let inFunction = false;
    let functionBody = '';
    
    for (const line of lines) {
      // Skip comments
      if (line.trim().startsWith('--')) continue;
      
      // Detect function start
      if (line.includes('CREATE OR REPLACE FUNCTION') || line.includes('CREATE FUNCTION')) {
        inFunction = true;
        functionBody = line + '\n';
        continue;
      }
      
      // Collect function body
      if (inFunction) {
        functionBody += line + '\n';
        // Detect function end (look for $$ language)
        if (line.includes("$$ language") || line.includes("$$ LANGUAGE")) {
          sections.push({ type: 'function', sql: functionBody });
          functionBody = '';
          inFunction = false;
          continue;
        }
        continue;
      }
      
      // Regular SQL statements
      currentSection.push(line);
      
      // If line ends with semicolon and we're not in a function, it's a complete statement
      if (line.trim().endsWith(';') && !inFunction) {
        const statement = currentSection.join('\n').trim();
        if (statement.length > 0) {
          sections.push({ type: 'statement', sql: statement });
        }
        currentSection = [];
      }
    }
    
    // Execute sections in order
    console.log(`📝 Executing ${sections.length} schema sections...`);
    let successCount = 0;
    let errorCount = 0;
    
    for (const section of sections) {
      try {
        await pool.query(section.sql);
        successCount++;
      } catch (error) {
        // Ignore "already exists" errors
        if (error.message.includes('already exists') || 
            error.code === '42P07' || // duplicate_table
            error.code === '42710' || // duplicate_object
            error.code === '42723') { // duplicate_function
          successCount++;
          continue;
        }
        // Log but continue for non-critical errors
        if (!error.message.includes('does not exist')) {
          console.error(`⚠️  Error in ${section.type}: ${error.message.substring(0, 150)}`);
        }
        errorCount++;
      }
    }
    
    console.log(`✅ Schema execution complete: ${successCount} succeeded, ${errorCount} errors (some may be expected)`);

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
