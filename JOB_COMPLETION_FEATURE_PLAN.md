# Job Completion & Invoice Feature - Implementation Plan

## Overview

This feature adds job completion tracking, supervisor approval workflow, and invoice generation for completed jobs.

## Requirements Breakdown

### 1. Staff Sign-Out Flow
- **At sign-out, staff must specify:**
  - Job completion status (Completed/Not Completed)
  - If not completed, provide reason
  - For callout jobs: Upload completion image (required)

### 2. Supervisor Approval
- Jobs marked as "not completed" are sent to supervisor for approval
- Supervisor can approve/reject completion
- If approved as satisfactory, invoice is generated

### 3. Invoice System
- Invoice generated after supervisor approval (or direct completion for callout)
- All 3 roles can view invoices
- Admin can mark invoices as paid
- Callout jobs: Staff can mark as completed + upload image → Invoice ready for payment

### 4. Dashboard Sections
- **Admin & Supervisor:** "Live Jobs" section (jobs in progress)
- **Admin:** "Invoice Jobs" section (completed jobs with invoices)

## Database Schema Changes

### New Tables Needed:

1. **job_completions** - Track job completion status per time entry
2. **invoices** - Store invoice information
3. **job_completion_images** - Store completion images for callout jobs

## Implementation Steps

1. ✅ Create database schema updates
2. ✅ Create models (JobCompletion, Invoice)
3. ✅ Update sign-out flow with completion dialog
4. ✅ Add image upload for callout jobs
5. ✅ Create supervisor approval screen
6. ✅ Create invoice generation logic
7. ✅ Add Live Jobs section to dashboards
8. ✅ Add Invoice Jobs section to admin dashboard

Let's start implementing!


