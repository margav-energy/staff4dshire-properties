# 🚨 Fix: CORS Error - Can't Login or Create Requests

## Problem
After going live, you're getting "Failed to fetch" errors because the backend isn't allowing requests from your frontend URLs.

## ✅ Quick Fix: Add ALLOWED_ORIGINS to Backend

### Option 1: Update render.yaml (Recommended)

1. **Get your frontend URLs from Render:**
   - Admin App URL: `https://staff4dshire-admin.onrender.com` (or your actual URL)
   - Staff App URL: `https://staff4dshire-staff.onrender.com` (or your actual URL)

2. **Update render.yaml:**
   - Uncomment and update the ALLOWED_ORIGINS line:
   ```yaml
   - key: ALLOWED_ORIGINS
     value: https://staff4dshire-admin.onrender.com,https://staff4dshire-staff.onrender.com
   ```
   (Replace with your actual URLs)

3. **Commit and push:**
   ```bash
   git add render.yaml
   git commit -m "Add CORS configuration for frontend apps"
   git push origin main
   ```

4. **Render will auto-redeploy** (~2 minutes)

### Option 2: Add Manually in Render Dashboard (Faster)

1. **Go to Render Dashboard** → Your Backend Service
2. **Click "Environment" tab**
3. **Click "Add Environment Variable"**
4. **Add:**
   - **Key**: `ALLOWED_ORIGINS`
   - **Value**: `https://staff4dshire-admin.onrender.com,https://staff4dshire-staff.onrender.com`
   (Replace with your actual frontend URLs - comma-separated, no spaces)
5. **Click "Save Changes"**
6. **Render will automatically redeploy** (~1-2 minutes)

---

## 🔍 How to Find Your Frontend URLs

1. Go to Render Dashboard
2. Find your Admin App Static Site → Copy the URL
3. Find your Staff App Static Site → Copy the URL
4. Use both URLs in ALLOWED_ORIGINS (comma-separated)

---

## ✅ Verify It's Fixed

After redeploy:

1. **Check backend is running:**
   - Visit: `https://staff4dshire-backend.onrender.com/api/health`
   - Should return: `{"status":"ok",...}`

2. **Try logging in:**
   - Go to your frontend app
   - Try to login with: `admin@staff4dshire.com` / `Admin123!`
   - Should work without CORS errors

3. **Check browser console:**
   - Press F12 → Console tab
   - Should see no CORS errors

---

## 🐛 Still Not Working?

### Check Backend Logs

1. Go to Render Dashboard → Backend Service
2. Click "Logs" tab
3. Look for CORS errors or connection issues

### Verify Environment Variable

1. Go to Backend Service → Environment tab
2. Verify `ALLOWED_ORIGINS` is set correctly
3. Make sure URLs match exactly (including `https://`)
4. No spaces in the value

### Temporary Fix: Allow All Origins (For Testing Only)

If you need a quick test, you can temporarily modify the backend code to allow all origins:

**⚠️ WARNING: Only for testing! Not secure for production!**

In `backend/server.js`, change:
```javascript
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:8080', 'http://localhost:3000']; // Default for development
```

To:
```javascript
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',')
  : (process.env.NODE_ENV === 'production' ? ['*'] : ['http://localhost:8080', 'http://localhost:3000']);
```

But **better to set ALLOWED_ORIGINS properly** instead!

---

## 📝 Summary

**The Issue:** Backend is blocking requests because frontend URLs aren't in ALLOWED_ORIGINS.

**The Fix:** Add `ALLOWED_ORIGINS` environment variable with your frontend URLs.

**Time to Fix:** ~2 minutes (manual) or ~5 minutes (via render.yaml)
