# Data Persistence Diagnosis

## Problem
Data created while the server is running disappears after server restart. Only hardcoded data remains.

## Root Cause
The mobile app providers are silently falling back to local storage (SharedPreferences) when API calls fail. This means:
- Data is saved locally on the device, but NOT in the PostgreSQL database
- When the server restarts, the database is empty (except for hardcoded data that gets re-inserted)
- The mobile app then loads from local storage, but this doesn't persist across devices or after clearing app data

## Solution
1. **Ensure API calls succeed** - Fix any connection/authentication issues
2. **Make API calls mandatory** - Don't silently fall back to local storage
3. **Load from database first** - Always load from API/database on startup
4. **Better error logging** - Show errors when API calls fail

## How to Verify
Run these commands to check if data is actually in the database:

```bash
# Check users
psql -U staff4dshire -d staff4dshire -c "SELECT id, email, first_name, last_name, created_at FROM users;"

# Check projects
psql -U staff4dshire -d staff4dshire -c "SELECT id, name, type, created_at FROM projects;"

# Check time entries
psql -U staff4dshire -d staff4dshire -c "SELECT id, user_id, project_id, sign_in_time FROM time_entries;"
```

If these queries return empty or only have hardcoded data, then data is NOT being saved to the database.


