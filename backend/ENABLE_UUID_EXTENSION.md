# How to Enable UUID Extension in PostgreSQL

## Step 1: Connect as PostgreSQL Superuser

You need to connect as the `postgres` superuser (or another superuser account) to create extensions.

### On Windows (Git Bash):

```bash
psql -U postgres -d staff4dshire
```

If this asks for a password, enter the postgres superuser password.

## Step 2: Enable the Extension

Once connected, run this command:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

## Step 3: Verify It's Enabled

Check that the extension is now available:

```sql
SELECT * FROM pg_extension WHERE extname = 'uuid-ossp';
```

You should see a row returned.

## Step 4: Exit and Run Migration

Exit psql:

```sql
\q
```

Then run your migration:

```bash
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
```

---

## Alternative: All in One Command

If you know the postgres password, you can do it all in one command:

```bash
psql -U postgres -d staff4dshire -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
```

Then run the migration:

```bash
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
```

---

## If You Don't Have Postgres Superuser Access

If you don't have the postgres superuser password or access, you have two options:

### Option 1: Ask Your Database Administrator

Ask your DBA to run:
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Option 2: Use the Fixed Schema (No Extension Needed)

Use the alternative schema file that doesn't require the extension:

```bash
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion_v2.sql
```

This uses `gen_random_uuid()` which is built into PostgreSQL 13+ and doesn't need any extensions.


