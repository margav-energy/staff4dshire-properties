# 🔧 Database Setup - Run These Commands

## The Problem
The base tables (`time_entries`, `projects`, etc.) don't exist yet, so the job completion migration can't run.

## Solution: Run in This Order

### 1️⃣ First: Create Base Tables

```bash
psql -U staff4dshire -d staff4dshire -f backend/schema.sql
```

This creates all the base tables like:
- `users`
- `projects`
- `time_entries`
- `documents`
- etc.

### 2️⃣ Then: Create Job Completion Tables

```bash
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
```

This creates the job completion and invoice tables.

---

## Quick Copy-Paste (Run Both)

```bash
# Step 1: Base tables
psql -U staff4dshire -d staff4dshire -f backend/schema.sql

# Step 2: Job completion tables  
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql
```

---

## Verify It Worked

Check that tables were created:

```bash
psql -U staff4dshire -d staff4dshire -c "\dt"
```

You should see tables including:
- `job_completions`
- `invoices`
- `job_completion_images`
- And all the base tables


