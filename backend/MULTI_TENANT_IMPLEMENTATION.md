# Multi-Tenant Implementation Guide

## Overview
This document outlines the multi-tenant architecture implementation that allows separate companies to use the app with isolated data.

## Architecture

### Roles
- **Superadmin**: Can access all companies, create companies, and manage superadmin users
- **Admin** (Company Admin): Can only manage users, projects, and data within their own company
- **Supervisor**: Company-scoped supervisor
- **Staff**: Company-scoped staff member

### Database Changes

1. **Companies Table**: Stores company/organization information
2. **Company ID Columns**: Added `company_id` to all data tables:
   - users
   - projects
   - time_entries
   - documents
   - job_completions
   - invoices
   - incidents
   - notifications
   - etc.

3. **User Table Updates**:
   - Added `company_id` column
   - Added `is_superadmin` boolean flag
   - Updated role constraint to include 'superadmin'

## Migration Steps

### 1. Run Database Migration
```bash
cd backend
psql -U staff4dshire -d staff4dshire -f schema_multi_tenant.sql
```

### 2. Create a Superadmin User

Run this SQL to create your first superadmin:
```sql
INSERT INTO companies (id, name, is_active)
VALUES ('00000000-0000-0000-0000-000000000000'::UUID, 'System Admin', TRUE);

INSERT INTO users (
    id, 
    email, 
    password_hash, 
    first_name, 
    last_name, 
    role, 
    is_superadmin, 
    company_id
)
VALUES (
    gen_random_uuid(),
    'superadmin@staff4dshire.com',
    '$2b$10$YourHashedPasswordHere', -- Hash your password with bcrypt
    'Super',
    'Admin',
    'superadmin',
    TRUE,
    NULL -- Superadmins don't need a company_id
);
```

### 3. Create Companies

Superadmins can create companies via the API:
```javascript
POST /api/companies
{
  "name": "Acme Construction Ltd",
  "domain": "acme.com",
  "address": "123 Construction St",
  "email": "admin@acme.com",
  "subscription_tier": "premium",
  "max_users": 100
}
```

### 4. Create Company Admins

Once a company exists, create admin users for that company:
```javascript
POST /api/users?userId=<superadmin_user_id>
{
  "email": "admin@acme.com",
  "password_hash": "$2b$10$...",
  "first_name": "Company",
  "last_name": "Admin",
  "role": "admin",
  "company_id": "<company_id_from_step_3>"
}
```

## API Changes

### User Endpoints
- All GET endpoints now filter by `company_id` unless user is superadmin
- POST /api/users now accepts `company_id` parameter
- Users can only be created within their company (or by superadmin)

### New Company Endpoints
- `GET /api/companies` - List all companies (superadmin only)
- `GET /api/companies/:id` - Get company details
- `POST /api/companies` - Create company (superadmin only)
- `PUT /api/companies/:id` - Update company (superadmin or company admin)
- `DELETE /api/companies/:id` - Delete company (superadmin only)

### Filtering Middleware
The `companyFilter.js` middleware automatically filters data by company_id:
- Superadmins: See all data
- Regular users: See only their company's data

## Mobile App Changes

### Updated Models
- `UserModel` now includes `companyId` and `isSuperadmin`
- `User` class in `AuthProvider` includes these fields

### Updated UserRole Enum
Added `superadmin` role:
```dart
enum UserRole { staff, supervisor, admin, superadmin }
```

### UI Updates Needed
1. **Company Management Screen** (Superadmin only)
   - List all companies
   - Create/edit/delete companies
   - View company statistics

2. **User Management Screen**
   - Filter users by company (superadmin)
   - Show company name next to user
   - Company admins only see their own company's users

3. **Company Selection** (Superadmin)
   - Add company selector when viewing data
   - Allow switching between companies

## Next Steps

1. ✅ Database schema migration
2. ✅ Backend API routes with company filtering
3. ✅ Models updated with companyId
4. ⏳ Update all User() constructors in AuthProvider to include companyId
5. ⏳ Create Company Management UI for superadmin
6. ⏳ Update User Management UI to respect company isolation
7. ⏳ Update all data queries (projects, timesheets, etc.) to filter by company
8. ⏳ Add authentication middleware to set req.user from JWT/session

## Testing

1. Test that superadmins can see all companies
2. Test that company admins only see their company's data
3. Test that data is properly isolated between companies
4. Test company creation/deletion
5. Test user creation with company assignment

## Security Notes

- Always validate company_id on the backend
- Never trust client-sent company_id values
- Use middleware to automatically filter queries
- Superadmins should have audit logging for company-level actions



