# Debugging User Creation Issue

## Current Status
- Database shows 0 users after creating a user in mobile app
- Password is now being passed through the flow
- Error handling is in place

## Steps to Debug

### 1. Check if Backend Server is Running
```bash
cd backend
npm start
# Should see: "Server is running on port 3001"
```

### 2. Test API Endpoint Directly
```bash
cd backend
node test_user_creation.js
```

This will:
- Test if the API endpoint is accessible
- Verify the database connection works
- Show any error messages

### 3. Check Mobile App Logs
When creating a user, look for these messages in the mobile app console:
- `❌ CRITICAL: Failed to create user in database`
- `UserApiService.createUser error:`
- `API POST Error:`

### 4. Check API Base URL
The mobile app uses different URLs based on platform:
- **Web**: `http://localhost:3001/api`
- **Android Emulator**: `http://10.0.2.2:3001/api`
- **iOS Simulator**: `http://localhost:3001/api`
- **Physical Device**: Must set `API_BASE_URL` environment variable

To check what URL is being used, add this to your code temporarily:
```dart
print('API Base URL: ${ApiConfig.baseUrl}');
```

### 5. Common Issues

#### Issue: "Connection refused" or "Failed to connect"
**Solution**: 
- Make sure backend server is running
- Check if using physical device - need to use your computer's IP address
- For physical device: `flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3001/api`

#### Issue: "Missing required fields"
**Solution**: 
- Password is now being sent, but verify it's not null/empty
- Check backend logs to see what data is being received

#### Issue: "Database connection error"
**Solution**:
- Check backend `.env` file has correct database credentials
- Verify PostgreSQL is running
- Test database connection: `psql -U staff4dshire -d staff4dshire -c "SELECT 1;"`

### 6. Enable Backend Logging
Add this to `backend/routes/users.js` at the start of the POST route:
```javascript
router.post('/', async (req, res) => {
  console.log('=== USER CREATION REQUEST ===');
  console.log('Body:', JSON.stringify(req.body, null, 2));
  console.log('Headers:', req.headers);
  // ... rest of code
});
```

### 7. Check Database Directly
```bash
psql -U staff4dshire -d staff4dshire -c "SELECT id, email, first_name, last_name, created_at FROM users ORDER BY created_at DESC;"
```

## Next Steps
1. Run `test_user_creation.js` to verify backend works
2. Check mobile app console for error messages
3. Verify API base URL matches your platform
4. Check backend server logs when creating a user

