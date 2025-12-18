# User Creation Fix - Password Issue

## Problem
When creating a user in the mobile app, the user was not being saved to the database. The database count shows 0 users even after creation.

## Root Cause
The backend API endpoint `/api/users` (POST) requires a `password_hash` field (see `backend/routes/users.js` line 65), but the mobile app was not sending this field when creating users.

## Fixes Applied

### 1. `AddEditUserScreen` (`mobile/lib/features/users/screens/add_edit_user_screen.dart`)
- Now returns both the user object AND the password when creating a new user
- Changed return type from `UserModel` to `Map<String, dynamic>` with keys:
  - `'user'`: The `UserModel` object
  - `'password'`: The plain text password (for new users only)

### 2. `UserProvider.addUser()` (`mobile/lib/core/providers/user_provider.dart`)
- Added optional `password` parameter
- Now passes the password to `UserApiService.createUser()` as `passwordHash`
- Improved error handling to show actual error messages

### 3. `UserManagementScreen` (`mobile/lib/features/users/screens/user_management_screen.dart`)
- Updated to handle the new return type from `AddEditUserScreen`
- Extracts both user and password from the result
- Passes password to `addUser()` method
- Added error handling to show failure messages to user

## Important Note: Password Hashing

**Current Implementation**: The password is being sent as plain text in the `password_hash` field. 

**Security Issue**: In production, passwords MUST be hashed before sending to the backend. The backend should:
1. Either hash the password on the backend side (preferred), OR
2. Accept a `password` field and hash it server-side

**Recommended Backend Fix**: Update `backend/routes/users.js` to:
- Accept a `password` field instead of `password_hash`
- Hash the password on the backend using bcrypt or similar
- Store the hash in the `password_hash` column

## Testing

1. **Try creating a user again** in the mobile app
2. **Check the database**:
   ```bash
   psql -U staff4dshire -d staff4dshire -c "SELECT id, email, first_name, last_name, created_at FROM users;"
   ```
3. **Check backend server logs** for any errors

## If Users Still Don't Save

Check for these error messages:
- `❌ CRITICAL: Failed to create user in database`
- `Missing required fields` (means password_hash is still missing)
- Database connection errors

Look in:
- Mobile app console/debug logs
- Backend server console output

## Next Steps

1. ✅ Fixed password passing from UI to API
2. ⏳ Implement proper password hashing (backend should hash)
3. ⏳ Test user creation end-to-end
4. ⏳ Verify users persist after server restart


