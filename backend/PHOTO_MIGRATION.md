# Photo Migration Guide

## Issue
Some existing users have photo URLs in the format `pref:profile_photo_{userId}` but their photos are stored in SharedPreferences (device-specific storage). This means:
- Photos created on Device A won't be available on Device B
- Photos are lost if SharedPreferences is cleared
- Photos don't persist across server restarts

## Solution Implemented
Photos are now stored as base64 data URLs (`data:image/jpeg;base64,{data}`) directly in the database's `photo_url` column. This ensures:
- ✅ Photos persist across devices
- ✅ Photos survive server restarts
- ✅ Photos are accessible from any device/browser

## For Existing Users

### Option 1: Re-upload Photo (Recommended)
1. Admin logs in
2. Goes to User Management
3. Edits the user
4. Uploads a new photo
5. Photo will be saved as base64 in the database

### Option 2: Manual Migration (If photo exists on another device)
If the photo still exists in SharedPreferences on another device:
1. The sync service will automatically migrate it to the database on next login
2. Once migrated, the photo URL will change from `pref:...` to `data:image/...`

## Database Schema Update
The `photo_url` column has been changed from `VARCHAR(500)` to `TEXT` to accommodate base64 image data.

To apply this change, run:
```sql
ALTER TABLE users ALTER COLUMN photo_url TYPE TEXT;
```

## For New Users
All newly created users will automatically have their photos stored as base64 in the database, ensuring persistence across all devices and server restarts.

