# Fix: Password Reset Columns Missing

## Quick Fix Options

### Option 1: Trigger Migration via API (Easiest)

Make a POST request to trigger the migration:

```bash
curl -X POST https://staff4dshire-backend.onrender.com/api/admin/migrate
```

Or use your browser/Postman to POST to:
```
https://staff4dshire-backend.onrender.com/api/admin/migrate
```

This will run the auto-migration which includes adding password reset columns.

### Option 2: Wait for Next Deployment

The auto-migration will run automatically on the next deployment. Just redeploy your backend service in Render.

### Option 3: Run SQL Directly (If you have database access)

If you have direct access to your Render PostgreSQL database, run this SQL:

```sql
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS password_reset_token VARCHAR(255),
ADD COLUMN IF NOT EXISTS password_reset_token_expires_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_users_password_reset_token 
ON users(password_reset_token) 
WHERE password_reset_token IS NOT NULL;
```

**To access Render database:**
1. Go to Render Dashboard
2. Click on your PostgreSQL database
3. Click "Connect" or "Shell"
4. Run the SQL above

### Option 4: Run Migration Script Locally

If you have the database connection string, you can run:

```bash
cd backend
node migrations/add_password_reset_columns.js
```

## Verify It Worked

After running the migration, check the logs. You should see:
```
✅ Password reset fields added successfully!
```

Or verify by checking if the column exists:
```sql
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'password_reset_token';
```

If this returns a row, the column exists and password reset should work!
