# 🚨 Fix: Database Connection Error

## Problem
The backend can't connect to the database and the schema hasn't been run.

## ✅ Solution: Two Steps

### Step 1: Verify Database Exists

1. **Go to Render Dashboard** → Check if `staff4dshire-db` database exists
2. **If it doesn't exist:**
   - Create it: "New +" → "PostgreSQL"
   - Name: `staff4dshire-db`
   - Database: `staff4dshire`
   - User: `staff4dshire`

### Step 2: Run Database Schema

Since you're on free tier (no shell access), you need to run the schema using Render's database connection.

#### Option A: Use Render's Database Shell (Recommended)

1. **Go to Render Dashboard** → Your Database (`staff4dshire-db`)
2. **Click "Connect"** or "Shell" tab
3. **Copy the connection string** or use the provided connection info
4. **Run the schema** using one of these methods:

**Method 1: Using psql (if you have it locally)**
```bash
# Get connection string from Render Dashboard → Database → Connect
# It will look like: postgresql://staff4dshire:password@host:port/staff4dshire

# Then run:
psql "postgresql://staff4dshire:password@host:port/staff4dshire" -f backend/schema.sql
```

**Method 2: Using Render's Web Shell (if available)**
- Go to Database → Shell tab
- Copy and paste the SQL from `backend/schema.sql`
- Execute it

**Method 3: Create a migration script** (see below)

---

## 🔧 Quick Fix: Create Auto-Migration Script

I'll create a script that runs the schema automatically on server start if tables don't exist.
