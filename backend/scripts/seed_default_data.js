/**
 * Database Seeding Script
 * Creates default users and test data for demonstration
 * This script runs automatically on server start if SEED_DATABASE=true
 * 
 * Default Credentials:
 * - Superadmin: superadmin@staff4dshire.com / Admin123!
 * - Admin: admin@staff4dshire.com / Admin123!
 * - Supervisor: supervisor@staff4dshire.com / Supervisor123!
 * - Staff: staff@staff4dshire.com / Staff123!
 */

const pool = require('../db');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');

// Default credentials - CHANGE THESE IN PRODUCTION!
const DEFAULT_CREDENTIALS = {
  superadmin: {
    email: 'superadmin@staff4dshire.com',
    password: 'Admin123!',
    firstName: 'Super',
    lastName: 'Admin',
    role: 'superadmin',
    isSuperadmin: true,
  },
  admin: {
    email: 'admin@staff4dshire.com',
    password: 'Admin123!',
    firstName: 'John',
    lastName: 'Admin',
    role: 'admin',
    isSuperadmin: false,
  },
  supervisor: {
    email: 'supervisor@staff4dshire.com',
    password: 'Supervisor123!',
    firstName: 'Jane',
    lastName: 'Supervisor',
    role: 'supervisor',
    isSuperadmin: false,
  },
  staff: {
    email: 'staff@staff4dshire.com',
    password: 'Staff123!',
    firstName: 'Bob',
    lastName: 'Staff',
    role: 'staff',
    isSuperadmin: false,
  },
};

async function hashPassword(password) {
  const saltRounds = 10;
  return await bcrypt.hash(password, saltRounds);
}

async function checkIfSeeded() {
  try {
    // Check if any users exist
    const result = await pool.query('SELECT COUNT(*) as count FROM users');
    return parseInt(result.rows[0].count) > 0;
  } catch (error) {
    // Table might not exist yet
    return false;
  }
}

