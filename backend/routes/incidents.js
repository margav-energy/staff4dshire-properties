const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');

// GET all incidents
router.get('/', async (req, res) => {
  try {
    // Check if table exists
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'incidents'
      )
    `);
    
    if (!tableExists.rows[0].exists) {
      console.log('⚠️  incidents table does not exist yet. Returning empty array.');
      return res.json([]);
    }
    
    const result = await pool.query(
      `SELECT i.*, 
              p.name as project_name,
              u.first_name || ' ' || u.last_name as reporter_name,
              assigned.first_name || ' ' || assigned.last_name as assigned_to_name
       FROM incidents i
       JOIN users u ON i.reporter_id = u.id
       LEFT JOIN projects p ON i.project_id = p.id
       LEFT JOIN users assigned ON i.assigned_to = assigned.id
       ORDER BY i.reported_at DESC`
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching incidents:', error);
    res.status(500).json({ error: 'Failed to fetch incidents', message: error.message });
  }
});

// GET incident by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT i.*, 
              p.name as project_name,
              u.first_name || ' ' || u.last_name as reporter_name,
              assigned.first_name || ' ' || assigned.last_name as assigned_to_name
       FROM incidents i
       JOIN users u ON i.reporter_id = u.id
       LEFT JOIN projects p ON i.project_id = p.id
       LEFT JOIN users assigned ON i.assigned_to = assigned.id
       WHERE i.id = $1`,
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Incident not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching incident:', error);
    res.status(500).json({ error: 'Failed to fetch incident' });
  }
});

// POST create new incident
router.post('/', async (req, res) => {
  try {
    // Check if table exists
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'incidents'
      )
    `);
    
    if (!tableExists.rows[0].exists) {
      return res.status(503).json({ 
        error: 'Incidents table not available yet', 
        message: 'The database is still being set up. Please try again in a moment.' 
      });
    }
    
    const {
      reporter_id,
      reporter_name,
      project_id,
      description,
      photo_path,
      severity = 'medium',
      location,
      latitude,
      longitude,
      status = 'reported'
    } = req.body;

    if (!reporter_id || !description) {
      return res.status(400).json({ error: 'Missing required fields: reporter_id, description' });
    }

    // Get user's company_id if available
    let companyId = null;
    try {
      const userResult = await pool.query(
        'SELECT company_id FROM users WHERE id = $1',
        [reporter_id]
      );
      companyId = userResult.rows[0]?.company_id || null;
    } catch (userError) {
      // If company_id column doesn't exist, that's OK
      console.log('⚠️  Could not get company_id for reporter:', userError.message);
    }

    const id = uuidv4();
    
    // Build INSERT query dynamically based on whether company_id column exists
    const columnCheck = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'incidents' AND column_name = 'company_id'
    `);
    const hasCompanyId = columnCheck.rows.length > 0;
    
    let insertColumns = ['id', 'reporter_id', 'project_id', 'description', 'photo_path', 'severity', 'location', 'latitude', 'longitude', 'status'];
    let insertValues = [id, reporter_id, project_id || null, description, photo_path || null, severity, location || null, latitude || null, longitude || null, status];
    let placeholders = insertValues.map((_, i) => `$${i + 1}`).join(', ');
    
    if (hasCompanyId && companyId) {
      insertColumns.push('company_id');
      insertValues.push(companyId);
      placeholders = insertValues.map((_, i) => `$${i + 1}`).join(', ');
    }
    
    const result = await pool.query(
      `INSERT INTO incidents (${insertColumns.join(', ')})
       VALUES (${placeholders})
       RETURNING *`,
      insertValues
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating incident:', error);
    res.status(500).json({ error: 'Failed to create incident', details: error.message });
  }
});

// PUT update incident (for status updates)
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      status,
      assigned_to,
      notes,
      status_updated_at,
      status_updated_by
    } = req.body;

    const updateFields = [];
    const values = [];
    let paramIndex = 1;

    if (status !== undefined) {
      updateFields.push(`status = $${paramIndex++}`);
      values.push(status);
    }

    if (assigned_to !== undefined) {
      updateFields.push(`assigned_to = $${paramIndex++}`);
      values.push(assigned_to);
    }

    if (notes !== undefined) {
      updateFields.push(`notes = $${paramIndex++}`);
      values.push(notes);
    }

    if (status_updated_at !== undefined) {
      updateFields.push(`status_updated_at = $${paramIndex++}`);
      values.push(status_updated_at);
    }

    if (status_updated_by !== undefined) {
      updateFields.push(`status_updated_by = $${paramIndex++}`);
      values.push(status_updated_by);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    // Always update updated_at
    updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    const result = await pool.query(
      `UPDATE incidents SET ${updateFields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Incident not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating incident:', error);
    res.status(500).json({ error: 'Failed to update incident', details: error.message });
  }
});

module.exports = router;

