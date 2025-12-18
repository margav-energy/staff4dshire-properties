# How to Start the Backend Server

## Quick Start
```bash
cd backend
npm start
```

You should see:
```
Server is running on port 3001
Health check: http://localhost:3001/api/health
Database connected successfully
```

## If Server Won't Start

### 1. Check if port is already in use
```bash
# Windows
netstat -ano | findstr :3001

# If port is in use, kill the process or change PORT in .env
```

### 2. Check database connection
Make sure your `.env` file has correct database credentials:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=staff4dshire
DB_USER=staff4dshire
DB_PASSWORD=your_password
PORT=3001
NODE_ENV=development
```

### 3. Install dependencies (if needed)
```bash
cd backend
npm install
```

### 4. Start server
```bash
npm start
```

## Keep Server Running

**IMPORTANT**: The backend server must be running for the mobile app to work!

- Keep the terminal window open where you ran `npm start`
- Don't close the terminal or the server will stop
- If you see "Server is running on port 3001", the server is active

## Test Server is Working

Open a new terminal and run:
```bash
cd backend
node test_user_creation.js
```

You should see: `✅ SUCCESS: User created successfully!`

