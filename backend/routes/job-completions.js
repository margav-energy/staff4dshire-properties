const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');

// GET all job completions
router.get('/', async (req, res) => {
  try {
    // Check if table exists
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'job_completions'
      )
    `);
    
    if (!tableExists.rows[0].exists) {
      console.log('⚠️  job_completions table does not exist yet. Returning empty array.');
      return res.json([]);
    }
    
    const result = await pool.query(
      `SELECT jc.*, 
              p.name as project_name,
              u.first_name || ' ' || u.last_name as staff_name
       FROM job_completions jc
       JOIN projects p ON jc.project_id = p.id
       JOIN users u ON jc.user_id = u.id
       ORDER BY jc.created_at DESC`
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching job completions:', error);
    res.status(500).json({ error: 'Failed to fetch job completions', message: error.message });
  }
});

// GET job completion by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT jc.*, 
              p.name as project_name,
              u.first_name || ' ' || u.last_name as staff_name
       FROM job_completions jc
       JOIN projects p ON jc.project_id = p.id
       JOIN users u ON jc.user_id = u.id
       WHERE jc.id = $1`,
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Job completion not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching job completion:', error);
    res.status(500).json({ error: 'Failed to fetch job completion' });
  }
});

// POST create new job completion
router.post('/', async (req, res) => {
  try {
    // Check if table exists
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'job_completions'
      )
    `);
    
    if (!tableExists.rows[0].exists) {
      return res.status(503).json({ 
        error: 'Job completions table not available yet', 
        message: 'The database is still being set up. Please try again in a moment.' 
      });
    }
    
    const {
      time_entry_id,
      project_id,
      user_id,
      is_completed,
      completion_reason,
      completion_image_url,
      status = 'pending'
    } = req.body;

    if (!time_entry_id || !project_id || !user_id || is_completed === undefined) {
      return res.status(400).json({ error: 'Missing required fields: time_entry_id, project_id, user_id, is_completed' });
    }

    // If not completed, completion_reason is required
    if (!is_completed && !completion_reason) {
      return res.status(400).json({ error: 'completion_reason is required when is_completed is false' });
    }

    const id = uuidv4();
    const result = await pool.query(
      `INSERT INTO job_completions (
        id, time_entry_id, project_id, user_id, is_completed,
        completion_reason, completion_image_url, status
      )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        id, time_entry_id, project_id, user_id, is_completed,
        completion_reason || null, completion_image_url || null, status
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    if (error.code === '23505') { // Unique violation (time_entry_id already has completion)
      return res.status(409).json({ error: 'Job completion already exists for this time entry' });
    }
    console.error('Error creating job completion:', error);
    res.status(500).json({ error: 'Failed to create job completion', details: error.message });
  }
});

// PUT approve job completion
router.put('/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    const { approved_by } = req.body;

    if (!approved_by) {
      return res.status(400).json({ error: 'approved_by is required' });
    }

    const result = await pool.query(
      `UPDATE job_completions 
       SET status = 'approved',
           approved_by = $1,
           approved_at = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING *`,
      [approved_by, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Job completion not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error approving job completion:', error);
    res.status(500).json({ error: 'Failed to approve job completion', details: error.message });
  }
});

// PUT reject job completion
router.put('/:id/reject', async (req, res) => {
  try {
    const { id } = req.params;
    const { approved_by, rejection_reason } = req.body;

    if (!approved_by) {
      return res.status(400).json({ error: 'approved_by is required' });
    }

    const result = await pool.query(
      `UPDATE job_completions 
       SET status = 'rejected',
           approved_by = $1,
           approved_at = CURRENT_TIMESTAMP,
           rejection_reason = $2,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING *`,
      [approved_by, rejection_reason || null, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Job completion not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error rejecting job completion:', error);
    res.status(500).json({ error: 'Failed to reject job completion', details: error.message });
  }
});

module.exports = router;

