# Database Setup Steps

## The Problem
The job completion migration failed because the base tables don't exist yet. You need to run the main schema first.

## Step-by-Step Setup

### Step 1: Run the Main Schema (if not already done)

Run this to create all the base tables (`users`, `projects`, `time_entries`, etc.):

```bash
psql -U staff4dshire -d staff4dshire -f backend/schema.sql
```

**Note:** If you get errors about the UUID extension, that's okay - it's already enabled. The script will skip it.

### Step 2: Run the Job Completion Schema

After the main schema is successfully run, run the job completion schema:

```bash
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
```

## Quick Check: Verify Tables Exist

To check which tables exist in your database:

```bash
psql -U staff4dshire -d staff4dshire -c "\dt"
```

You should see tables like:
- users
- projects
- time_entries
- documents
- etc.

## If You Already Ran the Main Schema

If you already ran `schema.sql` before, but the tables don't exist, you might need to:
1. Check if you're connected to the correct database
2. Verify the schema ran without errors
3. Check if tables were dropped accidentally

## Full Setup (From Scratch)

If you're setting up a fresh database:

```bash
# 1. Enable UUID extension (already done, but safe to run again)
psql -U postgres -d staff4dshire -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

# 2. Run main schema
psql -U staff4dshire -d staff4dshire -f backend/schema.sql

# 3. Run job completion schema
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
```


