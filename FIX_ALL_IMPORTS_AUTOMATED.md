# Automated Import Fix Guide

## Critical Router Fixes
✅ Router fixed - now loads User/Project objects from providers

## Remaining Import Issues

All files need to replace relative imports with shared package imports:

### Pattern to Fix:
**OLD:** `import '../../../core/providers/auth_provider.dart';`
**NEW:** `import 'package:staff4dshire_shared/shared.dart';`

**OLD:** `import '../../../core/models/user_model.dart';`
**NEW:** `import 'package:staff4dshire_shared/shared.dart';`

## Quick Fix Steps

### Step 1: Add Missing Exports to Shared Package
Check `packages/shared/lib/shared.dart` - we need to add exports for:
- All models (Project, Invoice, JobCompletion, etc.)
- All providers (TimesheetProvider, DocumentProvider, etc.)
- All utilities (UKData, etc.)
- All services

### Step 2: Use Find & Replace in IDE

In VS Code or Android Studio:

1. **Find:** `import\s+['"]\.\.\/\.\.\/\.\.\/core\/(providers|models|services|utils|config)\/[^'"]+['"];`
2. **Replace with:** `import 'package:staff4dshire_shared/shared.dart';`
3. **Enable Regex mode** in find/replace

This will replace all relative core imports with the shared package.

### Step 3: Remove Duplicate Imports

After replacing, you may have multiple `import 'package:staff4dshire_shared/shared.dart';` lines. Keep only one.

## Missing Exports

We need to add to `packages/shared/lib/shared.dart`:
- Models: Invoice, JobCompletion, NotificationItem, Document, TimeEntry, etc.
- Providers: TimesheetProvider, DocumentProvider, IncidentProvider, NotificationProvider, LocationProvider, XeroProvider
- Services: CompanyInvitationApiService, TimesheetExportService
- Utils: UKData
- Types: ProjectType, UserRole, NotificationType, DocumentType

## Files That Need Manual Fixes

Some files reference providers/models that don't exist in shared yet. These need to be added to the shared package first.



