/**
 * Script to create a superadmin user
 * Usage: node create_superadmin.js <email> <password>
 */

const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'staff4dshire',
  user: process.env.DB_USER || 'staff4dshire',
  password: process.env.DB_PASSWORD,
});

async function createSuperadmin(email, password, firstName = 'Super', lastName = 'Admin') {
  try {
    // Hash the password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create the superadmin user
    const userId = uuidv4();
    const result = await pool.query(
      `INSERT INTO users (
        id, 
        email, 
        password_hash, 
        first_name, 
        last_name, 
        role, 
        is_superadmin, 
        company_id,
        is_active
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, email, first_name, last_name, role, is_superadmin`,
      [userId, email, passwordHash, firstName, lastName, 'superadmin', true, null, true]
    );

    console.log('✅ Superadmin created successfully!');
    console.log('User details:');
    console.log(JSON.stringify(result.rows[0], null, 2));
    
    await pool.end();
    return result.rows[0];
  } catch (error) {
    console.error('❌ Error creating superadmin:', error.message);
    if (error.code === '23505') {
      console.error('User with this email already exists!');
    }
    await pool.end();
    process.exit(1);
  }
}

// Get arguments from command line
const args = process.argv.slice(2);

if (args.length < 2) {
  console.log('Usage: node create_superadmin.js <email> <password> [firstName] [lastName]');
  console.log('Example: node create_superadmin.js superadmin@staff4dshire.com MySecurePassword123');
  process.exit(1);
}

const [email, password, firstName, lastName] = args;

createSuperadmin(email, password, firstName, lastName);



