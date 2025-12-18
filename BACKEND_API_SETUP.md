# Backend API Integration Setup Guide

## Problem
The mobile app currently uses local storage (SharedPreferences) for all data, which means:
- Data is lost when the app is uninstalled or cache is cleared
- Data doesn't persist across devices
- Data is lost when the server restarts (if data was only in memory)

## Solution
Connect the mobile app to the PostgreSQL database through the backend API server.

## Prerequisites

1. **Backend server must be running**
   ```bash
   cd backend
   npm install
   npm start
   ```

2. **PostgreSQL database must be set up**
   ```bash
   # Create database
   createdb staff4dshire
   
   # Run schema
   psql -d staff4dshire -f backend/schema.sql
   ```

3. **Backend .env file configured**
   Create `backend/.env`:
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=staff4dshire
   DB_USER=staff4dshire
   DB_PASSWORD=your_password
   PORT=3001
   NODE_ENV=development
   ```

## API Configuration

The mobile app needs to know where the backend server is running.

### For Web (Chrome/Edge):
- Default: `http://localhost:3001/api`
- Works automatically

### For Android Emulator:
- Default: `http://10.0.2.2:3001/api`
- Works automatically

### For Physical Device or iOS Simulator:
You need to set the API URL manually:

**Option 1: Set environment variable when running:**
```bash
# Android
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:3001/api

# Example: If your computer IP is 192.168.1.100
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3001/api
```

**Option 2: Find your computer's IP address:**
- Windows: `ipconfig` (look for IPv4 Address)
- Mac/Linux: `ifconfig` or `ip addr`

**Option 3: Update API config directly** (temporary):
Edit `mobile/lib/core/config/api_config.dart` and change the default URL.

## Testing the Connection

1. **Check if backend is running:**
   ```bash
   curl http://localhost:3001/api/health
   ```
   Should return: `{"status":"ok","message":"Staff4dshire API is running"}`

2. **Test from mobile app:**
   - The app will try to connect to the API when loading data
   - Check the console/logs for connection errors
   - If offline, it will use cached data from SharedPreferences

## How It Works

1. **Offline-First Architecture:**
   - App loads cached data from local storage first (instant)
   - Then syncs with API in the background
   - If API is unavailable, continues using cached data

2. **Data Flow:**
   ```
   User Action → Mobile App → API Service → Backend Server → PostgreSQL
                      ↓
                 Local Cache (SharedPreferences)
   ```

3. **Provider Updates:**
   - Providers now sync with API when available
   - Data is saved to both API and local cache
   - Local cache serves as backup when offline

## Current Status

✅ **API Infrastructure:** Created
- `mobile/lib/core/services/api_service.dart` - HTTP client
- `mobile/lib/core/config/api_config.dart` - Configuration
- `mobile/lib/core/services/user_api_service.dart` - User API service

🔄 **In Progress:**
- Updating `UserProvider` to use API
- Will update other providers next (TimesheetProvider, ProjectProvider, etc.)

## Next Steps

1. **Start the backend server**
2. **Configure API URL** (if using physical device)
3. **Update providers** to use API service (this is being done now)
4. **Test data persistence** by:
   - Creating a user
   - Restarting the backend server
   - Verifying the user still exists

## Troubleshooting

### "Connection refused" error
- **Check:** Is the backend server running?
- **Check:** Is the API URL correct?
- **Check:** Firewall blocking port 3001?

### "Database connection error"
- **Check:** Is PostgreSQL running?
- **Check:** Is the database created?
- **Check:** Are .env credentials correct?

### Data not persisting
- **Check:** Are API calls succeeding? (check logs)
- **Check:** Is data being saved to database? (query PostgreSQL)
- **Check:** Is the provider using the API service?

## Migration from Local Storage

The app will automatically migrate:
1. Existing local data remains available
2. First API sync will merge local and server data
3. Server becomes source of truth after first sync


