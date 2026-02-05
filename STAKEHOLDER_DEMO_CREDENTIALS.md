# Stakeholder Demo - Quick Login Guide

## 🎯 Quick Access for Stakeholders

Use these credentials to log in and explore the application:

### Admin App (Management Interface)
**URL**: `https://your-admin-app.onrender.com`

**Login Credentials:**
- **Email**: `admin@staff4dshire.com`
- **Password**: `Admin123!`

**What you can see:**
- Company management
- User management
- Project management
- Reports and analytics
- Timesheet exports
- Full administrative features

---

### Staff App (Field Worker Interface)
**URL**: `https://your-staff-app.onrender.com`

**Login Credentials:**
- **Email**: `staff@staff4dshire.com`
- **Password**: `Staff123!`

**What you can see:**
- Sign in/out functionality
- Personal timesheet
- Document upload
- Compliance forms
- Chat/messaging
- Notifications

---

### Supervisor Account (Team Management)
**Login Credentials:**
- **Email**: `supervisor@staff4dshire.com`
- **Password**: `Supervisor123!`

**What you can see:**
- All staff features, plus:
- Live headcount
- Fire roll call
- Timesheet approval
- Team management

---

### Superadmin Account (Full System Access)
**Login Credentials:**
- **Email**: `superadmin@staff4dshire.com`
- **Password**: `Admin123!`

**What you can see:**
- Access to all companies
- System-wide administration
- All features across all companies

---

## 📱 Testing Different Roles

1. **Test as Admin**: See management features, user creation, project setup
2. **Test as Staff**: Experience field worker interface, sign in/out, timesheet
3. **Test as Supervisor**: View team management, approvals, headcount
4. **Test as Superadmin**: See multi-tenant capabilities

## 🔍 Demo Scenarios

### Scenario 1: Time Tracking
1. Log in as Staff
2. Go to Sign In/Out
3. Select a project
4. Sign in (GPS location captured)
5. View timesheet to see entry

### Scenario 2: User Management
1. Log in as Admin
2. Go to Users
3. Create a new user
4. Assign to a project
5. View user details

### Scenario 3: Project Management
1. Log in as Admin
2. Go to Projects
3. Create a new project
4. Assign staff members
5. View project details

### Scenario 4: Chat/Communication
1. Log in as Staff
2. Go to Chat
3. Start a conversation
4. Send messages
5. See real-time updates

## ⚠️ Important Notes

- These are **demo credentials only**
- Data is shared across all demo users
- Changes made during demo will be visible to other users
- For production, these credentials should be changed

## 🆘 Troubleshooting

**Can't log in?**
- Check that the backend is running
- Verify the API URL is correct
- Check browser console for errors

**No data showing?**
- Database seeding runs automatically on first deployment
- If no users exist, seeding will create them
- Check backend logs for seeding confirmation

**Need to reset?**
- Delete all users from database to trigger re-seeding
- Or manually run the seed script

---

**Ready to demo!** 🚀
