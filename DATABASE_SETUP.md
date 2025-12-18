# Database Setup Guide

## Overview

This guide will help you set up the backend database and API server so that all your data persists correctly in PostgreSQL instead of just local storage.

## Prerequisites

- Node.js (v18 or higher)
- PostgreSQL (v14 or higher)
- npm or yarn

## Step 1: Install Backend Dependencies

```bash
cd backend
npm install
```

## Step 2: Configure Database Connection

1. Create a `.env` file in the `backend` directory:

```bash
cd backend
cp .env.example .env
```

2. Edit the `.env` file with your PostgreSQL credentials:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=staff4dshire
DB_USER=postgres
DB_PASSWORD=your_password_here

PORT=3001
NODE_ENV=development
```

## Step 3: Create PostgreSQL Database

```bash
# Create the database
createdb staff4dshire

# Or if you need to specify user:
createdb -U postgres staff4dshire
```

## Step 4: Run Database Schema

```bash
# Run the schema to create all tables
psql -d staff4dshire -f backend/schema.sql

# Or if you need to specify user:
psql -U postgres -d staff4dshire -f backend/schema.sql
```

## Step 5: Start Backend Server

```bash
cd backend
npm start
```

Or for development with auto-reload:

```bash
npm run dev
```

The server should start on `http://localhost:3001`

Test it by visiting: `http://localhost:3001/api/health`

## Step 6: Configure Flutter App

1. Update the API URL in `mobile/lib/core/config/api_config.dart`:

   - **For Web (localhost)**: `http://localhost:3001/api` (default)
   - **For Android Emulator**: `http://10.0.2.2:3001/api`
   - **For iOS Simulator**: `http://localhost:3001/api`
   - **For Physical Device**: `http://YOUR_COMPUTER_IP:3001/api`
     - Find your IP: Windows (`ipconfig`), Mac/Linux (`ifconfig` or `ip addr`)
     - Example: `http://192.168.1.100:3001/api`

2. Make sure the API is enabled in `api_config.dart`:
   ```dart
   static bool get isApiEnabled => true;
   ```

## Step 7: Test the Connection

1. Start your Flutter app
2. Create a new project
3. Check the backend console for API calls
4. Check the database:
   ```sql
   SELECT * FROM projects;
   SELECT * FROM users;
   ```

## Troubleshooting

### Database Connection Failed

- Check PostgreSQL is running: `pg_isready`
- Verify credentials in `.env` file
- Check firewall settings

### API Not Responding

- Verify server is running: `curl http://localhost:3001/api/health`
- Check CORS settings (should be enabled in `server.js`)
- Check port 3001 is not in use

### Flutter App Can't Connect to API

- **Web**: Use `http://localhost:3001/api`
- **Android Emulator**: Use `http://10.0.2.2:3001/api`
- **Physical Device**: Use your computer's IP address (not localhost)
- Make sure backend server is running
- Check network/firewall settings

### Data Still Not Persisting

1. Verify API is enabled: Check `ApiConfig.isApiEnabled` is `true`
2. Check browser console (web) or logs (mobile) for API errors
3. Verify database connection is working
4. Check that schema was run successfully

## Migration from Local Storage

When you first connect to the API:
- Existing local data will be loaded first
- New data will be saved to the database
- Old data in SharedPreferences will remain as backup
- You may want to manually migrate important projects/users to the database initially

## Next Steps

Once everything is working:
1. All new projects, users, and timesheets will be saved to PostgreSQL
2. Data will persist across app restarts and server restarts
3. Multiple devices can access the same data (if on same network or deployed)

