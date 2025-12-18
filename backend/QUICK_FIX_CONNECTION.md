# Quick Fix: Connection Refused Error

## Problem
The Flutter web app shows `ERR_CONNECTION_REFUSED` when trying to connect to `http://localhost:3001/api/users`.

## Solution

### Step 1: Make Sure Backend Server is Running

Open a **new terminal window** and run:
```bash
cd backend
npm start
```

You should see:
```
Server is running on port 3001
Health check: http://localhost:3001/api/health
Database connected successfully
```

**IMPORTANT**: Keep this terminal window open! The server must stay running.

### Step 2: Test the Server

In another terminal, test if the server is responding:
```bash
cd backend
node test_user_creation.js
```

If you see `✅ SUCCESS: User created successfully!`, the server is working.

### Step 3: Restart Flutter App

1. Stop the Flutter app (Ctrl+C in the terminal where it's running)
2. Restart it:
   ```bash
   cd mobile
   flutter run -d chrome
   ```
   (Don't use the IP address for web - it will use localhost automatically)

### Step 4: Try Creating a User Again

After the app loads:
1. Navigate to User Management
2. Create a new user
3. Check if it saves to the database:
   ```bash
   psql -U staff4dshire -d staff4dshire -c "SELECT id, email, first_name, last_name FROM users ORDER BY created_at DESC LIMIT 5;"
   ```

## Common Issues

### Issue: "Port 3001 already in use"
**Solution**: Kill the process using port 3001:
```bash
# Find the process
netstat -ano | findstr :3001

# Kill it (replace PID with the number from above)
taskkill /PID <PID> /F

# Then start server again
cd backend
npm start
```

### Issue: Server starts but immediately crashes
**Solution**: Check the error message in the terminal. Common causes:
- Database connection failed (check `.env` file)
- Missing dependencies (`npm install`)

### Issue: Server running but Flutter app still can't connect
**Solution**: 
1. Make sure you're using `localhost` (not IP address) for web
2. Check browser console for CORS errors
3. Try accessing `http://localhost:3001/api/health` directly in browser

## Verification Checklist

- [ ] Backend server is running (`npm start` shows "Server is running")
- [ ] Test script works (`node test_user_creation.js` succeeds)
- [ ] Can access `http://localhost:3001/api/health` in browser
- [ ] Flutter app is using `localhost` (not IP address) for web
- [ ] No firewall blocking port 3001

