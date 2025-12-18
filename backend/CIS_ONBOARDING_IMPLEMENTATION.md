# CIS Subcontractor Onboarding Implementation

## Overview
A streamlined onboarding form specifically for CIS Subcontractors / Site Starters has been implemented. This is a simplified version compared to the full employee onboarding form.

## Database Schema
Created `schema_cis_onboarding.sql` with the `cis_onboarding` table containing all fields from the form:
- Basic Details (name, trade, site, start date, supervisor, mobile, email)
- CIS / Company Details (status, UTR, CIS status, company info, bank details)
- Right to Work & CSCS
- Key Tickets
- Emergency Contact
- Medical (Basic)
- Quick Site Induction (Manager section)
- Declaration (with signatures)

## API Routes (`/api/onboarding`)
- `GET /cis/:userId` - Get CIS onboarding data for a user
- `POST /cis` - Save/update CIS onboarding data

## Mobile App Components

### Models
- `CisOnboarding` - Data model for CIS onboarding

### Provider
- `OnboardingProvider` - Extended with CIS onboarding methods:
  - `loadCisOnboarding(userId)`
  - `saveCisOnboarding(onboarding)`

### Screen
- `CisOnboardingFormScreen` - Multi-step form with 3 steps:
  1. **Basic Details & CIS/Company Details** - Personal info, trade, site, employment status, bank details
  2. **Right to Work, CSCS & Key Tickets** - Right to work docs, CSCS card, qualifications
  3. **Emergency Contact, Medical & Declaration** - Contact info, medical fitness, site induction checklist, declaration

## Registration Flow

Currently, all new users are routed to the standard employee onboarding form (`/onboarding`). 

To route CIS subcontractors to the CIS form, you can:

1. **Option 1**: Add a selection during registration
2. **Option 2**: Check email pattern or user type
3. **Option 3**: Route based on employment type selection in first onboarding step

To manually route to CIS form, change the redirect in `register_screen.dart`:
```dart
context.go('/onboarding/cis');  // For CIS subcontractors
context.go('/onboarding');      // For regular employees
```

## Form Sections

1. **Basic Details** - Name, Known As, Trade, Site, Start Date, Supervisor, Mobile, Email
2. **CIS / Company Details** - Status (Sole Trader/LTD/Partnership), UTR, CIS Status, Company info, Bank details
3. **Right to Work & CSCS** - Nationality, Right to work, ID documents seen, CSCS details
4. **Key Tickets** - CPCS/NPORS, Working at Height, PASMA, Asbestos, First Aid, Manual Handling
5. **Emergency Contact** - Name, relationship, mobile, type
6. **Medical** - Fit to work, safety notes
7. **Quick Site Induction** - Manager checklist items
8. **Behaviour & Pay Basics** - Information display
9. **Declaration** - Signatures and dates

## Testing

1. Register a new user
2. Manually navigate to `/onboarding/cis` or update registration flow
3. Complete the 3-step form
4. Verify data saves correctly
5. Verify redirect to dashboard after completion

