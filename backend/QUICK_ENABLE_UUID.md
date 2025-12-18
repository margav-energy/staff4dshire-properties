# Quick Guide: Enable UUID Extension

## Method 1: Single Command (Fastest)

Run this command and enter the `postgres` password when prompted:

```bash
psql -U postgres -d staff4dshire -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
```

**Then run your migration:**
```bash
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
```

---

## Method 2: Interactive Session

1. Connect to PostgreSQL as superuser:
   ```bash
   psql -U postgres -d staff4dshire
   ```

2. Enable the extension:
   ```sql
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   ```

3. Verify it worked:
   ```sql
   SELECT * FROM pg_extension WHERE extname = 'uuid-ossp';
   ```
   (You should see 1 row)

4. Exit:
   ```sql
   \q
   ```

5. Run the migration:
   ```bash
   psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
   ```

---

## Method 3: No Extension Needed (Easiest!)

If you can't access the postgres superuser, just use the alternative schema:

```bash
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion_v2.sql
```

This version uses PostgreSQL's built-in UUID function and doesn't need any extensions!


