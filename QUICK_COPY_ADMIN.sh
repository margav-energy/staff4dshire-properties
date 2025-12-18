#!/bin/bash
# Quick copy script for admin app migration
# Run: bash QUICK_COPY_ADMIN.sh

cd "C:/Users/User/Desktop/Staff4dshire Properties"

echo "Creating directories..."
mkdir -p apps/admin_app/lib/features/{auth/{screens,widgets},dashboard/{screens,widgets},users/screens,companies/screens,projects/screens,invoices/screens,jobs/{screens,widgets},reports/screens,settings/screens,onboarding/screens,notifications/screens,inductions/screens}

echo "Copying auth features..."
cp mobile/lib/features/auth/screens/login_screen.dart apps/admin_app/lib/features/auth/screens/ 2>/dev/null || echo "Login screen already exists"
cp mobile/lib/features/auth/screens/invitation_register_screen.dart apps/admin_app/lib/features/auth/screens/ 2>/dev/null || echo "Invitation register already exists"
cp mobile/lib/features/auth/widgets/* apps/admin_app/lib/features/auth/widgets/ 2>/dev/null || echo "Auth widgets copied or missing"

echo "Copying dashboard features..."
cp mobile/lib/features/dashboard/screens/admin_dashboard_screen.dart apps/admin_app/lib/features/dashboard/screens/ 2>/dev/null || echo "Admin dashboard already exists"
cp mobile/lib/features/dashboard/screens/superadmin_dashboard_screen.dart apps/admin_app/lib/features/dashboard/screens/ 2>/dev/null || echo "Superadmin dashboard already exists"
cp mobile/lib/features/dashboard/widgets/* apps/admin_app/lib/features/dashboard/widgets/ 2>/dev/null || echo "Dashboard widgets copied or missing"

echo "Copying other admin features..."
cp -r mobile/lib/features/users/* apps/admin_app/lib/features/users/ 2>/dev/null || echo "Users feature copied or missing"
cp -r mobile/lib/features/companies/* apps/admin_app/lib/features/companies/ 2>/dev/null || echo "Companies feature copied or missing"
cp -r mobile/lib/features/projects/* apps/admin_app/lib/features/projects/ 2>/dev/null || echo "Projects feature copied or missing"
cp -r mobile/lib/features/invoices/* apps/admin_app/lib/features/invoices/ 2>/dev/null || echo "Invoices feature copied or missing"
cp -r mobile/lib/features/jobs/* apps/admin_app/lib/features/jobs/ 2>/dev/null || echo "Jobs feature copied or missing"
cp -r mobile/lib/features/reports/* apps/admin_app/lib/features/reports/ 2>/dev/null || echo "Reports feature copied or missing"
cp -r mobile/lib/features/settings/* apps/admin_app/lib/features/settings/ 2>/dev/null || echo "Settings feature copied or missing"
cp -r mobile/lib/features/onboarding/* apps/admin_app/lib/features/onboarding/ 2>/dev/null || echo "Onboarding feature copied or missing"
cp -r mobile/lib/features/notifications/* apps/admin_app/lib/features/notifications/ 2>/dev/null || echo "Notifications feature copied or missing"
cp -r mobile/lib/features/inductions/* apps/admin_app/lib/features/inductions/ 2>/dev/null || echo "Inductions feature copied or missing"

echo "Copying additional providers to shared package..."
cp mobile/lib/core/providers/invoice_provider.dart packages/shared/lib/core/providers/ 2>/dev/null || echo "Invoice provider already exists"
cp mobile/lib/core/providers/job_completion_provider.dart packages/shared/lib/core/providers/ 2>/dev/null || echo "Job completion provider already exists"
cp mobile/lib/core/providers/onboarding_provider.dart packages/shared/lib/core/providers/ 2>/dev/null || echo "Onboarding provider already exists"
cp mobile/lib/core/providers/notification_provider.dart packages/shared/lib/core/providers/ 2>/dev/null || echo "Notification provider already exists"

echo "Done! Next steps:"
echo "1. Fix import paths in copied files"
echo "2. Update packages/shared/lib/shared.dart to export new providers"
echo "3. Create admin router"
echo "4. Update apps/admin_app/lib/main.dart"



