# 🚨 Manual Schema Migration - Quick Fix

## The Problem
Auto-migration isn't working. You need to run the schema manually.

## ✅ Solution: Run Schema via Render Database Connection

Since you're on free tier (no shell), use one of these methods:

### Method 1: Using Render's Database Shell (If Available)

1. **Go to Render Dashboard** → Database (`staff4dshire-db`)
2. **Click "Shell" or "Connect" tab**
3. **Copy the SQL from `backend/schema.sql`**
4. **Paste and execute** in the shell

### Method 2: Using psql Locally (If You Have It)

1. **Get connection string from Render:**
   - Database → Connect tab
   - Copy the "Internal Database URL"

2. **Run schema:**
   ```bash
   psql "postgresql://staff4dshire_user:password@host:port/staff4dshire?sslmode=require" -f backend/schema.sql
   ```

### Method 3: Create Migration Endpoint (I'll add this)

I'll create an admin endpoint you can call to trigger migration manually.

---

## 📝 Quick SQL to Run

If you can access the database, run this SQL:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('staff', 'supervisor', 'admin', 'superadmin')),
    phone_number VARCHAR(20),
    photo_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Projects Table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_completed BOOLEAN DEFAULT FALSE,
    before_photo VARCHAR(500),
    after_photo VARCHAR(500),
    completed_at TIMESTAMP,
    type VARCHAR(50) NOT NULL DEFAULT 'regular' CHECK (type IN ('regular', 'callout')),
    category VARCHAR(100),
    photos JSONB DEFAULT '[]'::jsonb,
    drawings JSONB DEFAULT '[]'::jsonb,
    assigned_staff_ids UUID[] DEFAULT ARRAY[]::UUID[],
    assigned_supervisor_ids UUID[] DEFAULT ARRAY[]::UUID[],
    start_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Time Entries Table
CREATE TABLE IF NOT EXISTS time_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    sign_in_time TIMESTAMP NOT NULL,
    sign_out_time TIMESTAMP,
    sign_in_latitude DECIMAL(10, 8),
    sign_in_longitude DECIMAL(11, 8),
    sign_out_latitude DECIMAL(10, 8),
    sign_out_longitude DECIMAL(11, 8),
    sign_in_location VARCHAR(255),
    sign_out_location VARCHAR(255),
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Or better:** Copy the entire `backend/schema.sql` file content and run it.

---

## ✅ After Running Schema

1. **Check backend logs** - should show "Database connected successfully"
2. **Test API:** `https://staff4dshire-backend.onrender.com/api/health`
3. **Test login:** `admin@staff4dshire.com` / `Admin123!`

---

## 🔧 Alternative: I'll Add Migration Endpoint

I'm adding a manual migration trigger endpoint you can call.
