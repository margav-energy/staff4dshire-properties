# 🚀 Getting Started - Deploy to Render

This guide will walk you through deploying your Staff4dshire Properties app to Render so you can show it to stakeholders.

## ⏱️ Time Required: ~20 minutes

---

## 📋 Prerequisites Checklist

Before you start, make sure you have:
- ✅ GitHub account with your code pushed (✅ Already done!)
- ✅ Render account (we'll create this)
- ✅ About 20 minutes of time

---

## 🎯 Step-by-Step Deployment

### Step 1: Create Render Account (2 minutes)

1. Go to [render.com](https://render.com)
2. Click **"Get Started for Free"**
3. Sign up with your **GitHub account** (recommended)
4. Authorize Render to access your GitHub repositories

---

### Step 2: Deploy PostgreSQL Database (3 minutes)

1. In Render Dashboard, click **"New +"** → **"PostgreSQL"**
2. Fill in the details:
   - **Name**: `staff4dshire-db`
   - **Database**: `staff4dshire`
   - **User**: `staff4dshire`
   - **Region**: Choose closest to you (e.g., `Oregon`)
   - **Plan**: **Free** (for demo) or **Starter** ($7/month)
3. Click **"Create Database"**
4. **Wait 1-2 minutes** for database to be ready
5. ✅ **Important**: Copy the **Internal Database URL** (you'll see it in the database dashboard)

---

### Step 3: Deploy Backend API (5 minutes)

#### Option A: Using Blueprint (Easiest - Recommended)

1. In Render Dashboard, click **"New +"** → **"Blueprint"**
2. Connect your GitHub account if not already connected
3. Select your repository: **`Staff4dshire Properties`** (or your repo name)
4. Render will automatically detect the `render.yaml` file
5. Review the configuration:
   - It will create the backend service
   - It will link to your database
   - It will set `SEED_DATABASE=true` (creates default users automatically)
6. Click **"Apply"** to create all services
7. **Wait 5-10 minutes** for deployment

#### Option B: Manual Setup

1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub repository
3. Configure:
   - **Name**: `staff4dshire-backend`
   - **Environment**: `Node`
   - **Region**: Same as database
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
4. **Add Environment Variables**:
   - Click "Environment" tab
   - Add:
     - `NODE_ENV` = `production`
     - `PORT` = `10000`
     - `SEED_DATABASE` = `true`
5. **Link Database**:
   - Scroll to "Add Environment Variable"
   - Click "Link Database"
   - Select `staff4dshire-db`
   - Render automatically adds: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
6. Click **"Create Web Service"**
7. **Wait 5-10 minutes** for deployment

---

### Step 4: Initialize Database Schema (3 minutes)

Since you're on the free tier and can't use the shell, the database will be initialized automatically when the backend starts. However, you need to run the schema manually.

**Option 1: Using Render's Database Dashboard (Easiest)**

1. Go to your database in Render Dashboard
2. Click on the database name
3. Look for **"Connect"** or **"Info"** tab
4. Copy the **External Connection String** (looks like: `postgresql://user:pass@host:port/dbname`)
5. Use a PostgreSQL client (like pgAdmin, DBeaver, or command line) to connect
6. Run the schema:
   ```sql
   -- Copy and paste the contents of backend/schema.sql
   -- Then run it
   ```

**Option 2: Using psql Command Line**

1. Install PostgreSQL client locally (if not installed)
2. Get External Connection String from Render database dashboard
3. Run:
   ```bash
   psql "postgresql://staff4dshire:password@hostname:5432/staff4dshire" -f backend/schema.sql
   ```

**Option 3: Wait for Auto-Seeding (Simplest)**

The backend will attempt to create users automatically. If the schema isn't run yet, you'll see errors in the logs. In that case, use Option 1 or 2 above.

---

### Step 5: Verify Backend is Working (1 minute)

1. Go to your backend service in Render Dashboard
2. Click on the service name
3. You'll see a URL like: `https://staff4dshire-backend.onrender.com`
4. Test it: Visit `https://your-backend-url.onrender.com/api/health`
5. Should see: `{"status":"ok","message":"Staff4dshire API is running"}`

**Check Logs:**
- Click "Logs" tab in your backend service
- Look for: `✅ Database seeding completed successfully!`
- You should see the default login credentials printed

---

### Step 6: Update CORS Settings (2 minutes)

1. Go to your backend service → "Environment" tab
2. Add new environment variable:
   - **Key**: `ALLOWED_ORIGINS`
   - **Value**: `https://staff4dshire-admin.onrender.com,https://staff4dshire-staff.onrender.com`
   - (We'll update this with actual URLs after deploying the apps)
3. Click "Save Changes"
4. Backend will automatically redeploy

---

### Step 7: Deploy Admin App (5 minutes)

**Important**: Render's build environment doesn't have Flutter, so we need to build locally first.

1. **Build Admin App Locally:**
   ```bash
   cd apps/admin_app
   flutter clean
   flutter pub get
   flutter build web --release
   ```

2. **Update API URL** (if needed):
   - Edit `packages/shared/lib/core/config/api_config.dart`
   - Update line 18 with your backend URL:
     ```dart
     static const String _productionUrl = 'https://your-backend-url.onrender.com/api';
     ```
   - Rebuild: `flutter build web --release`

3. **Commit Build Files:**
   ```bash
   git add apps/admin_app/build/web
   git commit -m "Add admin app web build"
   git push
   ```

4. **Deploy on Render:**
   - Render Dashboard → "New +" → "Static Site"
   - Connect GitHub repository
   - Configure:
     - **Name**: `staff4dshire-admin`
     - **Branch**: `main`
     - **Root Directory**: `apps/admin_app`
     - **Build Command**: `echo "Using pre-built files"`
     - **Publish Directory**: `apps/admin_app/build/web`
   - Click "Create Static Site"
   - **Wait 5-10 minutes** for deployment

---

### Step 8: Deploy Staff App (5 minutes)

Repeat the same process for the staff app:

1. **Build Staff App Locally:**
   ```bash
   cd apps/staff_app
   flutter clean
   flutter pub get
   flutter build web --release
   ```

2. **Commit Build Files:**
   ```bash
   git add apps/staff_app/build/web
   git commit -m "Add staff app web build"
   git push
   ```

3. **Deploy on Render:**
   - "New +" → "Static Site"
   - **Name**: `staff4dshire-staff`
   - **Root Directory**: `apps/staff_app`
   - **Build Command**: `echo "Using pre-built files"`
   - **Publish Directory**: `apps/staff_app/build/web`
   - Click "Create Static Site"

---

### Step 9: Update CORS with Actual URLs (1 minute)

1. Once both apps are deployed, get their URLs:
   - Admin: `https://staff4dshire-admin.onrender.com`
   - Staff: `https://staff4dshire-staff.onrender.com`

2. Go to backend service → "Environment" tab
3. Update `ALLOWED_ORIGINS`:
   - **Value**: `https://staff4dshire-admin.onrender.com,https://staff4dshire-staff.onrender.com`
4. Save (auto-redeploys)

---

### Step 10: Test Everything! (2 minutes)

1. **Test Backend:**
   - Visit: `https://your-backend.onrender.com/api/health`
   - Should return: `{"status":"ok",...}`

2. **Test Admin App:**
   - Visit: `https://your-admin.onrender.com`
   - Login with: `admin@staff4dshire.com` / `Admin123!`

3. **Test Staff App:**
   - Visit: `https://your-staff.onrender.com`
   - Login with: `staff@staff4dshire.com` / `Staff123!`

---

## 🎉 You're Done!

Your app is now live! Share these URLs with stakeholders:

- **Admin App**: `https://staff4dshire-admin.onrender.com`
- **Staff App**: `https://staff4dshire-staff.onrender.com`

---

## 🔑 Default Login Credentials

All users are created automatically! See `STAKEHOLDER_DEMO_CREDENTIALS.md` for the complete list.

**Quick Login:**
- **Admin**: `admin@staff4dshire.com` / `Admin123!`
- **Staff**: `staff@staff4dshire.com` / `Staff123!`
- **Supervisor**: `supervisor@staff4dshire.com` / `Supervisor123!`
- **Superadmin**: `superadmin@staff4dshire.com` / `Admin123!`

---

## 📚 Additional Resources

- **Detailed Guide**: See `RENDER_DEPLOYMENT_GUIDE.md`
- **Quick Reference**: See `QUICK_DEPLOY_TO_RENDER.md`
- **Flutter Web Build**: See `DEPLOY_FLUTTER_WEB.md`
- **Stakeholder Guide**: See `STAKEHOLDER_DEMO_CREDENTIALS.md`

---

## 🐛 Troubleshooting

### Backend won't start
- Check logs in Render Dashboard
- Verify database is linked correctly
- Check environment variables are set

### Can't log in
- Verify backend is running (check `/api/health`)
- Check API URL in `api_config.dart` matches your backend URL
- Check CORS settings include your app URLs

### Database errors
- Make sure schema.sql has been run
- Check database connection in backend logs
- Verify environment variables are correct

### Flutter build fails
- Make sure you built locally first
- Check that `build/web` folder exists
- Verify you committed the build files

### CORS errors
- Update `ALLOWED_ORIGINS` with your actual app URLs
- Make sure URLs match exactly (including https://)
- Redeploy backend after updating CORS

---

## 💡 Pro Tips

1. **Free Tier Note**: Services spin down after 15 min of inactivity. First request takes ~30 seconds.

2. **Updating Code**: Just push to GitHub, Render auto-deploys!

3. **Viewing Logs**: Always check logs first when troubleshooting.

4. **Database Backups**: Free tier doesn't include backups. Consider upgrading for production.

5. **Custom Domain**: You can add your own domain in Render settings.

---

## 🆘 Need Help?

- Check the detailed guides in the `docs/` folder
- Review Render's documentation: [render.com/docs](https://render.com/docs)
- Check backend logs for error messages

---

**Good luck with your deployment! 🚀**
