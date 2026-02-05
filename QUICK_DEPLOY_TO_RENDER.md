# Quick Deploy to Render - Step by Step

## 🚀 Fast Track (15 minutes)

### 1. Push Code to GitHub
```bash
git add .
git commit -m "Prepare for Render deployment"
git push origin main
```

### 2. Create Render Account
- Go to [render.com](https://render.com)
- Sign up with GitHub (free)

### 3. Deploy Database (2 minutes)
- Dashboard → "New +" → "PostgreSQL"
- Name: `staff4dshire-db`
- Database: `staff4dshire`
- User: `staff4dshire`
- Plan: Free
- Click "Create Database"
- **Wait 1-2 minutes** for it to be ready

### 4. Deploy Backend (5 minutes)

**Option A: Using Blueprint (Easiest)**
- Dashboard → "New +" → "Blueprint"
- Connect GitHub repo
- Select your repository
- Render will detect `render.yaml`
- Click "Apply"
- **Wait 5-10 minutes** for deployment

**Option B: Manual**
- Dashboard → "New +" → "Web Service"
- Connect GitHub repo
- Settings:
  - Name: `staff4dshire-backend`
  - Environment: `Node`
  - Root Directory: `backend`
  - Build: `npm install`
  - Start: `npm start`
- Add Environment Variables:
  - `NODE_ENV` = `production`
  - `PORT` = `10000`
- Link Database: Select `staff4dshire-db`
- Click "Create Web Service"

### 5. Initialize Database (2 minutes)
- Go to backend service → "Shell" tab
- Run:
  ```bash
  cd backend
  psql $DATABASE_URL -f schema.sql
  ```
- Run migrations:
  ```bash
  node migrations/add_chat_tables.js
  node migrations/add_message_read_status.js
  ```

### 6. Update CORS (1 minute)
- Go to backend service → "Environment" tab
- Add variable:
  - Key: `ALLOWED_ORIGINS`
  - Value: `https://staff4dshire-admin.onrender.com,https://staff4dshire-staff.onrender.com`
  - (Update with your actual URLs after deploying apps)
- Save changes (auto-redeploys)

### 7. Deploy Admin App (3 minutes)
- Dashboard → "New +" → "Static Site"
- Connect GitHub repo
- Settings:
  - Name: `staff4dshire-admin`
  - Root Directory: `apps/admin_app`
  - Build: `cd apps/admin_app && flutter build web --release`
  - Publish: `apps/admin_app/build/web`
- Click "Create Static Site"
- **Wait 5-10 minutes** for build

### 8. Deploy Staff App (3 minutes)
- Same as Admin App:
  - Name: `staff4dshire-staff`
  - Root Directory: `apps/staff_app`
  - Build: `cd apps/staff_app && flutter build web --release`
  - Publish: `apps/staff_app/build/web`

### 9. Update API URLs (2 minutes)
- Edit `packages/shared/lib/core/config/api_config.dart`
- Update line 18:
  ```dart
  static const String _productionUrl = 'https://YOUR-BACKEND-URL.onrender.com/api';
  ```
- Commit and push:
  ```bash
  git add packages/shared/lib/core/config/api_config.dart
  git commit -m "Update API URL for production"
  git push
  ```
- Render will auto-redeploy both apps

### 10. Test! (1 minute)
- Backend: `https://your-backend.onrender.com/api/health`
- Admin: `https://your-admin.onrender.com`
- Staff: `https://your-staff.onrender.com`

### 11. Login with Default Credentials

**Default users are created automatically!** See `DEFAULT_LOGIN_CREDENTIALS.md` for details.

**Quick Login:**
- **Admin**: `admin@staff4dshire.com` / `Admin123!`
- **Staff**: `staff@staff4dshire.com` / `Staff123!`
- **Supervisor**: `supervisor@staff4dshire.com` / `Supervisor123!`
- **Superadmin**: `superadmin@staff4dshire.com` / `Admin123!`

## ✅ Done!

Your app is live! Share the URLs with stakeholders.

## 🔗 Your URLs
- Backend: `https://staff4dshire-backend.onrender.com`
- Admin: `https://staff4dshire-admin.onrender.com`
- Staff: `https://staff4dshire-staff.onrender.com`

## ⚠️ Important Notes

1. **Free Tier Limits:**
   - Services spin down after 15 minutes of inactivity
   - First request after spin-down takes ~30 seconds
   - Database: 90 days free, then $7/month

2. **Flutter Build Note:**
   - Render's build environment may not have Flutter installed
   - You may need to build locally and commit the `build/web` folder
   - Or use a custom Dockerfile (see Render docs)

3. **CORS:**
   - Update `ALLOWED_ORIGINS` with your actual app URLs
   - Add both admin and staff app URLs

## 🆘 Need Help?

See `RENDER_DEPLOYMENT_GUIDE.md` for detailed instructions.
