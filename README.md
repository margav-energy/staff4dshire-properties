# Staff4dshire Properties

A comprehensive multi-platform application system for property management, staff tracking, timesheet automation, safety compliance, and real-time communication. Built with Flutter for mobile/web apps and Node.js/Express for the backend API.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [User Roles & Permissions](#user-roles--permissions)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Documentation](#api-documentation)
- [Features in Detail](#features-in-detail)
- [Design System](#design-system)
- [Development](#development)

---

## 🎯 Overview

Staff4dshire Properties is a complete workforce management solution designed for property management companies, construction sites, and facilities management. The system enables real-time tracking of staff attendance, automated timesheet generation, safety compliance management, document tracking, and team communication.

### What the App Does

The application provides three main interfaces:

1. **Admin App** - Full administrative control for company managers, HR, and system administrators
2. **Staff App** - Field worker interface for sign-in/out, timesheet viewing, compliance forms, and communication
3. **Backend API** - RESTful API with WebSocket support for real-time features

The system supports **multi-tenancy**, allowing multiple companies to operate independently within the same infrastructure, with role-based access control ensuring data isolation and security.

---

## 🏗️ Architecture

The application follows a **monorepo architecture** with clear separation of concerns:

```
Staff4dshire Properties/
├── apps/
│   ├── admin_app/          # Flutter app for administrators
│   └── staff_app/           # Flutter app for field staff
├── packages/
│   └── shared/              # Shared Dart code (models, services, providers)
├── backend/                 # Node.js/Express API server
│   ├── routes/              # API route handlers
│   ├── migrations/          # Database migration scripts
│   └── middleware/          # Express middleware
├── web/                     # Next.js web application (legacy)
└── docs/                    # Documentation
```

### Key Architectural Decisions

- **Monorepo Structure**: Single repository for all apps and shared code
- **Shared Package**: Common business logic, models, and API services shared between admin and staff apps
- **Multi-tenant Database**: Company-based data isolation with UUID-based relationships
- **Real-time Communication**: Socket.io for WebSocket-based chat and notifications
- **Cross-platform**: Flutter apps run on iOS, Android, Web, and Windows

---

## ✨ Key Features

### Core Functionality

#### 1. **Time Tracking & Attendance**
- **One-tap Sign In/Out**: Quick sign-in/out with GPS location capture
- **Project Selection**: Assign time entries to specific projects/sites
- **Automatic Timesheets**: Weekly timesheet generation from sign-in/out data
- **Export Options**: PDF, Excel, and CSV export for payroll integration
- **Live Headcount**: Real-time view of who's on-site (supervisor feature)

#### 2. **Safety & Compliance**
- **Daily Fit-to-Work Declarations**: Health and safety compliance tracking
- **Digital RAMS Sign-Off**: Risk Assessment and Method Statement acknowledgment
- **Toolbox Talk Attendance**: Track safety briefings and training sessions
- **Fire Roll Call**: Emergency evacuation tracking system
- **Incident Reporting**: Document and track workplace incidents

#### 3. **Document Management**
- **Document Hub**: Centralized storage for:
  - CSCS cards
  - Health & Safety certificates
  - Insurance documents
  - CPP (Construction Phase Plans)
  - RAMS documents
- **Expiry Reminders**: Automated notifications for expiring documents
- **Document Verification**: Admin review and approval system

#### 4. **User & Company Management**
- **Multi-tenant Architecture**: Support for multiple companies
- **User Management**: Create, edit, activate/deactivate users
- **Role-based Access Control**: Staff, Supervisor, Admin, and Superadmin roles
- **Company Invitations**: Invite users to join companies
- **Onboarding System**: Track employee onboarding and inductions

#### 5. **Real-time Communication**
- **Chat System**: Direct messaging and group conversations
- **Project-based Chats**: Team communication for specific projects
- **Real-time Notifications**: Push notifications with sound alerts
- **Typing Indicators**: See when others are typing
- **Message Read Status**: Track message delivery and read receipts

#### 6. **Job Management**
- **Job Completion Tracking**: Submit and approve job completions
- **Photo Attachments**: Attach photos to job completion reports
- **Invoice Management**: Track invoices and payments
- **Project Management**: Create and manage projects/sites

#### 7. **Reporting & Analytics**
- **Attendance Reports**: Track attendance patterns
- **Timesheet Reports**: Detailed time tracking reports
- **Compliance Reports**: Safety and compliance metrics
- **Headcount Reports**: Real-time and historical headcount data

---

## 👥 User Roles & Permissions

### **Staff**
- Sign in/out with GPS tracking
- View own timesheet
- Submit fit-to-work declarations
- Sign RAMS documents
- Mark toolbox talk attendance
- Upload and view own documents
- View notifications
- Participate in chat conversations
- Submit job completions
- Report incidents

### **Supervisor**
- All Staff permissions, plus:
- View live headcount
- Conduct fire roll call
- Approve/edit timesheets
- View team reports
- Manage toolbox talks
- View team members' timesheets

### **Admin**
- All Supervisor permissions, plus:
- Full user management (CRUD operations)
- Project management
- Company management
- System-wide reports
- Timesheet exports
- Induction management
- Document verification
- System configuration
- Invoice management
- Job completion approvals

### **Superadmin**
- All Admin permissions, plus:
- Access to all companies
- System-wide administration
- Database management
- Global settings

---

## 🛠️ Technology Stack

### Frontend (Mobile/Web Apps)
- **Framework**: Flutter 3.0+ (Dart)
- **State Management**: Provider
- **HTTP Client**: http package
- **WebSocket**: socket_io_client
- **Local Storage**: shared_preferences
- **Image Handling**: image_picker
- **File Handling**: file_picker
- **Audio Playback**: audioplayers
- **Platforms**: iOS, Android, Web, Windows

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Real-time**: Socket.io
- **Authentication**: bcrypt for password hashing
- **Email**: nodemailer
- **UUID Generation**: uuid package

### Database
- **PostgreSQL** with UUID extension
- **Multi-tenant** architecture with company-based isolation
- **JSONB** fields for flexible data storage
- **Array types** for relationships

### Web Application (Legacy)
- **Framework**: Next.js (React/TypeScript)
- **Styling**: Tailwind CSS

---

## 📁 Project Structure

```
Staff4dshire Properties/
├── apps/
│   ├── admin_app/
│   │   ├── lib/
│   │   │   ├── core/
│   │   │   │   ├── router/          # Navigation routing
│   │   │   │   └── widgets/          # Reusable widgets
│   │   │   └── features/
│   │   │       ├── auth/             # Authentication screens
│   │   │       ├── chat/             # Chat feature
│   │   │       ├── companies/        # Company management
│   │   │       ├── dashboard/        # Admin dashboards
│   │   │       ├── users/            # User management
│   │   │       ├── projects/         # Project management
│   │   │       ├── settings/         # Settings screens
│   │   │       └── ...
│   │   ├── assets/                   # Images, sounds, etc.
│   │   └── pubspec.yaml
│   │
│   └── staff_app/
│       ├── lib/
│       │   ├── core/
│       │   │   ├── router/           # Navigation routing
│       │   │   └── widgets/          # Reusable widgets
│       │   └── features/
│       │       ├── auth/             # Authentication
│       │       ├── chat/             # Chat feature
│       │       ├── dashboard/        # Staff dashboards
│       │       ├── timesheet/       # Timesheet viewing
│       │       ├── sign_in_out/      # Sign in/out feature
│       │       ├── documents/        # Document management
│       │       ├── compliance/      # Compliance forms
│       │       ├── settings/         # Settings screens
│       │       └── ...
│       ├── assets/
│       └── pubspec.yaml
│
├── packages/
│   └── shared/
│       └── lib/
│           ├── core/
│           │   ├── models/           # Data models (User, Project, etc.)
│           │   ├── providers/        # State providers
│           │   ├── services/         # API services
│           │   └── utils/            # Utility functions
│           └── shared.dart
│
├── backend/
│   ├── routes/                       # API route handlers
│   │   ├── auth.js                   # Authentication
│   │   ├── users.js                  # User management
│   │   ├── companies.js              # Company management
│   │   ├── projects.js               # Project management
│   │   ├── timesheets.js             # Time tracking
│   │   ├── chat.js                   # Chat API
│   │   ├── notifications.js          # Notifications
│   │   ├── job-completions.js        # Job management
│   │   ├── incidents.js              # Incident reporting
│   │   └── ...
│   ├── migrations/                   # Database migrations
│   ├── middleware/                   # Express middleware
│   ├── db.js                         # Database connection
│   ├── server.js                     # Express server setup
│   └── package.json
│
├── web/                              # Next.js web app (legacy)
│   ├── app/                          # Next.js app directory
│   └── package.json
│
└── docs/                             # Documentation
    ├── FEATURES.md
    ├── CHAT_IMPLEMENTATION_GUIDE.md
    └── ...
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.0 or higher
- **Node.js** 18.x or higher
- **PostgreSQL** 14.x or higher
- **Git**

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create `.env` file:**
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=staff4dshire
   DB_USER=postgres
   DB_PASSWORD=your_password_here
   PORT=3001
   NODE_ENV=development
   ```

4. **Create database:**
   ```bash
   createdb staff4dshire
   ```

5. **Run database schema:**
   ```bash
   psql -d staff4dshire -f schema.sql
   ```

6. **Run migrations (if any):**
   ```bash
   node migrations/add_chat_tables.js
   # ... run other migrations as needed
   ```

7. **Start the server:**
   ```bash
   # Development mode (with auto-restart)
   npm run dev

   # Production mode
   npm start
   ```

   The API will be available at `http://localhost:3001`

### Admin App Setup

1. **Navigate to admin app:**
   ```bash
   cd apps/admin_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update API endpoint** in `packages/shared/lib/core/services/api_service.dart` if needed

4. **Run the app:**
   ```bash
   # Mobile
   flutter run

   # Web
   flutter run -d chrome

   # Windows
   flutter run -d windows
   ```

### Staff App Setup

1. **Navigate to staff app:**
   ```bash
   cd apps/staff_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update API endpoint** in `packages/shared/lib/core/services/api_service.dart` if needed

4. **Run the app:**
   ```bash
   # Mobile
   flutter run

   # Web
   flutter run -d chrome

   # Windows
   flutter run -d windows
   ```

### Shared Package

The shared package is automatically included as a local dependency. If you need to update it:

```bash
cd packages/shared
flutter pub get
```

---

## 📡 API Documentation

### Base URL
```
http://localhost:3001/api
```

### Authentication
All protected endpoints require authentication. Include user context via query parameters (temporary) or authentication headers.

### Main Endpoints

#### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/password-reset/request` - Request password reset
- `POST /api/password-reset/reset` - Reset password

#### Users
- `GET /api/users` - Get all users (filtered by company)
- `GET /api/users/:id` - Get user by ID
- `GET /api/users/email/:email` - Get user by email
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user
- `GET /api/users/:id/photo` - Get user photo

#### Companies
- `GET /api/companies` - Get all companies (filtered by user)
- `GET /api/companies/:id` - Get company by ID
- `POST /api/companies` - Create new company
- `PUT /api/companies/:id` - Update company
- `DELETE /api/companies/:id` - Delete company

#### Projects
- `GET /api/projects` - Get all projects (filtered by company)
- `GET /api/projects/:id` - Get project by ID
- `POST /api/projects` - Create new project
- `PUT /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project

#### Timesheets (Time Entries)
- `GET /api/timesheets` - Get all time entries
- `GET /api/timesheets/user/:userId` - Get time entries by user
- `GET /api/timesheets/:id` - Get time entry by ID
- `POST /api/timesheets` - Create time entry (sign in)
- `PUT /api/timesheets/:id` - Update time entry (sign out)
- `DELETE /api/timesheets/:id` - Delete time entry

#### Chat
- `GET /api/chat/conversations` - Get user's conversations
- `POST /api/chat/conversations` - Create new conversation
- `GET /api/chat/conversations/:id/messages` - Get messages in conversation
- `POST /api/chat/messages` - Send message
- `PUT /api/chat/messages/:id/read` - Mark message as read

#### Notifications
- `GET /api/notifications` - Get user notifications
- `PUT /api/notifications/:id/read` - Mark notification as read
- `DELETE /api/notifications/:id` - Delete notification

#### Job Completions
- `GET /api/job-completions` - Get job completions
- `POST /api/job-completions` - Submit job completion
- `PUT /api/job-completions/:id` - Update job completion
- `PUT /api/job-completions/:id/approve` - Approve job completion

#### Incidents
- `GET /api/incidents` - Get incidents
- `POST /api/incidents` - Report incident
- `PUT /api/incidents/:id` - Update incident

#### Onboarding
- `GET /api/onboarding` - Get onboarding records
- `POST /api/onboarding` - Create onboarding record
- `PUT /api/onboarding/:id` - Update onboarding record

### WebSocket Events (Socket.io)

#### Client → Server
- `join-user-room` - Join personal notification room
- `join-conversation` - Join chat conversation
- `leave-conversation` - Leave chat conversation
- `typing` - Send typing indicator
- `stop-typing` - Stop typing indicator

#### Server → Client
- `user-typing` - User is typing
- `user-stopped-typing` - User stopped typing
- `new-message` - New chat message
- `notification` - New notification

---

## 📖 Features in Detail

### Time Tracking System

The time tracking system is the core of the application, enabling accurate attendance monitoring and automated payroll processing.

**Sign-In Process:**
1. User selects a project/site
2. System captures GPS coordinates
3. Records timestamp
4. Creates time entry record
5. Updates live headcount

**Sign-Out Process:**
1. User initiates sign-out
2. System captures GPS coordinates
3. Records timestamp
4. Updates time entry with duration
5. Calculates hours worked
6. Updates live headcount

**Timesheet Generation:**
- Automatically aggregates sign-in/out entries
- Calculates daily and weekly totals
- Groups by project
- Supports export in multiple formats

### Chat System

Real-time messaging system with the following capabilities:

- **Direct Messages**: One-on-one conversations
- **Group Chats**: Multi-user conversations
- **Project Chats**: Conversations tied to specific projects
- **File Attachments**: Send images and files
- **Typing Indicators**: See when others are typing
- **Read Receipts**: Track message delivery
- **Real-time Delivery**: Instant message delivery via WebSocket

### Notification System

Comprehensive notification system with:

- **Push Notifications**: Real-time alerts
- **Sound Alerts**: Audio notifications for important messages
- **Notification Types**: Info, Warning, Error, Success
- **Read/Unread Status**: Track notification status
- **Filtering**: Filter by type and read status

### Document Management

Centralized document storage and tracking:

- **Document Types**: CSCS, H&S certificates, Insurance, CPP, RAMS
- **Upload Support**: Upload documents with metadata
- **Expiry Tracking**: Automatic expiry date monitoring
- **Reminders**: Notifications for expiring documents
- **Verification**: Admin review and approval workflow

### Multi-Tenancy

The system supports multiple companies operating independently:

- **Company Isolation**: Data is isolated by company_id
- **Superadmin Access**: Superadmins can access all companies
- **Company Invitations**: Invite users to join companies
- **Role-based Access**: Permissions based on role and company

---

## 🎨 Design System

### Color Scheme

- **Primary 700** (Dark Purple): `#4a026f`
  - Used for: Buttons, headers, interactive elements
  
- **Primary 500** (Light Purple): `#897c98`
  - Used for: Backgrounds, highlights, secondary buttons
  
- **Secondary 500** (Grey): `#707173`
  - Used for: Text, icons, borders

### Design Principles

- **Clean & Modern**: Minimalist interface with clear hierarchy
- **Consistent Spacing**: Uniform padding and margins
- **Professional Appearance**: Trustworthy and business-appropriate
- **Cross-platform Compatible**: Works seamlessly on all platforms
- **Accessibility-focused**: WCAG-compliant components

---

## 🔧 Development

### Running in Development Mode

**Backend:**
```bash
cd backend
npm run dev  # Uses nodemon for auto-restart
```

**Flutter Apps:**
```bash
cd apps/admin_app  # or staff_app
flutter run
```

### Database Migrations

Migrations are located in `backend/migrations/`. Run them in order:

```bash
node migrations/add_chat_tables.js
node migrations/add_message_read_status.js
# ... etc
```

### Code Structure

- **Features**: Organized by feature modules
- **Shared Code**: Common logic in `packages/shared`
- **API Services**: Centralized in `packages/shared/lib/core/services`
- **State Management**: Provider pattern throughout
- **Models**: Data models in `packages/shared/lib/core/models`

### Testing

```bash
# Run Flutter tests
cd apps/admin_app
flutter test

# Run backend tests (if implemented)
cd backend
npm test
```

---

## 📝 License

[Specify your license here]

---

## 🤝 Contributing

[Contributing guidelines if applicable]

---

## 📧 Support

For support, please contact [your contact information]

---

## 🔄 Recent Updates

### Chat Feature (Latest)
- Real-time messaging with Socket.io
- Direct, group, and project-based conversations
- File attachments and typing indicators
- Message read status tracking

### Notification System
- Push notifications with sound alerts
- Multiple notification types
- Read/unread status tracking

### Multi-tenant Architecture
- Company-based data isolation
- Superadmin access controls
- Company invitation system

---

**Built with ❤️ for efficient workforce management**