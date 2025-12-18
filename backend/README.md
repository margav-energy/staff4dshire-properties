# Staff4dshire Properties Backend API

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Database

Create a `.env` file in the `backend` directory:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=staff4dshire
DB_USER=postgres
DB_PASSWORD=your_password_here

PORT=3001
NODE_ENV=development
```

### 3. Create Database and Run Schema

```bash
# Create the database (if not exists)
createdb staff4dshire

# Run the schema
psql -d staff4dshire -f schema.sql
```

### 4. Start the Server

```bash
# Development mode (with auto-restart)
npm run dev

# Production mode
npm start
```

The server will run on `http://localhost:3001`

## API Endpoints

### Health Check
- `GET /api/health` - Check if API is running

### Users
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `GET /api/users/email/:email` - Get user by email
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Projects
- `GET /api/projects` - Get all projects
- `GET /api/projects/:id` - Get project by ID
- `POST /api/projects` - Create new project
- `PUT /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project

### Timesheets (Time Entries)
- `GET /api/timesheets` - Get all time entries
- `GET /api/timesheets/user/:userId` - Get time entries by user
- `GET /api/timesheets/:id` - Get time entry by ID
- `POST /api/timesheets` - Create new time entry (sign in)
- `PUT /api/timesheets/:id` - Update time entry (sign out)
- `DELETE /api/timesheets/:id` - Delete time entry

## Database Schema

See `schema.sql` for the complete database schema.

## Notes

- The API uses PostgreSQL UUIDs for IDs
- JSON fields (photos, drawings) are stored as JSONB in PostgreSQL
- Arrays (assigned_staff_ids, assigned_supervisor_ids) are stored as UUID arrays

