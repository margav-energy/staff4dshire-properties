const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');

// GET all time entries
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT te.*, u.first_name, u.last_name, p.name as project_name
       FROM time_entries te
       JOIN users u ON te.user_id = u.id
       JOIN projects p ON te.project_id = p.id
       ORDER BY te.sign_in_time DESC`
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching time entries:', error);
    res.status(500).json({ error: 'Failed to fetch time entries' });
  }
});

// GET time entries by user ID
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await pool.query(
      `SELECT te.*, p.name as project_name
       FROM time_entries te
       JOIN projects p ON te.project_id = p.id
       WHERE te.user_id = $1
       ORDER BY te.sign_in_time DESC`,
      [userId]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching user time entries:', error);
    res.status(500).json({ error: 'Failed to fetch time entries' });
  }
});

// GET time entry by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT te.*, u.first_name, u.last_name, p.name as project_name
       FROM time_entries te
       JOIN users u ON te.user_id = u.id
       JOIN projects p ON te.project_id = p.id
       WHERE te.id = $1`,
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Time entry not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching time entry:', error);
    res.status(500).json({ error: 'Failed to fetch time entry' });
  }
});

// POST create new time entry (sign in)
router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      project_id,
      sign_in_time,
      sign_in_latitude,
      sign_in_longitude,
      sign_in_location,
      notes
    } = req.body;

    if (!user_id || !project_id || !sign_in_time) {
      return res.status(400).json({ error: 'Missing required fields: user_id, project_id, sign_in_time' });
    }

    const id = uuidv4();
    const result = await pool.query(
      `INSERT INTO time_entries (
        id, user_id, project_id, sign_in_time,
        sign_in_latitude, sign_in_longitude, sign_in_location, notes
      )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        id, user_id, project_id, sign_in_time,
        sign_in_latitude || null, sign_in_longitude || null,
        sign_in_location || null, notes || null
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating time entry:', error);
    res.status(500).json({ error: 'Failed to create time entry', details: error.message });
  }
});

// PUT update time entry (sign out or update)
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    let updateFields = [];
    let values = [];
    let paramIndex = 1;

    const allowedFields = [
      'sign_out_time', 'sign_out_latitude', 'sign_out_longitude',
      'sign_out_location', 'is_approved', 'approved_by', 'approved_at',
      'notes'
    ];

    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        updateFields.push(`${field} = $${paramIndex++}`);
        values.push(updateData[field]);
      }
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    const result = await pool.query(
      `UPDATE time_entries SET ${updateFields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Time entry not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating time entry:', error);
    res.status(500).json({ error: 'Failed to update time entry', details: error.message });
  }
});

// DELETE time entry
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM time_entries WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Time entry not found' });
    }

    res.json({ message: 'Time entry deleted successfully', entry: result.rows[0] });
  } catch (error) {
    console.error('Error deleting time entry:', error);
    res.status(500).json({ error: 'Failed to delete time entry' });
  }
});

module.exports = router;

