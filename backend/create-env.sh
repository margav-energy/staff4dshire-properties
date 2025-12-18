#!/bin/bash
# Script to create .env file for Linux/Mac

ENV_FILE=".env"

if [ -f "$ENV_FILE" ]; then
    echo ".env file already exists"
    echo "Please edit it manually and set DB_PASSWORD"
    exit 1
fi

cat > "$ENV_FILE" << EOF
DB_HOST=localhost
DB_PORT=5432
DB_NAME=staff4dshire
DB_USER=staff4dshire
DB_PASSWORD=YOUR_PASSWORD_HERE

PORT=3001
NODE_ENV=development
EOF

echo ".env file created"
echo "IMPORTANT: Please edit the .env file and replace 'YOUR_PASSWORD_HERE' with your actual database password"
chmod 600 "$ENV_FILE"  # Make it readable only by owner

