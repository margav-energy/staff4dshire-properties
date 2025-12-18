# Database Schema Migration - Fix Instructions

## Problem
The migration failed because the `uuid-ossp` extension isn't enabled or requires superuser privileges.

## Quick Fix: Use Built-in UUID Function

I've created a **simpler version** that uses PostgreSQL's built-in UUID function (no extension needed):

### Step 1: Run the Fixed Schema

```bash
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion_v2.sql
```

This version uses `gen_random_uuid()` which is built into PostgreSQL 13+ and doesn't require any extension setup.

## Alternative: Enable UUID Extension

If you want to use the original version with `uuid_generate_v4()`, you need to enable the extension as a superuser:

### Option A: As postgres superuser

```bash
# First enable extension
psql -U postgres -d staff4dshire -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

# Then run migration
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
```

### Option B: Grant permissions

If you're using a non-superuser account:

```bash
# As postgres user, grant extension permission
psql -U postgres -d staff4dshire -c "GRANT ALL ON EXTENSION \"uuid-ossp\" TO staff4dshire;"

# Then run migration
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
```

## Recommended Solution

**Use `schema_job_completion_v2.sql`** - it's simpler and doesn't require extension setup!

The `gen_random_uuid()` function is built into PostgreSQL 13+ and works without any extensions.


