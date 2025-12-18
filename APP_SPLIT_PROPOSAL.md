# App Split Proposal: Admin vs Staff Apps

## Overview
Split the current single app into two specialized applications:
1. **Admin Portal** - For admins and superadmins
2. **Staff App** - For staff and supervisors

## Benefits

### ✅ Advantages

1. **Focused User Experience**
   - Admin app: Complex management interfaces, analytics, settings
   - Staff app: Simple, streamlined daily operations

2. **Security & Access Control**
   - Admin app: Stricter security, audit logs, sensitive operations
   - Staff app: Limited permissions, focused on work tasks

3. **Performance**
   - Smaller apps = faster load times
   - Admin app can be heavier with analytics/charts
   - Staff app optimized for speed and offline capability

4. **Independent Deployment**
   - Update staff app without affecting admin workflows
   - Different release cycles
   - Admin features can iterate faster

5. **Code Maintainability**
   - Clear separation of concerns
   - Easier to onboard new developers
   - Less conditional logic (role-based hiding/showing)

6. **Better Multi-Tenancy**
   - Admin app handles company setup/invitations
   - Staff app is just for work (simpler onboarding)

## Proposed Architecture

### Option 1: Monorepo with Shared Package (Recommended)
```
Staff4dshire Properties/
├── packages/
│   └── shared/              # Shared code
│       ├── lib/
│       │   ├── core/        # Models, services, providers
│       │   ├── api/         # API clients
│       │   └── utils/       # Utilities
│       └── pubspec.yaml
├── apps/
│   ├── admin_app/           # Admin/Superadmin app
│   │   ├── lib/
│   │   │   ├── features/    # Admin-specific features
│   │   │   ├── main_admin.dart
│   │   │   └── router_admin.dart
│   │   └── pubspec.yaml
│   └── staff_app/           # Staff/Supervisor app
│       ├── lib/
│       │   ├── features/    # Staff-specific features
│       │   ├── main_staff.dart
│       │   └── router_staff.dart
│       └── pubspec.yaml
└── backend/                 # Unchanged
```

### Option 2: Flutter Flavors (Simpler)
```
mobile/
├── lib/
│   ├── features/
│   │   ├── admin/           # Admin-only features
│   │   ├── staff/           # Staff-only features
│   │   └── shared/          # Shared features
│   ├── main_admin.dart      # Admin entry point
│   ├── main_staff.dart      # Staff entry point
│   └── app_router_admin.dart
├── android/
│   └── app/
│       └── build.gradle     # Flavor configs
└── ios/
    └── Flutter/             # Flavor configs
```

## Feature Distribution

### Admin Portal Features
- ✅ Company management (multi-tenancy)
- ✅ User management (CRUD)
- ✅ Project management (full control)
- ✅ Invoice management & payments
- ✅ Reports & analytics
- ✅ Job completion approvals
- ✅ System settings
- ✅ Onboarding management
- ✅ Document verification
- ✅ Audit logs
- ✅ Invitation system

### Staff App Features
- ✅ Sign in/out (time tracking)
- ✅ Timesheet viewing (own entries)
- ✅ Document upload (own documents)
- ✅ Compliance forms (fit-to-work, RAMS)
- ✅ Toolbox talk attendance
- ✅ Fire roll call (supervisors)
- ✅ Job completion submission
- ✅ Incident reporting
- ✅ Project selection
- ✅ Notifications (work-related)

### Shared Components
- ✅ Authentication (login/logout)
- ✅ User models & providers
- ✅ API services
- ✅ Theme & styling
- ✅ Core utilities
- ✅ Photo handling

## Implementation Plan

### Phase 1: Setup Structure
1. Create shared package or organize shared code
2. Set up Flutter flavors OR separate app projects
3. Configure build scripts for both apps

### Phase 2: Split Features
1. Move admin-specific screens to admin app
2. Move staff-specific screens to staff app
3. Extract shared code to common package

### Phase 3: Separate Routing
1. Create admin-specific router
2. Create staff-specific router
3. Remove role-based routing logic

### Phase 4: Build Configuration
1. Configure Android flavors/separate apps
2. Configure iOS schemes/separate targets
3. Set up CI/CD for both apps

### Phase 5: Testing & Polish
1. Test admin app independently
2. Test staff app independently
3. Verify shared code works in both
4. Update documentation

## Recommendations

### I recommend **Option 1 (Monorepo with Shared Package)** because:
- ✅ Best code reusability
- ✅ Clear separation
- ✅ Easy to maintain
- ✅ Scales well
- ✅ Industry standard approach

### Alternative: Start with **Option 2 (Flavors)** if:
- You want faster initial split
- Don't want to restructure too much yet
- Can migrate to monorepo later

## Migration Strategy

1. **Keep current app working** during migration
2. **Start with staff app** (simpler, test it first)
3. **Then create admin app** (extract admin features)
4. **Share authentication** so users use correct app
5. **Deploy both** and redirect based on role

## Questions to Consider

1. **Should both apps share the same login?**
   - Option A: Same backend, different frontends (recommended)
   - Option B: Separate authentication endpoints

2. **App naming:**
   - Admin: "Staff4dshire Admin" / "Staff4dshire Portal"
   - Staff: "Staff4dshire" / "Staff4dshire Field"

3. **Store listings:**
   - Two separate apps on Play Store/App Store
   - Or one app with different entry points?

## Next Steps

1. Choose architecture (Monorepo vs Flavors)
2. Create shared package structure
3. Begin splitting features
4. Test both apps independently
5. Deploy separately

Would you like me to proceed with implementing this split? I can start with whichever option you prefer.


