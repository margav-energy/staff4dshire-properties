-- Onboarding Schema for Staff4dshire Properties
-- This schema stores comprehensive onboarding data for new staff members

-- New Starter Details
CREATE TABLE IF NOT EXISTS onboarding_new_starter_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    position VARCHAR(255),
    site_office VARCHAR(255),
    start_date DATE,
    employment_type VARCHAR(50) CHECK (employment_type IN ('employee', 'subcontractor_cis', 'consultant')),
    known_as VARCHAR(100),
    date_of_birth DATE,
    ni_number VARCHAR(20),
    address TEXT,
    postcode VARCHAR(20),
    mobile VARCHAR(20),
    email VARCHAR(255),
    emergency_contact_name VARCHAR(255),
    emergency_contact_relationship VARCHAR(100),
    emergency_contact_mobile VARCHAR(20),
    emergency_contact_type VARCHAR(20), -- 'home' or 'work'
    secondary_contact_name VARCHAR(255),
    secondary_contact_mobile VARCHAR(20),
    nationality VARCHAR(100),
    right_to_work_uk BOOLEAN,
    right_to_work_docs_seen JSONB DEFAULT '[]'::jsonb, -- Array of doc types: ['uk_passport', 'brp', 'share_code', etc.]
    right_to_work_other VARCHAR(255),
    right_to_work_checked_by VARCHAR(255),
    right_to_work_checked_date DATE,
    -- Payroll & Tax (Employees)
    bank_name VARCHAR(255),
    sort_code VARCHAR(20),
    account_number VARCHAR(50),
    payroll_number VARCHAR(100),
    worked_this_tax_year BOOLEAN,
    p45_provided BOOLEAN,
    -- CIS Subcontractors
    utr VARCHAR(50),
    cis_status VARCHAR(50), -- 'registered' or 'unregistered'
    gross_company_name VARCHAR(255),
    company_number VARCHAR(50),
    -- Medical / Fitness
    fit_for_role BOOLEAN,
    medical_conditions TEXT,
    medication_details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Qualifications, Tickets & Competencies
CREATE TABLE IF NOT EXISTS onboarding_qualifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cscs_type VARCHAR(100),
    cscs_expiry DATE,
    cpcs_npors_types TEXT, -- Comma-separated or JSON
    cpcs_npors_expiry DATE,
    sssts_expiry DATE,
    smsts_expiry DATE,
    first_aid_work BOOLEAN,
    first_aid_emergency_expiry DATE,
    asbestos_awareness BOOLEAN,
    working_at_height BOOLEAN,
    pasma BOOLEAN,
    confined_spaces BOOLEAN,
    manual_handling BOOLEAN,
    fire_marshall BOOLEAN,
    other_qualifications TEXT,
    checked_by VARCHAR(255),
    checked_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Pre-Start Compliance Checklist (Internal Use)
CREATE TABLE IF NOT EXISTS onboarding_pre_start_checklist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Pre-Start Actions
    offer_letter_issued BOOLEAN DEFAULT FALSE,
    contract_signed BOOLEAN DEFAULT FALSE,
    job_description_issued BOOLEAN DEFAULT FALSE,
    pay_rate_confirmed BOOLEAN DEFAULT FALSE,
    start_date_confirmed BOOLEAN DEFAULT FALSE,
    site_address_sent BOOLEAN DEFAULT FALSE,
    -- Documentation Received
    right_to_work_docs_received BOOLEAN DEFAULT FALSE,
    bank_details_received BOOLEAN DEFAULT FALSE,
    proof_of_address_received BOOLEAN DEFAULT FALSE,
    utr_company_details_received BOOLEAN DEFAULT FALSE,
    cscs_tickets_copies_received BOOLEAN DEFAULT FALSE,
    ppe_requirements_sent BOOLEAN DEFAULT FALSE,
    docs_saved_to_hr_folder BOOLEAN DEFAULT FALSE,
    -- IT / Systems
    email_created BOOLEAN DEFAULT FALSE,
    added_to_communication_systems BOOLEAN DEFAULT FALSE,
    device_prepared BOOLEAN DEFAULT FALSE,
    manager_name VARCHAR(255),
    checklist_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- First Day Site Induction Checklist
