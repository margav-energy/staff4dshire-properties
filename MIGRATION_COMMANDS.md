# Migration Commands - Run These Yourself

## Step 1: Copy Login Screen

```bash
cd "C:/Users/User/Desktop/Staff4dshire Properties"

# Create directories for auth features
mkdir -p apps/admin_app/lib/features/auth/screens
mkdir -p apps/admin_app/lib/features/auth/widgets

# Copy login screen (shared, but we'll customize later)
cp mobile/lib/features/auth/screens/login_screen.dart apps/admin_app/lib/features/auth/screens/
cp mobile/lib/features/auth/screens/invitation_register_screen.dart apps/admin_app/lib/features/auth/screens/
cp mobile/lib/features/auth/widgets/welcome_dialog.dart apps/admin_app/lib/features/auth/widgets/

# Update imports in login_screen.dart (we'll need to fix these)
```

## Step 2: Copy Admin-Specific Features

```bash
# Dashboard screens
mkdir -p apps/admin_app/lib/features/dashboard/screens
mkdir -p apps/admin_app/lib/features/dashboard/widgets
cp -r mobile/lib/features/dashboard/screens/admin_dashboard_screen.dart apps/admin_app/lib/features/dashboard/screens/
cp -r mobile/lib/features/dashboard/screens/superadmin_dashboard_screen.dart apps/admin_app/lib/features/dashboard/screens/
cp -r mobile/lib/features/dashboard/widgets/* apps/admin_app/lib/features/dashboard/widgets/

# User management
mkdir -p apps/admin_app/lib/features/users/screens
cp -r mobile/lib/features/users/* apps/admin_app/lib/features/users/

# Company management
mkdir -p apps/admin_app/lib/features/companies/screens
cp -r mobile/lib/features/companies/* apps/admin_app/lib/features/companies/

# Project management
mkdir -p apps/admin_app/lib/features/projects/screens
cp -r mobile/lib/features/projects/* apps/admin_app/lib/features/projects/

# Invoice management
mkdir -p apps/admin_app/lib/features/invoices/screens
cp -r mobile/lib/features/invoices/* apps/admin_app/lib/features/invoices/

# Job approvals (admin only)
mkdir -p apps/admin_app/lib/features/jobs/screens
cp -r mobile/lib/features/jobs/* apps/admin_app/lib/features/jobs/

# Reports
mkdir -p apps/admin_app/lib/features/reports/screens
cp -r mobile/lib/features/reports/* apps/admin_app/lib/features/reports/

# Settings
mkdir -p apps/admin_app/lib/features/settings/screens
cp -r mobile/lib/features/settings/* apps/admin_app/lib/features/settings/
```

## Step 3: Copy Additional Needed Features

```bash
# Onboarding (admin manages these)
mkdir -p apps/admin_app/lib/features/onboarding/screens
cp -r mobile/lib/features/onboarding/* apps/admin_app/lib/features/onboarding/

# Notifications
mkdir -p apps/admin_app/lib/features/notifications/screens
cp -r mobile/lib/features/notifications/* apps/admin_app/lib/features/notifications/

# Inductions
mkdir -p apps/admin_app/lib/features/inductions/screens
cp -r mobile/lib/features/inductions/* apps/admin_app/lib/features/inductions/
```

## Step 4: Copy Supporting Files

```bash
# Copy any file_io_stub files needed
cp mobile/lib/features/auth/screens/file_io_stub.dart apps/admin_app/lib/features/auth/screens/ 2>/dev/null || true
cp mobile/lib/features/jobs/widgets/file_io_stub.dart apps/admin_app/lib/features/jobs/widgets/ 2>/dev/null || true

# Copy any image/file picker utilities if they exist
```

## Step 5: Copy Additional Providers Needed

```bash
# Copy providers that admin app will need
cp mobile/lib/core/providers/project_provider.dart packages/shared/lib/core/providers/ 2>/dev/null || echo "Already copied"
cp mobile/lib/core/providers/invoice_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/job_completion_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/onboarding_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/notification_provider.dart packages/shared/lib/core/providers/
```

## Step 6: Copy Additional Models Needed

