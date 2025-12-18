# Onboarding Form Implementation

## Overview
A comprehensive multi-step onboarding form system has been implemented for new staff members. When a new user registers, they are automatically redirected to complete the onboarding process.

## Database Schema
Created `schema_onboarding.sql` with the following tables:
- `onboarding_new_starter_details` - Personal and employment details
- `onboarding_qualifications` - Qualifications, tickets & competencies
- `onboarding_pre_start_checklist` - Internal compliance checklist (admin use)
- `onboarding_site_induction` - First day site induction (admin use)
- `onboarding_policies` - Policy acknowledgments
- `onboarding_reviews` - First week & probation reviews (admin use)
- `onboarding_progress` - Progress tracking

## API Routes (`/api/onboarding`)
- `GET /progress/:userId` - Get onboarding progress
- `GET /new-starter/:userId` - Get new starter details
- `POST /new-starter` - Save/update new starter details
- `GET /qualifications/:userId` - Get qualifications
- `POST /qualifications` - Save/update qualifications
- `GET /policies/:userId` - Get policies
- `POST /policies` - Save/update policies (marks onboarding as complete)

## Mobile App Components

### Models
- `OnboardingNewStarterDetails` - Data model for step 1
- `OnboardingProgress` - Progress tracking model

### Provider
- `OnboardingProvider` - State management for onboarding data

### Screen
- `OnboardingFormScreen` - Multi-step form with 3 steps:
  1. **New Starter Details** - Personal info, employment type, emergency contacts, right to work, bank details, medical fitness
  2. **Qualifications** - CSCS, CPCS/NPORS, SSSTS, SMSTS, First Aid, and other competencies
  3. **Policies** - Acknowledgment of all company policies

## Registration Flow
When a new user registers:
1. User completes registration with email, password, name, and photo
2. After successful registration, user is redirected to `/onboarding`
3. User completes the 3-step onboarding form
4. Upon completion, user is redirected to their dashboard

## Next Steps (Future Enhancements)
The following sections from the original form can be added later:
- Pre-Start Compliance Checklist (admin completes)
- First Day Site Induction (admin completes)
- First Week & Probation Reviews (admin completes)

These are marked as "admin use" in the schema and can be managed through admin screens.

## Testing
1. Register a new user
2. Verify redirect to onboarding form
3. Complete each step and verify data saves
4. Verify final redirect to dashboard after completion

