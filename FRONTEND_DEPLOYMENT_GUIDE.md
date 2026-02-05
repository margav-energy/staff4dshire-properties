# 🚀 Frontend Deployment Guide - Quick Start

This guide will help you deploy both Flutter web apps (Admin and Staff) to Render.

## ⏱️ Time Required: ~15 minutes

---

## 📋 Prerequisites

- ✅ Flutter installed on your local machine
- ✅ Backend deployed and running at `https://staff4dshire-backend.onrender.com`
- ✅ Git repository pushed to GitHub

---

## 🎯 Step-by-Step Deployment

### Step 1: Update API Configuration (2 minutes)

The API config needs to point to your Render backend URL.

**File to update:** `packages/shared/lib/core/config/api_config.dart`

**Change this line:**
```dart
static const String _productionUrl = 'https://api.staff4dshire.com/api';
```

**To:**
```dart
static const String _productionUrl = 'https://staff4dshire-backend.onrender.com/api';
```

---

### Step 2: Build Admin App Locally (3 minutes)

1. **Open terminal in project root**

2. **Navigate to admin app:**
   ```bash
   cd apps/admin_app
   ```

3. **Clean and get dependencies:**
   ```bash
   flutter clean
   flutter pub get
   ```

4. **Build for web:**
   ```bash
   flutter build web --release
   ```

5. **Wait for build to complete** (may take 2-3 minutes)

---

### Step 3: Build Staff App Locally (3 minutes)

1. **Navigate to staff app:**
   ```bash
   cd ../staff_app
   ```

2. **Clean and get dependencies:**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Build for web:**
   ```bash
   flutter build web --release
   ```

4. **Wait for build to complete** (may take 2-3 minutes)

---

### Step 4: Commit Build Files (2 minutes)

1. **Go back to project root:**
   ```bash
   cd ../..
   ```

2. **Add build files (force add if needed):**
   ```bash
   git add -f apps/admin_app/build/web
   git add -f apps/staff_app/build/web
   ```

3. **Commit:**
   ```bash
   git commit -m "Add Flutter web builds for Render deployment"
   ```

4. **Push to GitHub:**
   ```bash
   git push origin main
   ```

---

### Step 5: Deploy Admin App to Render (3 minutes)

1. **Go to Render Dashboard** → [dashboard.render.com](https://dashboard.render.com)

2. **Click "New +" → "Static Site"**

3. **Connect your GitHub repository**

4. **Configure Admin App:**
   - **Name**: `staff4dshire-admin` (or your preferred name)
   - **Branch**: `main`
   - **Root Directory**: `apps/admin_app`
   - **Build Command**: `echo "Using pre-built files"` (or leave empty)
   - **Publish Directory**: `apps/admin_app/build/web`

5. **Click "Create Static Site"**

6. **Wait for deployment** (~2 minutes)

7. **Note your Admin App URL** (e.g., `https://staff4dshire-admin.onrender.com`)

---

### Step 6: Deploy Staff App to Render (3 minutes)

1. **In Render Dashboard, click "New +" → "Static Site"**

2. **Connect your GitHub repository** (same repo)

3. **Configure Staff App:**
   - **Name**: `staff4dshire-staff` (or your preferred name)
   - **Branch**: `main`
   - **Root Directory**: `apps/staff_app`
   - **Build Command**: `echo "Using pre-built files"` (or leave empty)
   - **Publish Directory**: `apps/staff_app/build/web`

4. **Click "Create Static Site"**

5. **Wait for deployment** (~2 minutes)

6. **Note your Staff App URL** (e.g., `https://staff4dshire-staff.onrender.com`)

---

### Step 7: Update CORS Settings (2 minutes)

Your backend needs to allow requests from your frontend URLs.

1. **Go to your Backend service in Render Dashboard**

2. **Click "Environment" tab**

3. **Add/Update environment variable:**
   - **Key**: `ALLOWED_ORIGINS`
   - **Value**: `https://staff4dshire-admin.onrender.com,https://staff4dshire-staff.onrender.com`
   (Replace with your actual URLs)

4. **Click "Save Changes"**

5. **Render will automatically redeploy** (~1 minute)

---

## ✅ Verification Checklist

After deployment, test:

- [ ] **Admin App loads** at your Render URL
- [ ] **Staff App loads** at your Render URL
- [ ] **Login works** in both apps
- [ ] **No CORS errors** in browser console (F12 → Console)
- [ ] **API calls work** (try logging in with default credentials)

---

## 🔑 Default Login Credentials

Use these to test after deployment:

**Admin App:**
- Email: `admin@staff4dshire.com`
- Password: `Admin123!`

**Staff App:**
- Email: `staff@staff4dshire.com`
- Password: `Staff123!`

See `DEFAULT_LOGIN_CREDENTIALS.md` for all accounts.

---

## 🔄 Updating After Code Changes

When you make changes to the Flutter apps:

1. **Update code** in `apps/admin_app` or `apps/staff_app`

2. **Rebuild locally:**
   ```bash
   cd apps/admin_app
   flutter build web --release
   # or
   cd apps/staff_app
   flutter build web --release
   ```

3. **Commit and push:**
   ```bash
   git add apps/*/build/web
   git commit -m "Update Flutter web builds"
   git push origin main
   ```

4. **Render will auto-redeploy** (~2 minutes)

---

## 🐛 Troubleshooting

### Build fails locally
- Make sure Flutter is installed: `flutter doctor`
- Make sure you're in the correct directory
- Try `flutter clean` then rebuild

### Apps don't load on Render
- Check that `Publish Directory` is correct: `apps/admin_app/build/web`
- Check Render logs for errors
- Make sure build files were committed to GitHub

### CORS errors in browser
- Verify `ALLOWED_ORIGINS` environment variable in backend
- Make sure URLs match exactly (including https://)
- Check browser console for specific error messages

### Login doesn't work
- Check that backend is running: `https://staff4dshire-backend.onrender.com/api/health`
- Verify API URL in `api_config.dart` matches your backend URL
- Check browser console for API errors

---

## 📝 Quick Command Reference

```bash
# Build both apps
cd apps/admin_app && flutter build web --release
cd ../staff_app && flutter build web --release

# Commit builds
git add -f apps/*/build/web
git commit -m "Update web builds"
git push origin main
```

---

## 🎉 You're Done!

Your frontend apps are now live and ready to show stakeholders!

**Admin App**: `https://staff4dshire-admin.onrender.com`  
**Staff App**: `https://staff4dshire-staff.onrender.com`
