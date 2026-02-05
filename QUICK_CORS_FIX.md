# 🚨 Quick Fix: CORS Error - Can't Login

## The Problem
Your backend is blocking requests from your frontend apps because `ALLOWED_ORIGINS` isn't configured.

## ✅ Fastest Fix (2 minutes)

### Step 1: Get Your Frontend URLs

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Find your **Admin App Static Site** → Copy the URL (e.g., `https://staff4dshire-admin.onrender.com`)
3. Find your **Staff App Static Site** → Copy the URL (e.g., `https://staff4dshire-staff.onrender.com`)

### Step 2: Add to Backend Environment

1. Go to your **Backend Service** in Render Dashboard
2. Click **"Environment"** tab
3. Click **"Add Environment Variable"**
4. Add:
   - **Key**: `ALLOWED_ORIGINS`
   - **Value**: `https://your-admin-url.onrender.com,https://your-staff-url.onrender.com`
   - ⚠️ **Important**: Replace with your actual URLs, comma-separated, NO SPACES
5. Click **"Save Changes"**
6. Wait ~1-2 minutes for auto-redeploy

### Step 3: Test

1. Go to your frontend app
2. Try logging in: `admin@staff4dshire.com` / `Admin123!`
3. Should work now! ✅

---

## 🔍 Example

If your URLs are:
- Admin: `https://staff4dshire-admin.onrender.com`
- Staff: `https://staff4dshire-staff.onrender.com`

Then `ALLOWED_ORIGINS` value should be:
```
https://staff4dshire-admin.onrender.com,https://staff4dshire-staff.onrender.com
```

**No spaces after commas!**

---

## ✅ Verify It Works

1. **Check backend health:**
   - Visit: `https://staff4dshire-backend.onrender.com/api/health`
   - Should return JSON with `"status":"ok"`

2. **Try login:**
   - Should work without "Failed to fetch" errors

3. **Check browser console (F12):**
   - No CORS errors

---

## 🐛 Still Not Working?

- Make sure URLs match exactly (including `https://`)
- No spaces in the ALLOWED_ORIGINS value
- Wait 2 minutes after saving for redeploy
- Check backend logs in Render dashboard
