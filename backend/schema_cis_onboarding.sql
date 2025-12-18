-- CIS Subcontractor / Site Starter Onboarding Schema
-- Simplified onboarding form for subcontractors

CREATE TABLE IF NOT EXISTS cis_onboarding (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- 1. Basic Details
    name VARCHAR(255),
    known_as VARCHAR(100),
    trade VARCHAR(255),
    site VARCHAR(255),
    start_date DATE,
    supervisor VARCHAR(255),
    mobile VARCHAR(20),
    email VARCHAR(255),
    
    -- 2. CIS / Company Details
    company_status VARCHAR(50), -- 'sole_trader', 'ltd_company', 'partnership'
    utr VARCHAR(50),
    cis_status VARCHAR(50), -- 'registered' or 'gross'
    gross_company_name VARCHAR(255),
    company_number VARCHAR(50),
    bank_name VARCHAR(255),
    sort_code VARCHAR(20),
    account_number VARCHAR(50),
    
    -- 3. Right to Work & CSCS
    nationality VARCHAR(100),
    right_to_work_uk BOOLEAN,
    id_seen JSONB DEFAULT '[]'::jsonb, -- Array of ID types: ['passport', 'brp', 'share_code', etc.]
    id_other VARCHAR(255),
    cscs_type VARCHAR(100),
    cscs_card_number VARCHAR(100),
    cscs_expiry DATE,
    
    -- 4. Key Tickets
    cpcs_npors_plant VARCHAR(255),
    cpcs_npors_expiry DATE,
    working_at_height BOOLEAN DEFAULT FALSE,
    pasma BOOLEAN DEFAULT FALSE,
    asbestos_awareness BOOLEAN DEFAULT FALSE,
    first_aid BOOLEAN DEFAULT FALSE,
    manual_handling BOOLEAN DEFAULT FALSE,
    other_tickets TEXT,
    
    -- 5. Emergency Contact
    emergency_contact_name VARCHAR(255),
    emergency_contact_relationship VARCHAR(100),
    emergency_contact_mobile VARCHAR(20),
    emergency_contact_type VARCHAR(20), -- 'home' or 'work'
    
    -- 6. Medical
    fit_to_work BOOLEAN,
    medical_notes TEXT,
    
    -- 7. Quick Site Induction (Manager completes)
    site_rules_explained BOOLEAN DEFAULT FALSE,
    sign_in_out_explained BOOLEAN DEFAULT FALSE,
    fire_points_explained BOOLEAN DEFAULT FALSE,
    first_aid_explained BOOLEAN DEFAULT FALSE,
    rams_explained BOOLEAN DEFAULT FALSE,
    ppe_checked BOOLEAN DEFAULT FALSE,
    extra_ppe_notes TEXT,
    
    -- 8. Declaration
    subcontractor_signature VARCHAR(255),
    subcontractor_signed_date DATE,
    subcontractor_name_print VARCHAR(255),
    site_manager_signature VARCHAR(255),
    site_manager_signed_date DATE,
    site_manager_name_print VARCHAR(255),
    
    is_complete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_cis_onboarding_user_id ON cis_onboarding(user_id);

-- Trigger for updated_at
CREATE TRIGGER update_cis_onboarding_updated_at BEFORE UPDATE ON cis_onboarding
    FOR EACH ROW EXECUTE FUNCTION update_onboarding_updated_at();

