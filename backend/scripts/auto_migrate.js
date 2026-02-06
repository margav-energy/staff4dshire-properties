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
      console.log('✅ Database schema already exists. Checking for additional tables...');
      // Still run additional schemas even if main schema exists
      await runAdditionalSchemas();
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
      console.log('✅ Users table verified.');
      
      // Check if multi-tenant columns exist, if not run multi-tenant migration
      try {
        const columnCheck = await pool.query(`
          SELECT column_name 
          FROM information_schema.columns 
          WHERE table_name = 'users' AND column_name = 'company_id'
        `);
        
        if (columnCheck.rows.length === 0) {
          console.log('📄 Running multi-tenant schema migration...');
          
          // First, ensure companies table exists
          const companiesExists = await checkTableExists('companies');
          if (!companiesExists) {
            console.log('📄 Creating companies table...');
            try {
              await pool.query(`
                CREATE TABLE IF NOT EXISTS companies (
                  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                  name VARCHAR(255) NOT NULL,
                  domain VARCHAR(255),
                  address TEXT,
                  phone_number VARCHAR(20),
                  email VARCHAR(255),
                  is_active BOOLEAN DEFAULT TRUE,
                  subscription_tier VARCHAR(50) DEFAULT 'basic',
                  max_users INTEGER DEFAULT 50,
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
              `);
              console.log('✅ Companies table created.');
            } catch (createError) {
              console.log(`⚠️  Failed to create companies table: ${createError.message.substring(0, 200)}`);
            }
          } else {
            console.log('✅ Companies table already exists.');
          }
          
          const multiTenantPath = path.join(__dirname, '../schema_multi_tenant.sql');
          if (fs.existsSync(multiTenantPath)) {
            const multiTenantSchema = fs.readFileSync(multiTenantPath, 'utf8');
            try {
              // Execute multi-tenant schema
              await pool.query(multiTenantSchema);
              console.log('✅ Multi-tenant schema applied successfully!');
              
              // Verify columns were added
              const verifyCheck = await pool.query(`
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'users' AND column_name IN ('company_id', 'is_superadmin')
              `);
              console.log(`✅ Verified ${verifyCheck.rows.length} multi-tenant columns added.`);
            } catch (mtError) {
              console.log(`⚠️  Multi-tenant migration had errors: ${mtError.message.substring(0, 200)}`);
              // Try to add columns manually if schema fails
              try {
                console.log('🔄 Attempting to add columns manually...');
                await pool.query(`
                  ALTER TABLE users 
                  ADD COLUMN IF NOT EXISTS company_id UUID,
                  ADD COLUMN IF NOT EXISTS is_superadmin BOOLEAN DEFAULT FALSE;
                `);
                await pool.query(`
                  ALTER TABLE users 
                  DROP CONSTRAINT IF EXISTS users_role_check;
                `);
                await pool.query(`
                  ALTER TABLE users 
                  ADD CONSTRAINT users_role_check 
                  CHECK (role IN ('staff', 'supervisor', 'admin', 'superadmin'));
                `);
                console.log('✅ Manually added multi-tenant columns and updated role constraint.');
              } catch (manualError) {
                console.log(`⚠️  Manual column addition failed: ${manualError.message.substring(0, 200)}`);
              }
            }
          } else {
            console.log('⚠️  schema_multi_tenant.sql not found. Adding columns manually...');
            try {
              await pool.query(`
                ALTER TABLE users 
                ADD COLUMN IF NOT EXISTS company_id UUID,
                ADD COLUMN IF NOT EXISTS is_superadmin BOOLEAN DEFAULT FALSE;
              `);
              await pool.query(`
                ALTER TABLE users 
                DROP CONSTRAINT IF EXISTS users_role_check;
              `);
              await pool.query(`
                ALTER TABLE users 
                ADD CONSTRAINT users_role_check 
                CHECK (role IN ('staff', 'supervisor', 'admin', 'superadmin'));
              `);
              console.log('✅ Manually added multi-tenant columns.');
            } catch (manualError) {
              console.log(`⚠️  Manual column addition failed: ${manualError.message}`);
            }
          }
          
          // Also add password reset fields if they don't exist
          try {
            const passwordFieldsCheck = await pool.query(`
              SELECT column_name 
              FROM information_schema.columns 
              WHERE table_name = 'users' AND column_name = 'must_change_password'
            `);
            
            if (passwordFieldsCheck.rows.length === 0) {
              console.log('📄 Adding password reset fields...');
              await pool.query(`
                ALTER TABLE users 
                ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT FALSE,
                ADD COLUMN IF NOT EXISTS password_reset_token VARCHAR(255),
                ADD COLUMN IF NOT EXISTS password_reset_token_expires_at TIMESTAMP;
              `);
              console.log('✅ Password reset fields added.');
            }
          } catch (passwordFieldsError) {
            console.log(`⚠️  Could not add password reset fields: ${passwordFieldsError.message.substring(0, 200)}`);
          }
        } else {
          console.log('✅ Multi-tenant columns already exist on users table.');
          
          // Still check and update role constraint to include superadmin
          try {
            await pool.query(`
              ALTER TABLE users 
              DROP CONSTRAINT IF EXISTS users_role_check;
            `);
            await pool.query(`
              ALTER TABLE users 
              ADD CONSTRAINT users_role_check 
              CHECK (role IN ('staff', 'supervisor', 'admin', 'superadmin'));
            `);
            console.log('✅ Updated role constraint to include superadmin.');
          } catch (constraintError) {
            // Constraint might already be correct, ignore
          }
          
          // Check and add company_id to other tables that might be missing it
          console.log('📄 Checking other tables for company_id columns...');
          const tablesToCheck = ['projects', 'conversations', 'time_entries', 'documents', 'notifications'];
          
          for (const tableName of tablesToCheck) {
            try {
              const tableExists = await checkTableExists(tableName);
              if (tableExists) {
                const columnCheck = await pool.query(`
                  SELECT column_name 
                  FROM information_schema.columns 
                  WHERE table_name = $1 AND column_name = 'company_id'
                `, [tableName]);
                
                if (columnCheck.rows.length === 0) {
                  console.log(`📄 Adding company_id to ${tableName} table...`);
                  await pool.query(`
                    ALTER TABLE ${tableName} 
                    ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;
                  `);
                  console.log(`✅ Added company_id to ${tableName} table.`);
                }
              }
            } catch (tableError) {
              console.log(`⚠️  Could not add company_id to ${tableName}: ${tableError.message.substring(0, 100)}`);
            }
          }
        }
      } catch (checkError) {
        console.log('⚠️  Could not check for multi-tenant columns:', checkError.message);
      }
      
      // Run additional schema files if needed
      await runAdditionalSchemas();
      
      console.log('✅ Schema migration complete!');
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

