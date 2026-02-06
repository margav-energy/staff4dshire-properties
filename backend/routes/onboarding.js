const express = require('express');
const router = express.Router();
const pool = require('../db');

// Get onboarding progress for a user
router.get('/progress/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Check if table exists
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'onboarding_progress'
      )
    `);
    
    if (!tableExists.rows[0].exists) {
      console.log('⚠️  onboarding_progress table does not exist yet. Returning default progress.');
      return res.json({
        user_id: userId,
        current_step: 1,
        is_complete: false,
        step_1_completed: false,
        step_2_completed: false,
        step_3_completed: false,
        step_4_completed: false,
        step_5_completed: false,
        step_6_completed: false
      });
    }
    
    const result = await pool.query(
      'SELECT * FROM onboarding_progress WHERE user_id = $1',
      [userId]
    );
    
    if (result.rows.length === 0) {
      // Initialize progress if not exists
      const insertResult = await pool.query(
        `INSERT INTO onboarding_progress (user_id, current_step, is_complete)
         VALUES ($1, 1, false)
         RETURNING *`,
        [userId]
      );
      return res.json(insertResult.rows[0]);
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching onboarding progress:', error);
    res.status(500).json({ error: 'Failed to fetch onboarding progress', message: error.message });
  }
});

// Get new starter details for a user
router.get('/new-starter/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM onboarding_new_starter_details WHERE user_id = $1',
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.json(null);
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching new starter details:', error);
    res.status(500).json({ error: 'Failed to fetch new starter details' });
  }
});

// Save/Update new starter details
router.post('/new-starter', async (req, res) => {
  try {
    const data = req.body;
    const userId = data.user_id;
    
    if (!userId) {
      return res.status(400).json({ error: 'user_id is required' });
    }
    
    // Check if record exists
    const existing = await pool.query(
      'SELECT id FROM onboarding_new_starter_details WHERE user_id = $1',
      [userId]
    );
    
    if (existing.rows.length > 0) {
      // Update existing
      const updateFields = [];
      const values = [];
      let paramCount = 1;
      
      const fields = [
        'position', 'site_office', 'start_date', 'employment_type', 'known_as',
        'date_of_birth', 'ni_number', 'address', 'postcode', 'mobile', 'email',
        'emergency_contact_name', 'emergency_contact_relationship', 'emergency_contact_mobile',
        'emergency_contact_type', 'secondary_contact_name', 'secondary_contact_mobile',
        'nationality', 'right_to_work_uk', 'right_to_work_docs_seen', 'right_to_work_other',
        'right_to_work_checked_by', 'right_to_work_checked_date',
        'bank_name', 'sort_code', 'account_number', 'payroll_number', 'worked_this_tax_year', 'p45_provided',
        'utr', 'cis_status', 'gross_company_name', 'company_number',
        'fit_for_role', 'medical_conditions', 'medication_details'
      ];
      
      fields.forEach(field => {
        if (data[field] !== undefined) {
          updateFields.push(`${field} = $${paramCount}`);
          values.push(data[field]);
          paramCount++;
        }
      });
      
      if (updateFields.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }
      
      values.push(userId);
      const query = `UPDATE onboarding_new_starter_details 
                     SET ${updateFields.join(', ')}
                     WHERE user_id = $${paramCount}
                     RETURNING *`;
      
      const result = await pool.query(query, values);
      
      // Update progress
      await pool.query(
        'UPDATE onboarding_progress SET step_1_completed = true, current_step = 2 WHERE user_id = $1',
        [userId]
      );
      
      res.json(result.rows[0]);
    } else {
      // Insert new
      const insertFields = ['user_id', ...Object.keys(data).filter(k => k !== 'id' && k !== 'user_id')];
      const insertValues = [userId, ...insertFields.slice(1).map(f => data[f])];
      const placeholders = insertValues.map((_, i) => `$${i + 1}`).join(', ');
      
      const query = `INSERT INTO onboarding_new_starter_details (${insertFields.join(', ')})
                     VALUES (${placeholders})
                     RETURNING *`;
      
      const result = await pool.query(query, insertValues);
      
      // Update progress
      await pool.query(
        'UPDATE onboarding_progress SET step_1_completed = true, current_step = 2 WHERE user_id = $1',
        [userId]
      );
      
      res.json(result.rows[0]);
    }
  } catch (error) {
    console.error('Error saving new starter details:', error);
    res.status(500).json({ error: 'Failed to save new starter details', message: error.message });
  }
});

// Get qualifications for a user
router.get('/qualifications/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM onboarding_qualifications WHERE user_id = $1',
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.json(null);
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching qualifications:', error);
    res.status(500).json({ error: 'Failed to fetch qualifications' });
  }
});

// Save/Update qualifications
router.post('/qualifications', async (req, res) => {
  try {
    const data = req.body;
    const userId = data.user_id;
    
    if (!userId) {
      return res.status(400).json({ error: 'user_id is required' });
    }
    
    // Check if record exists
    const existing = await pool.query(
      'SELECT id FROM onboarding_qualifications WHERE user_id = $1',
      [userId]
    );
    
    if (existing.rows.length > 0) {
      // Update existing (similar pattern as new-starter)
      const updateFields = [];
      const values = [];
      let paramCount = 1;
      
      const fields = [
        'cscs_type', 'cscs_expiry', 'cpcs_npors_types', 'cpcs_npors_expiry',
        'sssts_expiry', 'smsts_expiry', 'first_aid_work', 'first_aid_emergency_expiry',
        'asbestos_awareness', 'working_at_height', 'pasma', 'confined_spaces',
        'manual_handling', 'fire_marshall', 'other_qualifications',
        'checked_by', 'checked_date'
      ];
      
      fields.forEach(field => {
        if (data[field] !== undefined) {
          updateFields.push(`${field} = $${paramCount}`);
          values.push(data[field]);
          paramCount++;
        }
      });
      
      if (updateFields.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }
      
      values.push(userId);
      const query = `UPDATE onboarding_qualifications 
                     SET ${updateFields.join(', ')}
                     WHERE user_id = $${paramCount}
                     RETURNING *`;
      
      const result = await pool.query(query, values);
      
      // Update progress
      await pool.query(
        'UPDATE onboarding_progress SET step_2_completed = true, current_step = 3 WHERE user_id = $1',
        [userId]
      );
      
      res.json(result.rows[0]);
    } else {
      // Insert new
      const insertFields = ['user_id', ...Object.keys(data).filter(k => k !== 'id' && k !== 'user_id')];
      const insertValues = [userId, ...insertFields.slice(1).map(f => data[f])];
      const placeholders = insertValues.map((_, i) => `$${i + 1}`).join(', ');
      
      const query = `INSERT INTO onboarding_qualifications (${insertFields.join(', ')})
                     VALUES (${placeholders})
                     RETURNING *`;
      
      const result = await pool.query(query, insertValues);
      
      // Update progress
      await pool.query(
        'UPDATE onboarding_progress SET step_2_completed = true, current_step = 3 WHERE user_id = $1',
        [userId]
      );
      
      res.json(result.rows[0]);
    }
  } catch (error) {
    console.error('Error saving qualifications:', error);
    res.status(500).json({ error: 'Failed to save qualifications', message: error.message });
  }
});

// Get policies for a user
router.get('/policies/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM onboarding_policies WHERE user_id = $1',
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.json(null);
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching policies:', error);
    res.status(500).json({ error: 'Failed to fetch policies' });
  }
});

// Save/Update policies
router.post('/policies', async (req, res) => {
  try {
    const data = req.body;
    const userId = data.user_id;
    
    if (!userId) {
      return res.status(400).json({ error: 'user_id is required' });
    }
    
    // Check if record exists
    const existing = await pool.query(
      'SELECT id FROM onboarding_policies WHERE user_id = $1',
      [userId]
    );
    
    if (existing.rows.length > 0) {
      // Update existing
      const updateFields = [];
      const values = [];
      let paramCount = 1;
      
      const fields = [
        'health_safety_policy', 'drugs_alcohol_policy', 'environmental_policy',
        'equality_diversity', 'disciplinary_grievance', 'quality_policy',
        'anti_bullying_harassment', 'data_protection_confidentiality',
        'vehicle_fuel_card_policy', 'it_email_social_media_policy',
        'acknowledged_name', 'acknowledged_signature', 'acknowledged_date'
      ];
      
      fields.forEach(field => {
        if (data[field] !== undefined) {
          updateFields.push(`${field} = $${paramCount}`);
          values.push(data[field]);
          paramCount++;
        }
      });
      
      if (updateFields.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }
      
      values.push(userId);
      const query = `UPDATE onboarding_policies 
                     SET ${updateFields.join(', ')}
                     WHERE user_id = $${paramCount}
                     RETURNING *`;
      
      const result = await pool.query(query, values);
      
      // Update progress
      await pool.query(
        'UPDATE onboarding_progress SET step_5_completed = true, current_step = 6, is_complete = true WHERE user_id = $1',
        [userId]
      );
      
      res.json(result.rows[0]);
    } else {
      // Insert new
      const insertFields = ['user_id', ...Object.keys(data).filter(k => k !== 'id' && k !== 'user_id')];
      const insertValues = [userId, ...insertFields.slice(1).map(f => data[f])];
      const placeholders = insertValues.map((_, i) => `$${i + 1}`).join(', ');
      
      const query = `INSERT INTO onboarding_policies (${insertFields.join(', ')})
                     VALUES (${placeholders})
                     RETURNING *`;
      
      const result = await pool.query(query, insertValues);
      
      // Update progress - mark onboarding as complete after policies
      await pool.query(
        'UPDATE onboarding_progress SET step_5_completed = true, current_step = 6, is_complete = true WHERE user_id = $1',
        [userId]
      );
      
      res.json(result.rows[0]);
    }
  } catch (error) {
    console.error('Error saving policies:', error);
    res.status(500).json({ error: 'Failed to save policies', message: error.message });
  }
});

// ===== CIS Subcontractor Onboarding Routes =====

// Get CIS onboarding for a user
router.get('/cis/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Check if table exists
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'cis_onboarding'
      )
    `);
    
    if (!tableExists.rows[0].exists) {
      console.log('⚠️  cis_onboarding table does not exist yet. Returning null.');
      return res.json(null);
    }
    
    const result = await pool.query(
      'SELECT * FROM cis_onboarding WHERE user_id = $1',
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.json(null);
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching CIS onboarding:', error);
    res.status(500).json({ error: 'Failed to fetch CIS onboarding', message: error.message });
  }
});

