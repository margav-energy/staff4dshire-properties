-- Migration: Add 'staff' role to company_invitations table
-- This allows staff members to be invited using invitation codes

-- Update the CHECK constraint to include 'staff' role
ALTER TABLE company_invitations 
DROP CONSTRAINT IF EXISTS company_invitations_role_check;

ALTER TABLE company_invitations 
ADD CONSTRAINT company_invitations_role_check 
CHECK (role IN ('admin', 'supervisor', 'staff'));


