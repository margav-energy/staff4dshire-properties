// Migration script to add invitation_requests and company_invitations tables
// Run with: node migrations/add_invitation_tables.js

const pool = require('../db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('Starting invitation tables migration...');
    
    // Read and execute invitation_requests schema
    const invitationRequestsPath = path.join(__dirname, '../schema_invitation_requests.sql');
    if (fs.existsSync(invitationRequestsPath)) {
      let schema = fs.readFileSync(invitationRequestsPath, 'utf8');
      
      // Replace uuid_generate_v4() with gen_random_uuid() if needed
      schema = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
      
      await client.query(schema);
      console.log('✅ invitation_requests table created successfully!');
    } else {
      console.log('⚠️  schema_invitation_requests.sql not found.');
    }
    
    // Read and execute company_invitations schema
    const companyInvitationsPath = path.join(__dirname, '../schema_company_invitations.sql');
    if (fs.existsSync(companyInvitationsPath)) {
      let schema = fs.readFileSync(companyInvitationsPath, 'utf8');
      
      // Replace uuid_generate_v4() with gen_random_uuid() if needed
      schema = schema.replace(/uuid_generate_v4\(\)/g, 'gen_random_uuid()');
      
      await client.query(schema);
      console.log('✅ company_invitations table created successfully!');
    } else {
      console.log('⚠️  schema_company_invitations.sql not found.');
    }
    
    await client.query('COMMIT');
    console.log('✅ Migration completed successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    client.release();
  }
}

runMigration()
  .then(() => {
    console.log('Migration script completed.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Migration script failed:', error);
    process.exit(1);
  });
