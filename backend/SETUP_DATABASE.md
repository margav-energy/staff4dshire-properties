# Database Setup Instructions

## Step 1: Create PostgreSQL User and Database

Run these commands in PostgreSQL (as a superuser, e.g., `postgres`):

```sql
CREATE USER staff4dshire WITH PASSWORD 'your_secure_password_here';
CREATE DATABASE staff4dshire OWNER staff4dshire;
GRANT ALL PRIVILEGES ON DATABASE staff4dshire TO staff4dshire;

\c staff4dshire
GRANT ALL ON SCHEMA public TO staff4dshire;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO staff4dshire;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO staff4dshire;
```

**Important**: Replace `'your_secure_password_here'` with a strong password you'll remember.

## Step 2: Set Password for Existing User

If you already created the user without a password, set one now:

```sql
ALTER USER staff4dshire WITH PASSWORD 'your_secure_password_here';
```

## Step 3: Create .env File

Create a `.env` file in the `backend` directory with the following content:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=staff4dshire
DB_USER=staff4dshire
DB_PASSWORD=your_secure_password_here

PORT=3001
NODE_ENV=development
```

**Important**: Replace `your_secure_password_here` with the actual password you set in Step 1 or 2.

## Step 4: Run Database Schema

```bash
psql -U staff4dshire -d staff4dshire -f schema.sql
```

You'll be prompted for the password you set.

## Step 5: Start the Server

```bash
npm run dev
```

The server should now connect successfully!

## Troubleshooting

### Error: "client password must be a string"

This means the password in your `.env` file is missing or empty. Make sure:
1. The `.env` file exists in the `backend` directory
2. `DB_PASSWORD` is set to a non-empty value
3. The password matches the one you set for the PostgreSQL user

### Error: "password authentication failed"

This means the password in your `.env` file doesn't match the PostgreSQL user password. Check:
1. The password in `.env` matches the one set in PostgreSQL
2. No extra spaces or quotes around the password in `.env`

### Can't connect to database

Make sure PostgreSQL is running:
- Windows: Check Services for "postgresql" service
- Linux/Mac: `sudo systemctl status postgresql` or `brew services list`

