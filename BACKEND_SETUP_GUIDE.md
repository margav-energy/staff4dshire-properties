# Backend Setup Guide

## ✅ What I Just Created

1. **Created `/backend/routes/auth.js`** - Authentication routes for login
2. **Updated `/backend/server.js`** - Added auth routes

## 🔧 Next Steps

### Step 1: Make Sure Backend Server is Running

```bash
cd backend
npm install  # Make sure bcrypt is installed
node server.js
```

Or if you have nodemon:
```bash
npm start
```

The server should start on port 3001 (or whatever PORT is set in `.env`).

### Step 2: Create a Test User

You need at least one user in the database to login. You can:

**Option A: Use the superadmin creation script**
```bash
cd backend
node create_superadmin.js
```

**Option B: Create user via SQL**
```sql
-- Insert a test admin user (password will be 'password123' - hashed)
INSERT INTO users (id, email, password_hash, first_name, last_name, role, is_active, company_id)
VALUES (
  uuid_generate_v4(),
  'admin@test.com',
  '$2b$10$rQ7K8v...' -- bcrypt hash of 'password123'
  'Admin',
  'User',
  'admin',
  TRUE,
  (SELECT id FROM companies LIMIT 1) -- Use first company
);
```

**Option C: Create user via the registration screen** (if it's working)

### Step 3: Test the API

Test the login endpoint:
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"password123"}'
```

### Step 4: Update AuthProvider (Next Step)

The AuthProvider currently uses local lookup instead of API calls. We need to update it to call `/api/auth/login`.

## 🔍 Current Status

- ✅ Backend auth route created
- ⚠️ AuthProvider still uses local lookup (needs update)
- ⚠️ Need test user in database
- ⚠️ Backend server needs to be running

## 📝 Testing

Once backend is running and you have a user:

1. Start backend: `cd backend && node server.js`
2. Start admin app: `cd apps/admin_app && flutter run -d web-server`
3. Try logging in with your test credentials



