const { Pool } = require('pg');
require('dotenv').config();

// Validate required environment variables
const dbPassword = process.env.DB_PASSWORD;
if (!dbPassword || dbPassword.trim() === '') {
  console.error('\n❌ ERROR: DB_PASSWORD is not set or is empty in .env file\n');
  console.error('📝 To fix this:\n');
  console.error('1. Create a .env file in the backend directory');
  console.error('2. Add your database password to it:\n');
  console.error('   DB_HOST=localhost');
  console.error('   DB_PORT=5432');
  console.error('   DB_NAME=staff4dshire');
  console.error('   DB_USER=staff4dshire');
  console.error('   DB_PASSWORD=your_actual_password_here');
  console.error('   PORT=3001');
  console.error('   NODE_ENV=development\n');
  console.error('3. If the user doesn\'t have a password, set one in PostgreSQL:');
  console.error('   psql -U postgres');
  console.error("   ALTER USER staff4dshire WITH PASSWORD 'your_password';\n");
  console.error('📖 See QUICK_FIX.md for detailed instructions\n');
  process.exit(1);
}

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'staff4dshire',
  user: process.env.DB_USER || 'staff4dshire',
  password: process.env.DB_PASSWORD,
  // SSL required for Render PostgreSQL databases
  ssl: process.env.NODE_ENV === 'production' ? {
    rejectUnauthorized: false // Render uses self-signed certificates
  } : false,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

// Test connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Database connection error:', err);
  } else {
    console.log('Database connected successfully');
  }
});

module.exports = pool;

