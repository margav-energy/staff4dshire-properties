/**
 * Combined script to run schema and seed database
 * This can be used as a build command or run manually
 * 
 * Usage: node scripts/run_schema_and_seed.js
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);
const fs = require('fs');
const path = require('path');
const pool = require('../db');
const { seedDatabase } = require('./seed_default_data');

async function runSchema() {
  try {
    const schemaPath = path.join(__dirname, '../schema.sql');
    
    if (!fs.existsSync(schemaPath)) {
      console.log('⚠️  schema.sql not found, skipping schema creation');
      return;
    }

    console.log('📄 Running database schema...');
    
    // Read schema file
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Split by semicolons and execute each statement
    const statements = schema
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const statement of statements) {
      if (statement.trim()) {
        try {
          await pool.query(statement);
        } catch (error) {
          // Ignore "already exists" errors
          if (!error.message.includes('already exists') && 
              !error.message.includes('duplicate key')) {
            console.warn(`⚠️  Schema statement warning: ${error.message}`);
          }
        }
      }
    }

    console.log('✅ Schema executed successfully');
  } catch (error) {
    console.error('❌ Error running schema:', error.message);
    throw error;
  }
}

async function runMigrations() {
  try {
    const migrationsDir = path.join(__dirname, '../migrations');
    
    if (!fs.existsSync(migrationsDir)) {
      console.log('ℹ️  No migrations directory found');
      return;
    }

    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.js'))
      .sort();

    console.log(`📦 Found ${files.length} migration(s)`);

    for (const file of files) {
      console.log(`   Running: ${file}`);
      try {
        require(path.join(migrationsDir, file));
      } catch (error) {
        console.warn(`   ⚠️  Migration ${file} had issues: ${error.message}`);
      }
    }

    console.log('✅ Migrations completed');
  } catch (error) {
    console.error('❌ Error running migrations:', error.message);
    // Don't throw - migrations are optional
  }
}

async function main() {
  console.log('\n🚀 Starting database setup...\n');

  try {
    // Run schema
    await runSchema();

    // Run migrations
    await runMigrations();

    // Seed database
    console.log('\n🌱 Seeding database...\n');
    await seedDatabase();

    console.log('\n✅ Database setup completed successfully!\n');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Database setup failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { runSchema, runMigrations };
