#!/bin/bash
# Complete database setup script

echo "========================================="
echo "Setting up Staff4dshire Properties Database"
echo "========================================="
echo ""

# Step 1: Main Schema
echo "Step 1: Creating base tables (users, projects, time_entries, etc.)..."
psql -U staff4dshire -d staff4dshire -f backend/schema.sql

if [ $? -eq 0 ]; then
    echo "✅ Base schema created successfully!"
else
    echo "❌ Error creating base schema. Please check the errors above."
    exit 1
fi

echo ""
echo "Step 2: Creating job completion and invoice tables..."
psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql

if [ $? -eq 0 ]; then
    echo "✅ Job completion schema created successfully!"
    echo ""
    echo "========================================="
    echo "✅ Database setup complete!"
    echo "========================================="
else
    echo "❌ Error creating job completion schema. Please check the errors above."
    exit 1
fi


