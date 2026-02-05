# Fix: Missing invitation_requests Table

## Problem
The `invitation_requests` table is missing from the database, causing errors when users try to create accounts.

## Solution

The auto-migration script has been updated to automatically create this table on the next deployment. However, for an immediate fix, you have two options:

### Option 1: Wait for Next Deployment (Recommended)
The updated `auto_migrate.js` will automatically create the missing tables when the server restarts or redeploys. Just redeploy your Render service.

### Option 2: Run Migration Manually (Immediate Fix)

#### Using Render Database Console:
1. Go to your Render dashboard
2. Navigate to your PostgreSQL database
3. Click on "Connect" or "Shell"
4. Run this SQL:

```sql
-- Copy and paste the contents of backend/migrations/add_invitation_tables.sql
```

Or connect via psql and run:
```bash
psql $DATABASE_URL -f backend/migrations/add_invitation_tables.sql
```

#### Using the Migration Script:
If you have access to run Node.js scripts on Render:
```bash
cd backend && node migrations/add_invitation_tables.js
```

## What Was Fixed

1. **Updated `backend/scripts/auto_migrate.js`**: Now automatically checks for and creates `invitation_requests` and `company_invitations` tables
2. **Created `backend/migrations/add_invitation_tables.sql`**: SQL file that can be run immediately (uses `gen_random_uuid()` which doesn't require extensions)
3. **Created `backend/migrations/add_invitation_tables.js`**: Node.js script that can be run manually

## Verification

After running the migration, verify the table exists:
```sql
SELECT * FROM invitation_requests LIMIT 1;
```

If this query runs without errors, the table has been created successfully.