async function checkColumnExists(tableName, columnName) {
  try {
    const result = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = $1 AND column_name = $2
    `, [tableName, columnName]);
    return result.rows.length > 0;
  } catch (error) {
    return false;
  }
}

async function createUser(userData, companyId = null) {
  try {
    const passwordHash = await hashPassword(userData.password);
    const userId = uuidv4();
    
    // Check which columns exist
    const hasCompanyId = await checkColumnExists('users', 'company_id');
    const hasIsSuperadmin = await checkColumnExists('users', 'is_superadmin');
    
    // Build query based on available columns
    let columns = ['id', 'email', 'password_hash', 'first_name', 'last_name', 'role', 'is_active', 'phone_number'];
    let values = [userId, userData.email.toLowerCase().trim(), passwordHash, userData.firstName, userData.lastName, userData.role, true, null];
    let placeholders = [];
    
    if (hasIsSuperadmin) {
      columns.push('is_superadmin');
      values.push(userData.isSuperadmin || false);
    }
    
    if (hasCompanyId && companyId) {
      columns.push('company_id');
      values.push(companyId);
    }
    
    // Build placeholders
    for (let i = 1; i <= values.length; i++) {
      placeholders.push(`$${i}`);
    }
    
    const result = await pool.query(
      `INSERT INTO users (${columns.join(', ')})
      VALUES (${placeholders.join(', ')})
      ON CONFLICT (email) DO NOTHING
      RETURNING id, email, first_name, last_name, role`,
      values
    );

    if (result.rows.length > 0) {
      console.log(`✅ Created user: ${userData.email} (${userData.role})`);
      return result.rows[0];
    } else {
      console.log(`ℹ️  User already exists: ${userData.email}`);
      // Get existing user
      const existing = await pool.query(
        'SELECT id, email, first_name, last_name, role FROM users WHERE email = $1',
        [userData.email.toLowerCase().trim()]
      );
      return existing.rows[0] || null;
    }
  } catch (error) {
    console.error(`❌ Error creating user ${userData.email}:`, error.message);
    return null;
  }
}

async function checkCompaniesTableExists() {
  try {
    await pool.query('SELECT 1 FROM companies LIMIT 1');
    return true;
  } catch (error) {
    return false;
  }
}

async function createCompany() {
  try {
    // Check if companies table exists
    const tableExists = await checkCompaniesTableExists();
    if (!tableExists) {
      console.log('ℹ️  Companies table does not exist. Creating it...');
      
      // Create companies table if it doesn't exist (for basic multi-tenancy)
      try {
        await pool.query(`
          CREATE TABLE IF NOT EXISTS companies (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255),
            subscription_tier VARCHAR(50) DEFAULT 'premium',
            max_users INTEGER DEFAULT 100,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `);
        console.log('✅ Created companies table');
      } catch (createError) {
        console.log('⚠️  Could not create companies table:', createError.message);
        return null;
      }
    }

    // Check if demo company exists
    const existing = await pool.query(
      "SELECT id FROM companies WHERE name = 'Demo Company'"
    );
    
    if (existing.rows.length > 0) {
      console.log('ℹ️  Demo Company already exists');
      return existing.rows[0].id;
    }

    const companyId = uuidv4();
    await pool.query(
      `INSERT INTO companies (id, name, email, subscription_tier, max_users)
       VALUES ($1, $2, $3, $4, $5)`,
      [companyId, 'Demo Company', 'admin@staff4dshire.com', 'premium', 100]
    );

    console.log('✅ Created Demo Company');
    return companyId;
  } catch (error) {
    console.error('❌ Error creating company:', error.message);
    return null;
  }
}

async function createProjects(companyId) {
  try {
    // If no company, create projects without company_id
    const projects = [
      {
        name: 'Main Office Building',
        address: '123 Main Street, London, UK',
        description: 'Headquarters office renovation project',
      },
      {
        name: 'Construction Site A',
        address: '456 Industrial Way, Manchester, UK',
        description: 'New construction project',
      },
      {
        name: 'Warehouse Facility',
        address: '789 Commerce Road, Birmingham, UK',
        description: 'Warehouse maintenance and upgrades',
      },
    ];

    const createdProjects = [];

    for (const project of projects) {
      try {
        // Check if project exists
        let existing;
        if (companyId) {
          existing = await pool.query(
            'SELECT id FROM projects WHERE name = $1 AND (company_id = $2 OR company_id IS NULL)',
            [project.name, companyId]
          );
        } else {
          existing = await pool.query(
            'SELECT id FROM projects WHERE name = $1 AND company_id IS NULL',
            [project.name]
          );
        }

        if (existing.rows.length > 0) {
          console.log(`ℹ️  Project already exists: ${project.name}`);
          createdProjects.push(existing.rows[0].id);
          continue;
        }

        const projectId = uuidv4();
        
        // Try with company_id first, fallback to without if column doesn't exist
        try {
          if (companyId) {
            await pool.query(
              `INSERT INTO projects (id, name, address, description, company_id, is_active)
               VALUES ($1, $2, $3, $4, $5, $6)`,
              [projectId, project.name, project.address, project.description, companyId, true]
            );
          } else {
            await pool.query(
              `INSERT INTO projects (id, name, address, description, is_active)
               VALUES ($1, $2, $3, $4, $5)`,
              [projectId, project.name, project.address, project.description, true]
            );
          }
        } catch (err) {
          // Fallback if company_id column doesn't exist
          await pool.query(
            `INSERT INTO projects (id, name, address, description, is_active)
             VALUES ($1, $2, $3, $4, $5)`,
            [projectId, project.name, project.address, project.description, true]
          );
        }

        console.log(`✅ Created project: ${project.name}`);
        createdProjects.push(projectId);
      } catch (error) {
        console.warn(`⚠️  Could not create project ${project.name}: ${error.message}`);
      }
    }

    return createdProjects;
  } catch (error) {
    console.error('❌ Error creating projects:', error.message);
    return [];
  }
}

async function assignUsersToCompany(users, companyId) {
  try {
    for (const user of users) {
      if (user && user.id) {
        await pool.query(
          'UPDATE users SET company_id = $1 WHERE id = $2 AND company_id IS NULL',
          [companyId, user.id]
        );
      }
    }
    console.log('✅ Assigned users to company');
  } catch (error) {
    console.error('❌ Error assigning users to company:', error.message);
  }
}

async function seedDatabase() {
  console.log('\n🌱 Starting database seeding...\n');

  try {
    // Check if already seeded
    const alreadySeeded = await checkIfSeeded();
    if (alreadySeeded) {
      console.log('ℹ️  Database already contains data. Skipping seed.');
      console.log('   To re-seed, delete all users first or set FORCE_SEED=true\n');
      return;
    }

    // Create company
    const companyId = await createCompany();
    if (!companyId) {
      console.error('❌ Failed to create company. Aborting seed.');
      return;
    }

    // Create superadmin (no company)
    const superadmin = await createUser(DEFAULT_CREDENTIALS.superadmin, null);
    
    // Create company users
    const admin = await createUser(DEFAULT_CREDENTIALS.admin, companyId);
    const supervisor = await createUser(DEFAULT_CREDENTIALS.supervisor, companyId);
    const staff = await createUser(DEFAULT_CREDENTIALS.staff, companyId);

    // Assign users to company (in case they were created before company)
    await assignUsersToCompany([admin, supervisor, staff], companyId);

    // Create projects (works with or without company_id)
    await createProjects(companyId);

    console.log('\n✅ Database seeding completed successfully!\n');
    console.log('📋 Default Login Credentials:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🔴 Superadmin:');
    console.log(`   Email: ${DEFAULT_CREDENTIALS.superadmin.email}`);
    console.log(`   Password: ${DEFAULT_CREDENTIALS.superadmin.password}`);
    console.log('');
    console.log('🟢 Admin:');
    console.log(`   Email: ${DEFAULT_CREDENTIALS.admin.email}`);
    console.log(`   Password: ${DEFAULT_CREDENTIALS.admin.password}`);
    console.log('');
    console.log('🟡 Supervisor:');
    console.log(`   Email: ${DEFAULT_CREDENTIALS.supervisor.email}`);
    console.log(`   Password: ${DEFAULT_CREDENTIALS.supervisor.password}`);
    console.log('');
    console.log('🔵 Staff:');
    console.log(`   Email: ${DEFAULT_CREDENTIALS.staff.email}`);
    console.log(`   Password: ${DEFAULT_CREDENTIALS.staff.password}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  } catch (error) {
    console.error('❌ Error seeding database:', error);
    throw error;
  }
}

// Export for use in server.js
module.exports = { seedDatabase, DEFAULT_CREDENTIALS };

// Run if called directly
if (require.main === module) {
  seedDatabase()
    .then(() => {
      console.log('Seeding complete');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Seeding failed:', error);
      process.exit(1);
    });
}
