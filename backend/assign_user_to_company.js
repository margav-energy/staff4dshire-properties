const pool = require('./db');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function getCompanies() {
  const result = await pool.query('SELECT id, name FROM companies ORDER BY name');
  return result.rows;
}

async function getUser(userId) {
  const result = await pool.query(
    'SELECT id, email, first_name, last_name, company_id, role FROM users WHERE id = $1',
    [userId]
  );
  return result.rows[0];
}

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function main() {
  try {
    const userId = process.argv[2];
    
    if (!userId) {
      console.log('Usage: node assign_user_to_company.js <user-id>');
      console.log('\nExample:');
      console.log('  node assign_user_to_company.js c3feb1b2-b22d-4621-b1ec-3d0d45bc3f07');
      process.exit(1);
    }

    const user = await getUser(userId);
    if (!user) {
      console.log(`User not found: ${userId}`);
      process.exit(1);
    }

    console.log(`\nCurrent User:`);
    console.log(`  Name: ${user.first_name} ${user.last_name}`);
    console.log(`  Email: ${user.email}`);
    console.log(`  Role: ${user.role}`);
    console.log(`  Current Company ID: ${user.company_id || '(None)'}`);

    const companies = await getCompanies();
    console.log(`\nAvailable Companies:`);
    companies.forEach((company, index) => {
      console.log(`  ${index + 1}. ${company.name} (${company.id})`);
    });

    const answer = await question('\nEnter company number to assign user to (or press Enter to cancel): ');
    const companyIndex = parseInt(answer) - 1;

    if (isNaN(companyIndex) || companyIndex < 0 || companyIndex >= companies.length) {
      console.log('Cancelled.');
      process.exit(0);
    }

    const selectedCompany = companies[companyIndex];
    
    // Update user's company
    await pool.query(
      'UPDATE users SET company_id = $1 WHERE id = $2',
      [selectedCompany.id, userId]
    );

    console.log(`\n✅ Successfully assigned ${user.first_name} ${user.last_name} to ${selectedCompany.name}`);
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main().finally(() => rl.close());
