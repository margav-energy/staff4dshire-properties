// Test the login endpoint directly
const http = require('http');

const testData = JSON.stringify({
  email: 'admin@test.com',
  password: 'password123'
});

const options = {
  hostname: 'localhost',
  port: 3001,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(testData)
  }
};

console.log('🧪 Testing login endpoint...');
console.log(`POST http://localhost:3001/api/auth/login`);
console.log(`Data: ${testData}\n`);

const req = http.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log(`Status: ${res.statusCode}`);
    console.log('Response:', data);
    try {
      const json = JSON.parse(data);
      console.log('\nParsed Response:');
      console.log(JSON.stringify(json, null, 2));
    } catch (e) {
      console.log('\n(Response is not JSON)');
    }
    process.exit(res.statusCode === 200 || res.statusCode === 401 ? 0 : 1);
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error.message);
  console.error('\n💡 Make sure the backend server is running:');
  console.error('   cd backend && node server.js');
  process.exit(1);
});

req.write(testData);
req.end();



