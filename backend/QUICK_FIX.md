# Quick Fix: Database Connection Error

## The Problem
You're getting: `Error: SASL: SCRAM-SERVER-FIRST-MESSAGE: client password must be a string`

This means the database password is missing or not set.

## Quick Fix Steps

### Step 1: Set Password for PostgreSQL User

Connect to PostgreSQL and set a password for the `staff4dshire` user:

```bash
psql -U postgres
```

Then run:
```sql
ALTER USER staff4dshire WITH PASSWORD 'YourPassword123!';
```

Replace `'YourPassword123!'` with your own secure password. **Remember this password!**

### Step 2: Create .env File

Create a file named `.env` in the `backend` folder with this content:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=staff4dshire
DB_USER=staff4dshire
DB_PASSWORD=YourPassword123!

PORT=3001
NODE_ENV=development
```

**IMPORTANT**: Replace `YourPassword123!` with the exact same password you set in Step 1.

### Step 3: Restart Server

Stop the server (Ctrl+C) and restart:

```bash
npm run dev
```

You should now see: "Database connected successfully" ✅

## Alternative: Quick Script

### Windows (PowerShell)
```powershell
cd backend
@"
DB_HOST=localhost
DB_PORT=5432
DB_NAME=staff4dshire
DB_USER=staff4dshire
DB_PASSWORD=YourPassword123!

PORT=3001
NODE_ENV=development
"@ | Out-File -FilePath .env -Encoding utf8
```

Then edit `.env` and change `YourPassword123!` to your actual password.

### Linux/Mac (Bash)
```bash
cd backend
cat > .env << 'EOF'
DB_HOST=localhost
DB_PORT=5432
DB_NAME=staff4dshire
DB_USER=staff4dshire
DB_PASSWORD=YourPassword123!

PORT=3001
NODE_ENV=development
EOF
```

Then edit `.env` and change `YourPassword123!` to your actual password.

## Verify Connection

After restarting, you should see:
- ✅ "Database connected successfully"
- ✅ Server running on port 3001

If you still get errors, check:
1. The password in `.env` matches the PostgreSQL user password exactly
2. No extra spaces or quotes around the password in `.env`
3. PostgreSQL service is running