async function runAdditionalSchemas() {
  try {
    // Check and run invitation_requests schema
    const invitationRequestsExists = await checkTableExists('invitation_requests');
    if (!invitationRequestsExists) {
      console.log('📄 Running invitation_requests schema...');
      
      // Try migration SQL file first (uses gen_random_uuid())
      const migrationPath = path.join(__dirname, '../migrations/add_invitation_tables.sql');
      if (fs.existsSync(migrationPath)) {
        try {
          const schema = fs.readFileSync(migrationPath, 'utf8');
          await pool.query(schema);
          console.log('✅ invitation_requests and company_invitations tables created successfully!');
          return; // Success, exit early
        } catch (migrationError) {
          console.log(`⚠️  Migration file failed: ${migrationError.message.substring(0, 150)}`);
          // Fall through to try individual schema files
        }
      }
      
      // Fallback: Try individual schema files
      const invitationRequestsPath = path.join(__dirname, '../schema_invitation_requests.sql');
      if (fs.existsSync(invitationRequestsPath)) {
        const schema = fs.readFileSync(invitationRequestsPath, 'utf8');
        try {
          await pool.query(schema);
          console.log('✅ invitation_requests table created successfully!');
        } catch (error) {
          // If uuid_generate_v4() fails, try with gen_random_uuid()
          if (error.message.includes('uuid_generate_v4') || error.message.includes('function uuid_generate_v4')) {
            console.log('⚠️  uuid_generate_v4() not available, using gen_random_uuid() instead...');
            const fixedSchema = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
            await pool.query(fixedSchema);
            console.log('✅ invitation_requests table created with gen_random_uuid()!');
          } else {
            throw error;
          }
        }
      } else {
        console.log('⚠️  schema_invitation_requests.sql not found.');
      }
    } else {
      console.log('✅ invitation_requests table already exists.');
    }

    // Check and run company_invitations schema
    const companyInvitationsExists = await checkTableExists('company_invitations');
    if (!companyInvitationsExists) {
      console.log('📄 Running company_invitations schema...');
      const companyInvitationsPath = path.join(__dirname, '../schema_company_invitations.sql');
      if (fs.existsSync(companyInvitationsPath)) {
        const schema = fs.readFileSync(companyInvitationsPath, 'utf8');
        try {
          await pool.query(schema);
          console.log('✅ company_invitations table created successfully!');
        } catch (error) {
          // If uuid_generate_v4() fails, try with gen_random_uuid()
          if (error.message.includes('uuid_generate_v4') || error.message.includes('function uuid_generate_v4')) {
            console.log('⚠️  uuid_generate_v4() not available, using gen_random_uuid() instead...');
            const fixedSchema = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
            await pool.query(fixedSchema);
            console.log('✅ company_invitations table created with gen_random_uuid()!');
          } else {
            throw error;
          }
        }
      } else {
        console.log('⚠️  schema_company_invitations.sql not found.');
      }
    } else {
      console.log('✅ company_invitations table already exists.');
    }

    // Check and run conversations schema
    const conversationsExists = await checkTableExists('conversations');
    if (!conversationsExists) {
      console.log('📄 Running conversations schema...');
      const chatTablesPath = path.join(__dirname, '../migrations/add_chat_tables_v2.sql');
      if (fs.existsSync(chatTablesPath)) {
        const schema = fs.readFileSync(chatTablesPath, 'utf8');
        try {
          await pool.query(schema);
          console.log('✅ conversations, conversation_participants, and messages tables created successfully!');
        } catch (error) {
          // If uuid_generate_v4() fails, try with gen_random_uuid()
          if (error.message.includes('uuid_generate_v4') || error.message.includes('function uuid_generate_v4')) {
            console.log('⚠️  uuid_generate_v4() not available, using gen_random_uuid() instead...');
            const fixedSchema = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
            await pool.query(fixedSchema);
            console.log('✅ conversations tables created with gen_random_uuid()!');
          } else {
            console.log(`⚠️  Could not create conversations tables: ${error.message.substring(0, 200)}`);
          }
        }
      } else {
        console.log('⚠️  migrations/add_chat_tables_v2.sql not found.');
      }
    } else {
      console.log('✅ conversations table already exists.');
    }

    // Check and run incidents schema
    const incidentsExists = await checkTableExists('incidents');
    if (!incidentsExists) {
      console.log('📄 Running incidents schema...');
      const incidentsPath = path.join(__dirname, '../schema_incidents_v2.sql');
      if (fs.existsSync(incidentsPath)) {
        const schema = fs.readFileSync(incidentsPath, 'utf8');
        try {
          await pool.query(schema);
          console.log('✅ incidents table created successfully!');
        } catch (error) {
          // If uuid_generate_v4() fails, try with gen_random_uuid()
          if (error.message.includes('uuid_generate_v4') || error.message.includes('function uuid_generate_v4')) {
            console.log('⚠️  uuid_generate_v4() not available, using gen_random_uuid() instead...');
            const fixedSchema = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
            await pool.query(fixedSchema);
            console.log('✅ incidents table created with gen_random_uuid()!');
          } else {
            console.log(`⚠️  Could not create incidents table: ${error.message.substring(0, 200)}`);
          }
        }
      } else {
        console.log('⚠️  schema_incidents_v2.sql not found.');
      }
    } else {
      console.log('✅ incidents table already exists.');
    }

    // Check and run onboarding schema
    const onboardingProgressExists = await checkTableExists('onboarding_progress');
    if (!onboardingProgressExists) {
      console.log('📄 Running onboarding schema...');
      const onboardingPath = path.join(__dirname, '../schema_onboarding.sql');
      if (fs.existsSync(onboardingPath)) {
        const schema = fs.readFileSync(onboardingPath, 'utf8');
        try {
          await pool.query(schema);
          console.log('✅ onboarding tables created successfully!');
        } catch (error) {
          // If uuid_generate_v4() fails, try with gen_random_uuid()
          if (error.message.includes('uuid_generate_v4') || error.message.includes('function uuid_generate_v4')) {
            console.log('⚠️  uuid_generate_v4() not available, using gen_random_uuid() instead...');
            const fixedSchema = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
            await pool.query(fixedSchema);
            console.log('✅ onboarding tables created with gen_random_uuid()!');
          } else {
            console.log(`⚠️  Could not create onboarding tables: ${error.message.substring(0, 200)}`);
          }
        }
      } else {
        console.log('⚠️  schema_onboarding.sql not found.');
      }
    } else {
      console.log('✅ onboarding_progress table already exists.');
    }

    // Check and run CIS onboarding schema
    const cisOnboardingExists = await checkTableExists('cis_onboarding');
    if (!cisOnboardingExists) {
      console.log('📄 Running CIS onboarding schema...');
      const cisOnboardingPath = path.join(__dirname, '../schema_cis_onboarding.sql');
      if (fs.existsSync(cisOnboardingPath)) {
        const schema = fs.readFileSync(cisOnboardingPath, 'utf8');
        try {
          await pool.query(schema);
          console.log('✅ cis_onboarding table created successfully!');
        } catch (error) {
          // If uuid_generate_v4() fails, try with gen_random_uuid()
          if (error.message.includes('uuid_generate_v4') || error.message.includes('function uuid_generate_v4')) {
            console.log('⚠️  uuid_generate_v4() not available, using gen_random_uuid() instead...');
            const fixedSchema = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
            await pool.query(fixedSchema);
            console.log('✅ cis_onboarding table created with gen_random_uuid()!');
          } else {
            console.log(`⚠️  Could not create cis_onboarding table: ${error.message.substring(0, 200)}`);
          }
        }
      } else {
        console.log('⚠️  schema_cis_onboarding.sql not found.');
      }
    } else {
      console.log('✅ cis_onboarding table already exists.');
    }

    // Check and run job_completions and invoices schema
    const jobCompletionsExists = await checkTableExists('job_completions');
    if (!jobCompletionsExists) {
      console.log('📄 Running job_completions and invoices schema...');
      const jobCompletionPath = path.join(__dirname, '../schema_job_completion_v2.sql');
      if (fs.existsSync(jobCompletionPath)) {
        const schema = fs.readFileSync(jobCompletionPath, 'utf8');
        try {
          await pool.query(schema);
          console.log('✅ job_completions and invoices tables created successfully!');
        } catch (error) {
          // If uuid_generate_v4() fails, try with gen_random_uuid()
          if (error.message.includes('uuid_generate_v4') || error.message.includes('function uuid_generate_v4')) {
            console.log('⚠️  uuid_generate_v4() not available, using gen_random_uuid() instead...');
            const fixedSchema = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
            await pool.query(fixedSchema);
            console.log('✅ job_completions and invoices tables created with gen_random_uuid()!');
          } else {
            console.log(`⚠️  Could not create job_completions/invoices tables: ${error.message.substring(0, 200)}`);
          }
        }
      } else {
        console.log('⚠️  schema_job_completion_v2.sql not found.');
      }
    } else {
      console.log('✅ job_completions table already exists.');
    }

    // Check and add password reset fields if they don't exist
    try {
      const passwordResetCheck = await pool.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'password_reset_token'
      `);
      
      if (passwordResetCheck.rows.length === 0) {
        console.log('📄 Adding password reset fields to users table...');
        await pool.query(`
          ALTER TABLE users 
          ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT FALSE,
          ADD COLUMN IF NOT EXISTS password_reset_token VARCHAR(255),
          ADD COLUMN IF NOT EXISTS password_reset_token_expires_at TIMESTAMP;
        `);
        
        // Create index for password reset token
        try {
          await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_users_password_reset_token 
            ON users(password_reset_token) 
            WHERE password_reset_token IS NOT NULL;
          `);
        } catch (indexError) {
          // Index might already exist, ignore
        }
        
        console.log('✅ Password reset fields added successfully!');
      } else {
        console.log('✅ Password reset fields already exist.');
      }
    } catch (passwordResetError) {
      console.log(`⚠️  Could not add password reset fields: ${passwordResetError.message.substring(0, 200)}`);
    }
  } catch (error) {
    console.log(`⚠️  Error running additional schemas: ${error.message.substring(0, 200)}`);
    // Don't throw - these are optional schemas
  }
}

module.exports = { runSchema };
