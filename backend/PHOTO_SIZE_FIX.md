# Photo Upload Size Fix

## Issue
When creating or editing users with photos, the request was failing with:
```
500 - {"error":"Internal server error","message":"request entity too large"}
```

This was because base64-encoded images exceed Express.js's default body size limit (100KB).

## Solution Applied

### 1. Server Configuration (backend/server.js)
Increased Express body size limit to handle base64 images:
```javascript
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
```

### 2. Client-Side Image Compression (mobile/lib/features/users/screens/add_edit_user_screen.dart)
Reduced image size before upload:
- **Max dimensions**: Changed from 800x800px to 512x512px
- **Image quality**: Reduced from 85% to 70%
- **Size limit check**: Updated to 1.5MB (was 1MB)

## Action Required

**You must restart the backend server** for the changes to take effect:

```bash
# Stop the current server (Ctrl+C)
# Then restart it:
cd backend
node server.js
```

## Expected Results

After restarting:
- ✅ Photos up to 512x512px @ 70% quality will upload successfully
- ✅ Base64 images up to ~1.5MB will be accepted by the server
- ✅ Photos will be stored in the database as base64 data URLs
- ✅ Photos will persist across devices and server restarts

## Technical Notes

- Base64 encoding increases file size by approximately 33%
- A 512x512px JPEG at 70% quality typically results in ~100-200KB base64 string
- The server limit of 50MB provides plenty of headroom for future needs
- Client-side compression ensures efficient use of bandwidth and storage

