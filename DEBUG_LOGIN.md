# Debug Login Issue

## ✅ Backend is Working

The backend login endpoint is working correctly when tested directly. 

## 🔍 What to Check

### Step 1: Open Browser DevTools

1. Press `F12` in your browser
2. Go to **Console** tab
3. Go to **Network** tab
4. Try logging in

### Step 2: Look for These in Console

You should see debug messages like:
- `🔐 Attempting login via API: http://localhost:3001/api/auth/login`
- `📧 Email: admin@test.com`
- `🌐 API POST: http://localhost:3001/api/auth/login`
- `📥 Response Status: 200` (or error code)
- `📥 Response Body: {...}`

### Step 3: Check Network Tab

1. Find the request to `/api/auth/login`
2. Check:
   - **Status**: Should be `200` (green) or `401` (yellow)
   - **Request Payload**: Should have email and password
   - **Response**: Should have `{"success": true, "user": {...}}`

### Step 4: Common Issues

**If you see CORS errors:**
- Backend CORS is enabled, but double-check it's running

**If you see "Connection refused":**
- Backend server is not running on port 3001
- Run: `cd backend && node server.js`

**If you see 401 "Invalid email or password":**
- Wrong credentials
- Use: `admin@test.com` / `password123`

**If you see 500 error:**
- Check backend terminal for error details

**If no request appears in Network tab:**
- JavaScript error preventing the request
- Check Console tab for errors

## 📝 What to Share

If login still doesn't work, please share:
1. **Console tab** - Any error messages
2. **Network tab** - The `/api/auth/login` request details (status, request, response)
3. **Backend terminal** - Any error messages when you try to login

## 🔑 Test Credentials

- **Email:** `admin@test.com`
- **Password:** `password123`



