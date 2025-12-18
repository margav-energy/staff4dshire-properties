#!/bin/bash
# Script to enable UUID extension in PostgreSQL

echo "Enabling UUID extension in PostgreSQL..."
echo "You will need to enter the postgres superuser password."

# Enable the extension
psql -U postgres -d staff4dshire -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ UUID extension enabled successfully!"
    echo ""
    echo "Now you can run the migration:"
    echo "psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion.sql"
else
    echo ""
    echo "❌ Failed to enable extension. You may need to:"
    echo "   1. Check your postgres superuser password"
    echo "   2. Use the alternative schema (no extension needed):"
    echo "      psql -U staff4dshire -d staff4dshire -f backend/schema_job_completion_v2.sql"
fi


