# Add last_login Column to Database

## Quick Fix

Run this SQL command on your PostgreSQL database:

```sql
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS last_login TIMESTAMP;
```

## How to Run

**Option 1: Using psql command line**
```bash
psql -U your_username -d your_database_name -f migrations/add_last_login.sql
```

**Option 2: Using pgAdmin or any SQL client**
- Connect to your database
- Run the SQL from `migrations/add_last_login.sql`

**Option 3: Using Node.js script**
```bash
cd backend
node -e "
const pool = require('./db');
pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP')
  .then(() => { console.log('Column added!'); process.exit(0); })
  .catch(err => { console.error(err); process.exit(1); });
"
```

## What This Does

Adds a `last_login TIMESTAMP` column to track when users last logged in. This is optional but useful for:
- Security monitoring
- User activity tracking
- Session management

## Note

The auth route will work even if this column doesn't exist (it will just skip updating it). But it's good practice to add it.



