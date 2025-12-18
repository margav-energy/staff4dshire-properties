# Next Steps for Monorepo Completion

## Immediate Actions

### 1. Test Shared Package
```bash
cd packages/shared
flutter pub get
```
- Check for any missing dependencies
- Fix import paths if needed
- Ensure package builds successfully

### 2. Test Admin App
```bash
cd apps/admin_app
flutter pub get
flutter run
```
- Should show basic "Admin Login" screen
- Verify shared package imports work

### 3. Test Staff App
```bash
cd apps/staff_app
flutter pub get
flutter run
```
- Should show basic "Staff Login" screen
- Verify shared package imports work

## Feature Migration Plan

### Admin App Priority
1. **Authentication** - Copy login/register screens (shared auth, but separate UI)
2. **Dashboard** - Copy admin_dashboard_screen and superadmin_dashboard_screen
3. **User Management** - Copy all user management features
4. **Company Management** - Copy company features
5. **Project Management** - Copy project CRUD features
6. **Invoices** - Copy invoice management
7. **Reports** - Copy reporting features

### Staff App Priority
1. **Authentication** - Copy login/register screens
2. **Dashboard** - Copy staff_dashboard_screen and supervisor_dashboard_screen
3. **Sign In/Out** - Copy sign_in_out_screen
4. **Timesheets** - Copy timesheet features
5. **Documents** - Copy document hub
6. **Compliance** - Copy compliance forms
7. **Jobs** - Copy job completion features

## Important Notes

- Both apps use the **same backend API**
- Both apps use **shared authentication** (same AuthProvider)
- Users are redirected to the correct app based on role
- Old `mobile/` app can serve as reference during migration
- Keep both apps working during migration

## Questions to Resolve

1. Should we keep the old `mobile/` app for reference?
2. How should we handle users who have both roles? (e.g., supervisor who is also admin)
3. Should we create separate app store listings?
4. How do we handle deep linking between apps? (probably not needed)



