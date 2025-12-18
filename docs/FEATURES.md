# Staff4dshire Properties - Feature Documentation

## Core Features

### 1. Sign In/Out System
**One-tap sign in/out with GPS and timestamp**

#### Mobile App
- Quick access button on dashboard
- GPS location capture on sign-in
- Automatic timestamp recording
- Visual status indicator
- Project selection required before sign-in

#### Web App
- Similar interface for web access
- Location capture via browser geolocation API
- Real-time clock display
- Sign-in/out history tracking

#### Data Captured
- User ID
- Project/Site ID
- GPS Coordinates (latitude, longitude)
- Timestamp (sign-in and sign-out)
- Device information

---

### 2. Project/Site Selection
**Dynamic project selection before sign-in**

#### Features
- List of active projects
- Project details (name, address, description)
- Search and filter capabilities
- Recent projects quick access
- Project-specific requirements display

---

### 3. Automatic Weekly Timesheets
**Automated timesheet generation from sign-in/out data**

#### Features
- Automatic calculation of hours worked
- Weekly view with day-by-day breakdown
- Daily hours summary
- Total weekly hours
- Time entry details:
  - Sign-in time
  - Sign-out time
  - Project name
  - Location
  - Duration

#### Export Options
- PDF format (formatted document)
- Excel format (.xlsx)
- CSV format (for import into other systems)

---

### 4. Daily Fit-to-Work Declarations
**Health and safety compliance declarations**

#### Features
- Daily declaration required
- Binary choice: Fit / Not Fit
- Optional notes field
- Submission timestamp
- Compliance tracking

#### Workflow
1. User opens fit-to-work screen
2. Selects fit/not fit status
3. Optionally adds notes
4. Submits declaration
5. System records timestamp

---

### 5. Digital RAMS Sign-Off
**Risk Assessment and Method Statement digital signing**

#### Features
- RAMS document list by project
- Version tracking
- Digital signature/acknowledgment
- Sign-off timestamp
- Document viewing capability
- Compliance status tracking

---

### 6. Toolbox Talk Attendance Tracking
**Safety briefing attendance management**

#### Features
- Scheduled toolbox talks
- Attendance marking
- Digital signature/confirmation
- Talk details:
  - Title
  - Date and time
  - Location
  - Project association
- Attendance history

---

### 7. Document Hub
**Centralized document management**

#### Document Types
- **CSCS Cards**: Construction Skills Certification Scheme
- **Health & Safety Certificates**: H&S training and certifications
- **Insurance Documents**: Insurance coverage documents
- **CPP**: Construction Phase Plan
- **RAMS**: Risk Assessment and Method Statement
- **Other**: Miscellaneous documents

#### Features
- Document upload
- Document viewing
- Expiry date tracking
- Expiry reminders (30 days before)
- Document verification status
- Filter by document type
- Search functionality
- Download capability

---

### 8. Supervisor Tools
**Enhanced tools for supervisors**

#### Live Headcount
- Real-time count of staff on site
- Filter by project
- Last update timestamp

#### Fire Roll Call
- Emergency evacuation management
- Mark staff as accounted for
- Generate roll call report

#### Approve/Edit Times
- Review timesheet submissions
- Approve or reject entries
- Edit incorrect entries
- Add notes/comments
- Bulk approval capability

---

### 9. Admin Dashboard
**Comprehensive administration tools**

#### Attendance Reports
- Daily, weekly, monthly reports
- Project-based filtering
- Staff-based filtering
- Export capabilities
- Attendance trends and analytics

#### Timesheet Exports
- Bulk export for payroll
- Custom date range selection
- Filter by project, staff, status
- Multiple format support (PDF, Excel, CSV)

#### Induction Management
- Track staff inductions
- Schedule new inductions
- Induction completion tracking
- Certificate generation

#### Additional Admin Features
- User management (add, edit, remove)
- Project management
- Role management
- System settings
- Compliance monitoring
- Document verification

---

## Optional Features (Future Enhancements)

### Geofencing
- Define project boundaries
- Automatic sign-in when entering geofence
- Notifications when outside geofence
- Location verification

### Photo Sign-In
- Optional photo capture on sign-in
- Face verification
- Selfie requirement
- Photo storage and management

### AI Document Reading
- Automatic extraction of document details
- Expiry date detection
- Certificate number extraction
- Document classification
- Data validation

---

## User Roles

### Staff
- Sign in/out
- View own timesheet
- Submit fit-to-work declarations
- Sign RAMS documents
- Mark toolbox talk attendance
- Upload and view documents
- View own dashboard

### Supervisor
- All staff permissions
- View live headcount
- Conduct fire roll call
- Approve/edit timesheets
- View team reports
- Manage toolbox talks

### Admin
- All supervisor permissions
- Full user management
- Project management
- System-wide reports
- Timesheet exports
- Induction management
- System configuration
- Document verification
- Compliance oversight

---

## Data Flow

### Sign-In Process
1. User opens sign-in screen
2. Selects project
3. System captures GPS location
4. System records timestamp
5. Creates timesheet entry
6. Updates live headcount

### Sign-Out Process
1. User opens sign-out screen
2. System captures GPS location
3. System records timestamp
4. Updates timesheet entry
5. Calculates hours worked
6. Updates live headcount

### Timesheet Generation
1. System aggregates sign-in/out entries
2. Calculates durations
3. Groups by project
4. Organizes by date
5. Displays in weekly view
6. Allows export

---

## Security & Compliance

### Data Security
- Encrypted data transmission
- Secure authentication
- Role-based access control
- Audit logging

### Compliance
- GDPR compliant data handling
- Document retention policies
- Data export capabilities
- Privacy controls

