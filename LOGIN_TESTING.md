# Login Testing Guide

## ✅ Backend Status

**Backend API is working correctly!** Test results:
- ✅ Login endpoint responds (200 status)
- ✅ Password verification works
- ✅ User data returned correctly

## 🔑 Test Credentials

I've created/updated a test admin user:

- **Email:** `admin@test.com`
- **Password:** `password123`

## 🧪 Testing Steps

1. **Make sure backend is running:**
   ```bash
   cd backend
   node server.js
   ```

2. **Try logging in with:**
   - Email: `admin@test.com`
   - Password: `password123`

3. **If login still fails, check:**

   **A. Browser Console (F12)**
   - Look for any error messages
   - Check Network tab to see if API call is being made
   - Check the response status and body

   **B. Backend Terminal**
   - Should show the login request being received
   - Check for any error messages

   **C. Common Issues:**
   - ❌ CORS errors → Check backend CORS settings
   - ❌ Connection refused → Backend not running on port 3001
   - ❌ Wrong API URL → Check `ApiConfig.baseUrl`
   - ❌ Invalid credentials → Use `admin@test.com` / `password123`

## 📋 Other Available Users

You can also try logging in with existing users (but you need their passwords):
- `akosua@mail.com` (supervisor)
- `tester@gmail.com` (staff)
- `jane@mail.com` (supervisor)
- `jake@mail.com` (staff)
- `moses@mail.com` (staff)

To see all users:
```bash
cd backend
node show_user_passwords.js
```

## 🔧 Debug Commands

**Test login endpoint directly:**
```bash
cd backend
node test_auth_endpoint.js
```

**Check if users exist:**
```bash
cd backend
node test_login.js
```

## 🐛 If Still Not Working

1. Open browser DevTools (F12)
2. Go to Network tab
3. Try logging in
4. Look for the `/api/auth/login` request
5. Check:
   - Request URL (should be `http://localhost:3001/api/auth/login`)
   - Request payload (email/password)
   - Response status (should be 200)
   - Response body (should have `success: true`)

Share the error message or response you see!



