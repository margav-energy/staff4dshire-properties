const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');

// GET all incidents
router.get('/', async (req, res) => {
  try {
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
    res.status(500).json({ error: 'Failed to fetch incidents' });
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

    const id = uuidv4();
    const result = await pool.query(
      `INSERT INTO incidents (
        id, reporter_id, project_id, description, photo_path,
        severity, location, latitude, longitude, status
      )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        id, reporter_id, project_id || null, description, photo_path || null,
        severity, location || null, latitude || null, longitude || null, status
      ]
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

