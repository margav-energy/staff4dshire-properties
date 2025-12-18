# Quick Start - Backend Setup

## ✅ What I Just Created

1. **Created `/backend/routes/auth.js`** - Login endpoint at `/api/auth/login`
2. **Updated `/backend/server.js`** - Added auth routes  
3. **Updated `packages/shared/lib/core/providers/auth_provider.dart`** - Now calls backend API for login

## 🚀 To Get Login Working:

### Step 1: Start Backend Server

```bash
cd backend
npm install  # Make sure dependencies are installed
node server.js
```

The server should start on port **3001** and show:
```
Server is running on port 3001
Health check: http://localhost:3001/api/health
```

### Step 2: Create a Test User

You need at least one user in the database. Options:

**Option A: Use the superadmin script**
```bash
cd backend
node create_superadmin.js admin@test.com password123
```

**Option B: Create via SQL** (if you have database access)
```sql
-- Make sure you have a default company first
INSERT INTO companies (id, name) 
VALUES ('00000000-0000-0000-0000-000000000001', 'Default Company')
ON CONFLICT DO NOTHING;

-- Create admin user (password: password123)
-- You need to hash the password first with bcrypt
-- Or use the create_superadmin.js script which does this
```

**Option C: Register via the app** (if registration is working)

### Step 3: Test the Login

1. Make sure backend is running: `cd backend && node server.js`
2. Open the admin app: `cd apps/admin_app && flutter run -d web-server`
3. Try logging in with your test credentials

### Step 4: Verify Backend Connection

Check browser console (F12) or terminal for:
- ✅ "API login successful" messages
- ❌ Connection errors (CORS, network, etc.)

## 🔧 Troubleshooting

**"Invalid email or password"**
- User doesn't exist in database
- Password hash doesn't match
- User is inactive (`is_active = FALSE`)

**Connection refused / CORS errors**
- Backend server not running
- Wrong port (should be 3001)
- CORS not configured (should be enabled in server.js)

**Still can't login?**
- Check backend terminal for error messages
- Verify user exists: `SELECT * FROM users WHERE email = 'your@email.com';`
- Check password hash is set: `SELECT id, email, password_hash IS NOT NULL as has_password FROM users;`

## 📝 Test Credentials

After running `create_superadmin.js`, you can use:
- **Email:** `admin@test.com` (or whatever you specified)
- **Password:** `password123` (or whatever you specified)



