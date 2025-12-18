# Testing API Connection - Step by Step Guide

## ✅ Backend is Running!

Your backend server is confirmed running:
- ✅ Server on port 3001
- ✅ Health check working
- ✅ Database connected

## Next Steps: Test the Mobile App Connection

### 1. Check API Configuration

The mobile app should automatically connect to:
- **Web/Chrome**: `http://localhost:3001/api`
- **Android Emulator**: `http://10.0.2.2:3001/api`
- **Physical Device**: Needs your computer's IP address

### 2. Test User Sync

Now that UserProvider is updated, test if it syncs:

**What I Changed:**
- ✅ UserProvider now loads from API on startup
- ✅ UserProvider syncs with API when creating/updating/deleting users
- ✅ Falls back to local storage if API is unavailable

**How to Test:**

1. **Start the mobile app**
   ```bash
   cd mobile
   flutter run
   ```

2. **Check the console/logs** for:
   - "Synced X users from API" - Success!
   - "Failed to sync users from API" - Connection issue

3. **Create a new user:**
   - Go to User Management
   - Add a new user
   - Check if it appears in the database:
     ```bash
     psql -d staff4dshire -c "SELECT email, first_name, last_name FROM users;"
     ```

4. **Restart the backend server:**
   - Stop the server (Ctrl+C)
   - Start it again
   - Check if the user still exists in the app
   - ✅ Should still be there (synced from database!)

### 3. Verify Database Persistence

**Check users in database:**
```bash
psql -d staff4dshire -c "SELECT id, email, first_name, last_name, role FROM users;"
```

**Create a user from the app, then check again:**
- The new user should appear in the database
- Restart the backend server
- The user should still exist

## Expected Behavior

### When API is Available:
1. App loads cached users instantly (from local storage)
2. App syncs with API in background
3. New users are saved to both API and local cache
4. Data persists in PostgreSQL database

### When API is Unavailable:
1. App loads cached users (offline mode)
2. New users are saved locally only
3. Will sync when API is back online (next time you load users)

## Troubleshooting

### "Connection refused" Error
**Problem:** Mobile app can't reach backend server

**Solutions:**
1. **Check if backend is running:**
   ```bash
   curl http://localhost:3001/api/health
   ```

2. **For physical devices, set API URL:**
   ```bash
   # Find your IP
   ipconfig  # Windows
   ifconfig  # Mac/Linux
   
   # Run with IP
   flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3001/api
   ```

3. **Check firewall:** Make sure port 3001 is not blocked

### Users Not Syncing
**Problem:** Users aren't appearing in database

**Check:**
1. Backend server is running
2. Database connection is working
3. Check backend logs for errors
4. Check mobile app console for API errors

### Data Still Not Persisting
**Problem:** Data disappears after server restart

**Verify:**
1. Data is actually in PostgreSQL (not just in memory)
   ```bash
   psql -d staff4dshire -c "SELECT COUNT(*) FROM users;"
   ```

2. UserProvider is using API (check logs for "Synced from API")

3. API calls are succeeding (check backend logs)

## Success Indicators

✅ **Working correctly when:**
- Users appear in database after creating them in app
- Users persist after backend server restart
- App shows "Synced X users from API" in logs
- No "Connection refused" errors

## Next Providers to Update

After UserProvider works:
- ⏳ TimesheetProvider
- ⏳ ProjectProvider
- ⏳ DocumentProvider
- ⏳ AuthProvider (for login API)

Each will follow the same pattern:
1. Load from API
2. Fall back to local cache
3. Save to both API and cache

## Quick Test Commands

```bash
# Test backend health
curl http://localhost:3001/api/health

# Check users in database
psql -d staff4dshire -c "SELECT email, first_name, last_name FROM users ORDER BY created_at DESC LIMIT 5;"

# Check backend logs
# (watch the terminal where backend is running)
```

## What's Changed

### UserProvider Now:
- ✅ Syncs with API on initialization
- ✅ Creates users via API (saves to PostgreSQL)
- ✅ Updates users via API
- ✅ Deletes users via API
- ✅ Falls back to local storage if API unavailable
- ✅ Caches data locally for offline access

### Files Modified:
- `mobile/lib/core/providers/user_provider.dart` - Updated to use API
- `mobile/lib/core/services/user_api_service.dart` - Created API service
- `mobile/lib/core/config/api_config.dart` - Platform detection

---

**Ready to test!** Start the mobile app and watch the logs to see API sync in action. 🚀