CREATE TABLE IF NOT EXISTS onboarding_site_induction (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(255),
    site VARCHAR(255),
    induction_date DATE,
    inducted_by VARCHAR(255),
    -- Site & Safety Induction
    site_rules_explained BOOLEAN DEFAULT FALSE,
    sign_in_out_procedure BOOLEAN DEFAULT FALSE,
    welfare_facilities BOOLEAN DEFAULT FALSE,
    fire_exits_explained BOOLEAN DEFAULT FALSE,
    first_aid_stations BOOLEAN DEFAULT FALSE,
    accident_reporting BOOLEAN DEFAULT FALSE,
    traffic_routes BOOLEAN DEFAULT FALSE,
    smoking_rules BOOLEAN DEFAULT FALSE,
    drugs_alcohol_policy BOOLEAN DEFAULT FALSE,
    housekeeping_waste BOOLEAN DEFAULT FALSE,
    -- RAMS & Task Briefings
    rams_issued BOOLEAN DEFAULT FALSE,
    method_statements_explained BOOLEAN DEFAULT FALSE,
    coshh_briefed BOOLEAN DEFAULT FALSE,
    permit_to_work_systems BOOLEAN DEFAULT FALSE,
    -- PPE & Tools
    minimum_ppe_checked BOOLEAN DEFAULT FALSE,
    additional_ppe_issued BOOLEAN DEFAULT FALSE,
    tools_equipment_inspected BOOLEAN DEFAULT FALSE,
    -- Behaviour & Standards
    zero_tolerance_explained BOOLEAN DEFAULT FALSE,
    neighbours_property_respect BOOLEAN DEFAULT FALSE,
    social_media_policy BOOLEAN DEFAULT FALSE,
    no_unauthorised_visitors BOOLEAN DEFAULT FALSE,
    -- Signatures
    inductee_signature VARCHAR(255),
    inductee_signed_date DATE,
    manager_signature VARCHAR(255),
    manager_signed_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Policies Acknowledged
CREATE TABLE IF NOT EXISTS onboarding_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    health_safety_policy BOOLEAN DEFAULT FALSE,
    drugs_alcohol_policy BOOLEAN DEFAULT FALSE,
    environmental_policy BOOLEAN DEFAULT FALSE,
    equality_diversity BOOLEAN DEFAULT FALSE,
    disciplinary_grievance BOOLEAN DEFAULT FALSE,
    quality_policy BOOLEAN DEFAULT FALSE,
    anti_bullying_harassment BOOLEAN DEFAULT FALSE,
    data_protection_confidentiality BOOLEAN DEFAULT FALSE,
    vehicle_fuel_card_policy BOOLEAN DEFAULT FALSE,
    it_email_social_media_policy BOOLEAN DEFAULT FALSE,
    acknowledged_name VARCHAR(255),
    acknowledged_signature VARCHAR(255),
    acknowledged_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- First Week & Probation Reviews
CREATE TABLE IF NOT EXISTS onboarding_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- First Week Check
    first_week_check_date DATE,
    introduced_to_team BOOLEAN DEFAULT FALSE,
    timesheet_process_explained BOOLEAN DEFAULT FALSE,
    expenses_process_explained BOOLEAN DEFAULT FALSE,
    job_expectations_discussed BOOLEAN DEFAULT FALSE,
    ppe_tools_checked_again BOOLEAN DEFAULT FALSE,
    training_needs TEXT,
    first_week_manager VARCHAR(255),
    -- 1-Month Review
    one_month_review_date DATE,
    one_month_performance_notes TEXT,
    one_month_outcome VARCHAR(50), -- 'continue', 'action_plan', 'end_engagement'
    one_month_employee_signature VARCHAR(255),
    one_month_manager_signature VARCHAR(255),
    -- 3-Month / Probation Review (Employees)
    three_month_review_date DATE,
    three_month_outcome VARCHAR(50), -- 'confirmed', 'extended', 'terminated'
    probation_extended_to DATE,
    three_month_employee_signature VARCHAR(255),
    three_month_manager_signature VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Onboarding Progress Tracking
CREATE TABLE IF NOT EXISTS onboarding_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    step_1_completed BOOLEAN DEFAULT FALSE, -- New Starter Details
    step_2_completed BOOLEAN DEFAULT FALSE, -- Qualifications
    step_3_completed BOOLEAN DEFAULT FALSE, -- Pre-Start Checklist (admin)
    step_4_completed BOOLEAN DEFAULT FALSE, -- Site Induction (admin)
    step_5_completed BOOLEAN DEFAULT FALSE, -- Policies
    step_6_completed BOOLEAN DEFAULT FALSE, -- Reviews (admin)
    current_step INTEGER DEFAULT 1,
    is_complete BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_onboarding_user_id ON onboarding_new_starter_details(user_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_qualifications_user_id ON onboarding_qualifications(user_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_progress_user_id ON onboarding_progress(user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_onboarding_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_onboarding_new_starter_updated_at BEFORE UPDATE ON onboarding_new_starter_details
    FOR EACH ROW EXECUTE FUNCTION update_onboarding_updated_at();

CREATE TRIGGER update_onboarding_qualifications_updated_at BEFORE UPDATE ON onboarding_qualifications
    FOR EACH ROW EXECUTE FUNCTION update_onboarding_updated_at();

CREATE TRIGGER update_onboarding_progress_updated_at BEFORE UPDATE ON onboarding_progress
    FOR EACH ROW EXECUTE FUNCTION update_onboarding_updated_at();

