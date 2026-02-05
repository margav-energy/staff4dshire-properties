# Default Login Credentials

These are the default credentials created automatically when the database is seeded. **These are for demonstration purposes only.**

## 🔴 Superadmin Account

**Full Access - Can manage all companies and users**

- **Email**: `superadmin@staff4dshire.com`
- **Password**: `Admin123!`
- **Role**: Superadmin
- **Access**: All companies, all features

## 🟢 Admin Account

**Company Admin - Can manage company, users, and projects**

- **Email**: `admin@staff4dshire.com`
- **Password**: `Admin123!`
- **Role**: Admin
- **Company**: Demo Company
- **Access**: Full company management, user management, project management

## 🟡 Supervisor Account

**Supervisor - Can manage team and approve timesheets**

- **Email**: `supervisor@staff4dshire.com`
- **Password**: `Supervisor123!`
- **Role**: Supervisor
- **Company**: Demo Company
- **Access**: Team management, timesheet approval, live headcount, fire roll call

## 🔵 Staff Account

**Field Staff - Basic user access**

- **Email**: `staff@staff4dshire.com`
- **Password**: `Staff123!`
- **Role**: Staff
- **Company**: Demo Company
- **Access**: Sign in/out, view timesheet, upload documents, compliance forms

---

## 📝 Notes

1. **These credentials are created automatically** when `SEED_DATABASE=true` is set in environment variables
2. **Change these passwords immediately** in production
3. The seeding script only runs if the database is empty (no users exist)
4. To re-seed, delete all users first or set `FORCE_SEED=true`

## 🎯 Quick Test Login

For stakeholder demonstration, use:
- **Admin App**: Login with `admin@staff4dshire.com` / `Admin123!`
- **Staff App**: Login with `staff@staff4dshire.com` / `Staff123!`

## 🔒 Security Warning

⚠️ **DO NOT use these credentials in production!**

These are default demo credentials. Always:
1. Change passwords after first login
2. Create new users with secure passwords
3. Disable seeding in production (`SEED_DATABASE=false`)