// Save/Update CIS onboarding
router.post('/cis', async (req, res) => {
  try {
    const data = req.body;
    const userId = data.user_id;
    
    if (!userId) {
      return res.status(400).json({ error: 'user_id is required' });
    }
    
    // Check if record exists
    const existing = await pool.query(
      'SELECT id FROM cis_onboarding WHERE user_id = $1',
      [userId]
    );
    
    if (existing.rows.length > 0) {
      // Update existing
      const updateFields = [];
      const values = [];
      let paramCount = 1;
      
      const fields = [
        'name', 'known_as', 'trade', 'site', 'start_date', 'supervisor', 'mobile', 'email',
        'company_status', 'utr', 'cis_status', 'gross_company_name', 'company_number',
        'bank_name', 'sort_code', 'account_number',
        'nationality', 'right_to_work_uk', 'id_seen', 'id_other',
        'cscs_type', 'cscs_card_number', 'cscs_expiry',
        'cpcs_npors_plant', 'cpcs_npors_expiry',
        'working_at_height', 'pasma', 'asbestos_awareness', 'first_aid', 'manual_handling', 'other_tickets',
        'emergency_contact_name', 'emergency_contact_relationship', 'emergency_contact_mobile', 'emergency_contact_type',
        'fit_to_work', 'medical_notes',
        'site_rules_explained', 'sign_in_out_explained', 'fire_points_explained',
        'first_aid_explained', 'rams_explained', 'ppe_checked', 'extra_ppe_notes',
        'subcontractor_signature', 'subcontractor_signed_date', 'subcontractor_name_print',
        'site_manager_signature', 'site_manager_signed_date', 'site_manager_name_print',
        'is_complete'
      ];
      
      fields.forEach(field => {
        if (data[field] !== undefined) {
          updateFields.push(`${field} = $${paramCount}`);
          values.push(data[field]);
          paramCount++;
        }
      });
      
      if (updateFields.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }
      
      values.push(userId);
      const query = `UPDATE cis_onboarding 
                     SET ${updateFields.join(', ')}
                     WHERE user_id = $${paramCount}
                     RETURNING *`;
      
      const result = await pool.query(query, values);
      res.json(result.rows[0]);
    } else {
      // Insert new
      const insertFields = ['user_id', ...Object.keys(data).filter(k => k !== 'id' && k !== 'user_id')];
      const insertValues = [userId, ...insertFields.slice(1).map(f => data[f])];
      const placeholders = insertValues.map((_, i) => `$${i + 1}`).join(', ');
      
      const query = `INSERT INTO cis_onboarding (${insertFields.join(', ')})
                     VALUES (${placeholders})
                     RETURNING *`;
      
      const result = await pool.query(query, insertValues);
      res.json(result.rows[0]);
    }
  } catch (error) {
    console.error('Error saving CIS onboarding:', error);
    res.status(500).json({ error: 'Failed to save CIS onboarding', message: error.message });
  }
});

module.exports = router;

