-- Job Completion and Invoice Schema Additions
-- Run this after the main schema.sql
-- This version uses gen_random_uuid() which is built-in to PostgreSQL 13+ (no extension needed)

-- Job Completions Table
-- Tracks completion status for each time entry/job session
CREATE TABLE IF NOT EXISTS job_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    time_entry_id UUID NOT NULL REFERENCES time_entries(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_completed BOOLEAN NOT NULL,
    completion_reason TEXT, -- Required if is_completed = false
    completion_image_url VARCHAR(500), -- For callout jobs
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'invoiced')),
    approved_by UUID REFERENCES users(id), -- Supervisor who approved
    approved_at TIMESTAMP,
    rejection_reason TEXT, -- If supervisor rejects
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(time_entry_id) -- One completion per time entry
);

-- Invoices Table
-- Stores invoice information for completed jobs
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number VARCHAR(100) UNIQUE NOT NULL, -- Auto-generated (e.g., INV-2024-001)
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    time_entry_id UUID REFERENCES time_entries(id) ON DELETE SET NULL,
    job_completion_id UUID REFERENCES job_completions(id) ON DELETE SET NULL,
    staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    supervisor_id UUID REFERENCES users(id), -- Supervisor who approved
    amount DECIMAL(10, 2) NOT NULL,
    hours_worked DECIMAL(5, 2), -- Calculated from time entry
    hourly_rate DECIMAL(10, 2), -- Can be set per project or user
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'paid', 'cancelled')),
    is_paid BOOLEAN DEFAULT FALSE,
    paid_at TIMESTAMP,
    paid_by UUID REFERENCES users(id), -- Admin who marked as paid
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Job Completion Images Table (for callout jobs)
CREATE TABLE IF NOT EXISTS job_completion_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_completion_id UUID NOT NULL REFERENCES job_completions(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    image_type VARCHAR(50), -- 'before', 'after', 'completion'
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_job_completions_time_entry ON job_completions(time_entry_id);
CREATE INDEX IF NOT EXISTS idx_job_completions_project ON job_completions(project_id);
CREATE INDEX IF NOT EXISTS idx_job_completions_status ON job_completions(status);
CREATE INDEX IF NOT EXISTS idx_job_completions_user ON job_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_project ON invoices(project_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_staff ON invoices(staff_id);
CREATE INDEX IF NOT EXISTS idx_job_completion_images_completion ON job_completion_images(job_completion_id);

-- Function to generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
DECLARE
    year_part VARCHAR(4);
    seq_num INTEGER;
    new_invoice_num VARCHAR(100);
BEGIN
    year_part := TO_CHAR(CURRENT_DATE, 'YYYY');
    
    -- Get the next sequence number for this year
    SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM '[0-9]+$') AS INTEGER)), 0) + 1
    INTO seq_num
    FROM invoices
    WHERE invoice_number LIKE 'INV-' || year_part || '-%';
    
    -- Format: INV-YYYY-001
    new_invoice_num := 'INV-' || year_part || '-' || LPAD(seq_num::TEXT, 3, '0');
    
    NEW.invoice_number := new_invoice_num;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate invoice number
DROP TRIGGER IF EXISTS generate_invoice_number_trigger ON invoices;
CREATE TRIGGER generate_invoice_number_trigger
    BEFORE INSERT ON invoices
    FOR EACH ROW
    WHEN (NEW.invoice_number IS NULL OR NEW.invoice_number = '')
    EXECUTE FUNCTION generate_invoice_number();

-- Trigger for updated_at on job_completions (only if function exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') THEN
        DROP TRIGGER IF EXISTS update_job_completions_updated_at ON job_completions;
        CREATE TRIGGER update_job_completions_updated_at BEFORE UPDATE ON job_completions
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Trigger for updated_at on invoices (only if function exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') THEN
        DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
        CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- View for Live Jobs (jobs in progress)
DROP VIEW IF EXISTS live_jobs;
CREATE VIEW live_jobs AS
SELECT 
    p.id as project_id,
    p.name as project_name,
    p.type as project_type,
    p.address,
    te.id as time_entry_id,
    te.user_id,
    u.first_name || ' ' || u.last_name as staff_name,
    te.sign_in_time,
    te.sign_out_time,
    CASE 
        WHEN te.sign_out_time IS NULL THEN 'in_progress'
        WHEN jc.id IS NULL THEN 'pending_completion'
        WHEN jc.status = 'pending' THEN 'pending_approval'
        ELSE jc.status
    END as job_status,
    jc.is_completed,
    jc.completion_reason
FROM projects p
INNER JOIN time_entries te ON p.id = te.project_id
INNER JOIN users u ON te.user_id = u.id
LEFT JOIN job_completions jc ON te.id = jc.time_entry_id
WHERE 
    p.is_active = TRUE 
    AND (te.sign_out_time IS NULL OR jc.status IN ('pending', 'approved'))
    AND p.is_completed = FALSE;

-- View for Invoice Jobs (completed jobs with invoices)
DROP VIEW IF EXISTS invoice_jobs;
CREATE VIEW invoice_jobs AS
SELECT 
    i.id as invoice_id,
    i.invoice_number,
    i.project_id,
    p.name as project_name,
    p.type as project_type,
    i.staff_id,
    u.first_name || ' ' || u.last_name as staff_name,
    i.amount,
    i.hours_worked,
    i.hourly_rate,
    i.status as invoice_status,
    i.is_paid,
    i.paid_at,
    i.created_at as invoice_date,
    i.due_date,
    jc.completion_image_url
FROM invoices i
INNER JOIN projects p ON i.project_id = p.id
INNER JOIN users u ON i.staff_id = u.id
LEFT JOIN job_completions jc ON i.job_completion_id = jc.id
ORDER BY i.created_at DESC;


