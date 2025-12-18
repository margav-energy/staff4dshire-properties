// Test script to verify user creation endpoint works
const http = require('http');

const testUser = {
  email: 'test@staff4dshire.com',
  password_hash: 'testpassword123',
  first_name: 'Test',
  last_name: 'User',
  role: 'staff',
  phone_number: '+44 7700 900123',
  is_active: true
};

const postData = JSON.stringify(testUser);

const options = {
  hostname: 'localhost',
  port: 3001,
  path: '/api/users',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  }
};

console.log('Testing user creation endpoint...');
console.log('URL: http://localhost:3001/api/users');
console.log('Data:', testUser);
console.log('');

const req = http.request(options, (res) => {
  let data = '';

  console.log(`Status Code: ${res.statusCode}`);
  console.log(`Headers:`, res.headers);
  console.log('');

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('Response Body:');
    try {
      const parsed = JSON.parse(data);
      console.log(JSON.stringify(parsed, null, 2));
    } catch (e) {
      console.log(data);
    }
    
    if (res.statusCode >= 200 && res.statusCode < 300) {
      console.log('\n✅ SUCCESS: User created successfully!');
    } else {
      console.log('\n❌ FAILED: User creation failed');
    }
  });
});

req.on('error', (e) => {
  console.error('❌ ERROR:', e.message);
  console.error('\nPossible issues:');
  console.error('1. Backend server is not running');
  console.error('2. Server is not listening on port 3001');
  console.error('3. Connection refused');
  console.error('\nTo fix:');
  console.error('1. Make sure backend server is running: cd backend && npm start');
  console.error('2. Check if port 3001 is available');
});

req.write(postData);
req.end();