```bash
# Copy any missing models
cp mobile/lib/core/models/invoice_model.dart packages/shared/lib/core/models/ 2>/dev/null || echo "Already exists"
cp mobile/lib/core/models/job_completion_model.dart packages/shared/lib/core/models/ 2>/dev/null || echo "Already exists"
cp mobile/lib/core/models/onboarding_model.dart packages/shared/lib/core/models/ 2>/dev/null || echo "Already exists"
cp mobile/lib/core/models/cis_onboarding_model.dart packages/shared/lib/core/models/ 2>/dev/null || echo "Already exists"
cp mobile/lib/core/models/incident_model.dart packages/shared/lib/core/models/ 2>/dev/null || echo "Already exists"
cp mobile/lib/core/models/document_model.dart packages/shared/lib/core/models/ 2>/dev/null || echo "Already exists"
```

## Step 7: Copy Additional Services Needed

```bash
# Copy any missing services
cp mobile/lib/core/services/project_api_service.dart packages/shared/lib/core/services/ 2>/dev/null || echo "Check if exists"
cp mobile/lib/core/services/invoice_api_service.dart packages/shared/lib/core/services/ 2>/dev/null || echo "Check if exists"
cp mobile/lib/core/services/photo_sync_service.dart packages/shared/lib/core/services/ 2>/dev/null || echo "Check if exists"
```

## Step 8: Update Shared Package Exports

After copying, you'll need to update `packages/shared/lib/shared.dart` to export new providers/models.

## Step 9: Create Admin Router

After copying files, create the router. I'll provide the router code separately.

## Step 10: Fix Import Paths

After copying, you'll need to fix import paths in all copied files:
- Change `../../../core/` to `package:staff4dshire_shared/shared.dart` where appropriate
- Update relative imports to use shared package

## Quick Copy All (Run This First)

```bash
cd "C:/Users/User/Desktop/Staff4dshire Properties"

# Create all directories first
mkdir -p apps/admin_app/lib/features/{auth/{screens,widgets},dashboard/{screens,widgets},users/screens,companies/screens,projects/screens,invoices/screens,jobs/{screens,widgets},reports/screens,settings/screens,onboarding/screens,notifications/screens,inductions/screens}

# Copy features (this will take a while)
cp -r mobile/lib/features/auth/screens/login_screen.dart apps/admin_app/lib/features/auth/screens/
cp -r mobile/lib/features/auth/screens/invitation_register_screen.dart apps/admin_app/lib/features/auth/screens/
cp -r mobile/lib/features/auth/widgets/* apps/admin_app/lib/features/auth/widgets/ 2>/dev/null || true

cp -r mobile/lib/features/dashboard/screens/admin_dashboard_screen.dart apps/admin_app/lib/features/dashboard/screens/
cp -r mobile/lib/features/dashboard/screens/superadmin_dashboard_screen.dart apps/admin_app/lib/features/dashboard/screens/
cp -r mobile/lib/features/dashboard/widgets/* apps/admin_app/lib/features/dashboard/widgets/ 2>/dev/null || true

cp -r mobile/lib/features/users/* apps/admin_app/lib/features/users/
cp -r mobile/lib/features/companies/* apps/admin_app/lib/features/companies/
cp -r mobile/lib/features/projects/* apps/admin_app/lib/features/projects/
cp -r mobile/lib/features/invoices/* apps/admin_app/lib/features/invoices/
cp -r mobile/lib/features/jobs/* apps/admin_app/lib/features/jobs/
cp -r mobile/lib/features/reports/* apps/admin_app/lib/features/reports/
cp -r mobile/lib/features/settings/* apps/admin_app/lib/features/settings/
cp -r mobile/lib/features/onboarding/* apps/admin_app/lib/features/onboarding/
cp -r mobile/lib/features/notifications/* apps/admin_app/lib/features/notifications/
cp -r mobile/lib/features/inductions/* apps/admin_app/lib/features/inductions/

echo "Files copied! Now you'll need to fix import paths."
```

## After Copying

1. Fix import paths in all copied files
2. Update `packages/shared/lib/shared.dart` 
3. Create admin router
4. Update `apps/admin_app/lib/main.dart` to use the router

I'll provide the router code and import fixes after you run the copy commands.



