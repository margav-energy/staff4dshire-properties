# Render Deployment Guide

This guide will help you deploy the Staff4dshire Properties application to Render for stakeholder demonstration.

## 📋 Prerequisites

1. **GitHub Account** - Your code should be pushed to GitHub
2. **Render Account** - Sign up at [render.com](https://render.com) (free tier available)
3. **Domain (Optional)** - You can use Render's free subdomain or connect your own domain

## 🗄️ Step 1: Deploy PostgreSQL Database

1. **Log in to Render Dashboard**
   - Go to [dashboard.render.com](https://dashboard.render.com)
   - Sign up or log in

2. **Create PostgreSQL Database**
   - Click "New +" → "PostgreSQL"
   - Configure:
     - **Name**: `staff4dshire-db`
     - **Database**: `staff4dshire`
     - **User**: `staff4dshire`
     - **Region**: Choose closest to your users (e.g., Oregon)
     - **Plan**: Free (for demo) or Starter ($7/month)
   - Click "Create Database"
   - **Wait for database to be ready** (takes 1-2 minutes)

3. **Get Database Connection String**
   - Once created, click on the database
   - Copy the **Internal Database URL** (you'll need this later)
   - Note: Render provides connection details automatically via environment variables

## 🚀 Step 2: Deploy Backend API

### Option A: Using render.yaml (Recommended)

1. **Connect GitHub Repository**
   - In Render Dashboard, click "New +" → "Blueprint"
   - Connect your GitHub account
   - Select your repository: `Staff4dshire Properties`
   - Render will detect the `render.yaml` file

2. **Review Configuration**
   - Render will show the services to be created
   - The backend service will automatically:
     - Link to the database
     - Set up environment variables
     - Configure build and start commands

3. **Deploy**
   - Click "Apply" to create all services
   - Wait for deployment (5-10 minutes)

### Option B: Manual Setup

1. **Create Web Service**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Configure:
     - **Name**: `staff4dshire-backend`
     - **Environment**: `Node`
     - **Region**: Same as database
     - **Branch**: `main` (or your default branch)
     - **Root Directory**: `backend`
     - **Build Command**: `npm install`
     - **Start Command**: `npm start`

2. **Add Environment Variables**
   - Scroll to "Environment Variables"
   - Add the following:
     ```
     NODE_ENV=production
     PORT=10000
     ```
   - **Link Database**:
     - Click "Link Database" or "Add Environment Variable"
     - Select `staff4dshire-db`
     - Render will automatically add:
       - `DB_HOST`
       - `DB_PORT`
       - `DB_NAME`
       - `DB_USER`
       - `DB_PASSWORD`

3. **Deploy**
   - Click "Create Web Service"
   - Wait for first deployment (5-10 minutes)

## 📊 Step 3: Initialize Database Schema

1. **Get Database Connection Info**
   - Go to your database in Render Dashboard
   - Copy the **External Connection String** (for local access)
   - Or use the Internal Database URL from environment variables

2. **Run Schema Migration**
   
   **Option A: Using Render Shell (Recommended)**
   - Go to your backend service
   - Click "Shell" tab
   - Run:
     ```bash
     cd backend
     psql $DATABASE_URL -f schema.sql
     ```
   
   **Option B: Using Local psql**
   - Install PostgreSQL client locally
   - Use the External Connection String from Render
   - Run:
     ```bash
     psql "postgresql://staff4dshire:password@hostname:5432/staff4dshire" -f backend/schema.sql
     ```

3. **Run Migrations (if any)**
   - In Render Shell or locally:
     ```bash
     cd backend
     node migrations/add_chat_tables.js
     node migrations/add_message_read_status.js
     # ... run other migrations as needed
     ```

## 🌐 Step 4: Deploy Flutter Web Apps

### Deploy Admin App

1. **Build Flutter Web App**
   ```bash
   cd apps/admin_app
   flutter build web --release
   ```
   This creates a `build/web` directory with static files.

2. **Create Static Site on Render**
   - In Render Dashboard, click "New +" → "Static Site"
   - Connect your GitHub repository
   - Configure:
     - **Name**: `staff4dshire-admin`
     - **Branch**: `main`
     - **Root Directory**: `apps/admin_app`
     - **Build Command**: `cd apps/admin_app && flutter build web --release`
     - **Publish Directory**: `apps/admin_app/build/web`

3. **Add Environment Variables** (if needed)
   - The app will use production API URL from `api_config.dart`
   - Update `packages/shared/lib/core/config/api_config.dart`:
     ```dart
     static const String _productionUrl = 'https://your-backend-url.onrender.com/api';
     ```

4. **Deploy**
   - Click "Create Static Site"
   - Wait for build and deployment

### Deploy Staff App

Repeat the same process for the staff app:

1. **Build Flutter Web App**
   ```bash
   cd apps/staff_app
   flutter build web --release
   ```

2. **Create Static Site**
   - Name: `staff4dshire-staff`
   - Root Directory: `apps/staff_app`
   - Build Command: `cd apps/staff_app && flutter build web --release`
   - Publish Directory: `apps/staff_app/build/web`

## 🔧 Step 5: Update API Configuration

After deploying, update the API URLs in your Flutter apps:

1. **Update API Config**
   - Edit `packages/shared/lib/core/config/api_config.dart`
   - Update `_productionUrl` with your Render backend URL:
     ```dart
     static const String _productionUrl = 'https://staff4dshire-backend.onrender.com/api';
     ```

2. **Rebuild and Redeploy**
   - Rebuild both Flutter apps
   - Push changes to GitHub
   - Render will automatically redeploy

## 🔒 Step 6: Update CORS Settings (Important!)

1. **Update Backend CORS**
   - Edit `backend/server.js`
   - Update CORS origin to your Flutter web app URLs:
     ```javascript
     const cors = require('cors');
     
     const corsOptions = {
       origin: [
         'https://staff4dshire-admin.onrender.com',
         'https://staff4dshire-staff.onrender.com',
         // Add your actual Render URLs here
       ],
       credentials: true,
       methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
     };
     
     app.use(cors(corsOptions));
     
     // Socket.io CORS
     const io = new Server(server, {
       cors: {
         origin: [
           'https://staff4dshire-admin.onrender.com',
           'https://staff4dshire-staff.onrender.com',
         ],
         methods: ['GET', 'POST'],
         credentials: true
       }
     });
     ```

2. **Commit and Push**
   - Commit the changes
   - Push to GitHub
   - Render will automatically redeploy

## ✅ Step 7: Verify Deployment

1. **Test Backend API**
   - Visit: `https://your-backend-url.onrender.com/api/health`
   - Should return: `{"status":"ok","message":"Staff4dshire API is running"}`

2. **Test Admin App**
   - Visit your admin app URL
   - Try logging in (create a test user first via API or database)

3. **Test Staff App**
   - Visit your staff app URL
   - Verify it connects to the backend

## 🎯 Step 8: Create Test Data

1. **Create Superadmin User**
   - Use the backend API or database directly
   - Or run: `node backend/create_superadmin.js` (if you have access)

2. **Create Test Company**
   - Log in to admin app
   - Create a test company

3. **Create Test Users**
   - Create admin, supervisor, and staff users
   - Test different roles

## 📝 Environment Variables Summary

### Backend Service
- `NODE_ENV=production`
- `PORT=10000` (Render default)
- `DB_HOST` (auto from database)
- `DB_PORT` (auto from database)
- `DB_NAME` (auto from database)
- `DB_USER` (auto from database)
- `DB_PASSWORD` (auto from database)

### Optional (for email features)
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASSWORD`
- `SMTP_FROM`
- `APP_BASE_URL`

## 🔗 URLs After Deployment

- **Backend API**: `https://staff4dshire-backend.onrender.com`
- **Admin App**: `https://staff4dshire-admin.onrender.com`
- **Staff App**: `https://staff4dshire-staff.onrender.com`

## 💰 Pricing (Free Tier)

- **PostgreSQL**: 90 days free, then $7/month
- **Web Service**: Free (with limitations), or $7/month for Starter
- **Static Sites**: Free (unlimited)

## 🐛 Troubleshooting

### Database Connection Issues
- Verify environment variables are set correctly
- Check database is running and accessible
- Ensure schema has been run

### CORS Errors
- Update CORS settings in `backend/server.js`
- Add your Flutter web app URLs to allowed origins
- Redeploy backend

### Build Failures
- Check build logs in Render Dashboard
- Verify all dependencies are in `package.json`
- Ensure Flutter is available in build environment (may need custom Dockerfile)

### API Not Responding
- Check service logs in Render Dashboard
- Verify PORT environment variable is set to 10000
- Check health endpoint: `/api/health`

## 📚 Next Steps

1. **Set up Custom Domain** (optional)
   - Add your domain in Render
   - Update DNS records

2. **Enable HTTPS** (automatic on Render)
   - Render provides free SSL certificates

3. **Set up Monitoring**
   - Use Render's built-in monitoring
   - Set up alerts for downtime

4. **Backup Database**
   - Render provides automatic backups on paid plans
   - Consider manual backups for free tier

## 🎉 You're Done!

Your application is now live on Render and ready to show stakeholders!

## 🔑 Default Login Credentials

**Default users are automatically created when `SEED_DATABASE=true`** (already set in render.yaml).

See `DEFAULT_LOGIN_CREDENTIALS.md` for the complete list, or use these quick credentials:

- **Admin**: `admin@staff4dshire.com` / `Admin123!`
- **Staff**: `staff@staff4dshire.com` / `Staff123!`
- **Supervisor**: `supervisor@staff4dshire.com` / `Supervisor123!`
- **Superadmin**: `superadmin@staff4dshire.com` / `Admin123!`

⚠️ **Security Note**: Change these passwords immediately in production!

**Quick Links:**
- Render Dashboard: https://dashboard.render.com
- Render Docs: https://render.com/docs
