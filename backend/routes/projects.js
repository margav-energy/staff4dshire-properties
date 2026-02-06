const express = require('express');
const router = express.Router();
const pool = require('../db');
const { v4: uuidv4 } = require('uuid');

// GET all projects (filtered by company unless superadmin)
router.get('/', async (req, res) => {
  try {
    // Get userId from query param (temporary, should come from auth middleware)
    const userId = req.query.userId;
    
    let query = 'SELECT * FROM projects';
    let params = [];
    
    if (userId) {
      // Check which columns exist in users table
      const columnCheck = await pool.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name IN ('is_superadmin', 'company_id')
      `);
      const existingColumns = columnCheck.rows.map(row => row.column_name);
      const hasIsSuperadmin = existingColumns.includes('is_superadmin');
      const hasCompanyId = existingColumns.includes('company_id');
      
      // Build select query based on available columns
      let selectColumns = ['role'];
      if (hasCompanyId) {
        selectColumns.push('company_id');
      }
      if (hasIsSuperadmin) {
        selectColumns.push('is_superadmin');
      }
      
      // Get user's company_id and superadmin status
      const userResult = await pool.query(
        `SELECT ${selectColumns.join(', ')} FROM users WHERE id = $1`,
        [userId]
      );
      
      if (userResult.rows.length > 0) {
        const user = userResult.rows[0];
        const isSuperadmin = (hasIsSuperadmin && user.is_superadmin) || user.role === 'superadmin';
        const companyId = hasCompanyId ? user.company_id : null;
        
        console.log('[PROJECTS API] User found:', {
          userId,
          company_id: companyId,
          is_superadmin: hasIsSuperadmin ? user.is_superadmin : false,
          role: user.role,
          isSuperadmin
        });
        
        // Superadmins can see all projects
        if (!isSuperadmin) {
          // Regular users can only see projects from their company
          // Check if company_id column exists first
          try {
            const columnCheck = await pool.query(`
              SELECT column_name 
              FROM information_schema.columns 
              WHERE table_name = 'projects' AND column_name = 'company_id'
            `);
            const hasCompanyIdColumn = columnCheck.rows.length > 0;
            
            if (hasCompanyId) {
              // Only filter if company_id exists (non-null)
              if (companyId) {
                // Filter by matching company_id
                query += ' WHERE company_id IS NOT NULL AND company_id = $1';
                params = [companyId];
                console.log('[PROJECTS API] Filtering by company_id:', companyId);
              } else {
                // User has no company_id - return empty list
                query += ' WHERE 1=0'; // Always false condition
                params = [];
                console.log('[PROJECTS API] User has no company_id, returning empty list');
              }
            } else {
              // company_id column doesn't exist yet - return all projects for this user
              console.log('[PROJECTS API] company_id column not found, returning all projects');
            }
          } catch (checkError) {
            // If check fails, just return all projects
            console.log('[PROJECTS API] Error checking company_id column, returning all projects');
          }
        } else {
          console.log('[PROJECTS API] Superadmin detected, returning all projects');
        }
      } else {
        console.log('[PROJECTS API] User not found for userId:', userId);
      }
    } else {
      console.log('[PROJECTS API] No userId provided, returning all projects');
    }
    
    query += ' ORDER BY created_at DESC';
    const result = await pool.query(query, params);
    // Parse JSON fields and convert coordinates
    const projects = result.rows.map(row => {
      // Convert latitude/longitude to numbers if they're strings
      const lat = row.latitude != null 
        ? (typeof row.latitude === 'string' ? parseFloat(row.latitude) : row.latitude)
        : null;
      const lng = row.longitude != null
        ? (typeof row.longitude === 'string' ? parseFloat(row.longitude) : row.longitude)
        : null;
      
      return {
        ...row,
        latitude: lat,
        longitude: lng,
        photos: typeof row.photos === 'string' ? JSON.parse(row.photos) : (row.photos || []),
        drawings: typeof row.drawings === 'string' ? JSON.parse(row.drawings) : (row.drawings || []),
        assigned_staff_ids: row.assigned_staff_ids || [],
        assigned_supervisor_ids: row.assigned_supervisor_ids || [],
      };
    });
    res.json(projects);
  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(500).json({ error: 'Failed to fetch projects' });
  }
});

// GET project by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    // Validate UUID format - skip if invalid (likely old test data)
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(404).json({ error: 'Project not found' });
    }
    const result = await pool.query('SELECT * FROM projects WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }
    
    const project = result.rows[0];
    // Convert latitude/longitude to numbers if they're strings
    if (project.latitude != null && typeof project.latitude === 'string') {
      project.latitude = parseFloat(project.latitude);
    }
    if (project.longitude != null && typeof project.longitude === 'string') {
      project.longitude = parseFloat(project.longitude);
    }
    project.photos = typeof project.photos === 'string' ? JSON.parse(project.photos) : (project.photos || []);
    project.drawings = typeof project.drawings === 'string' ? JSON.parse(project.drawings) : (project.drawings || []);
    project.assigned_staff_ids = project.assigned_staff_ids || [];
    project.assigned_supervisor_ids = project.assigned_supervisor_ids || [];
    
    res.json(project);
  } catch (error) {
    console.error('Error fetching project:', error);
    res.status(500).json({ error: 'Failed to fetch project' });
  }
});

// POST create new project
router.post('/', async (req, res) => {
  try {
    const {
      name,
      address,
      latitude,
      longitude,
      description,
      is_active = true,
      is_completed = false,
      before_photo,
      after_photo,
      completed_at,
      type = 'regular',
      category,
      photos = [],
      drawings = [],
      assigned_staff_ids = [],
      assigned_supervisor_ids = [],
      start_date
    } = req.body;
    
    // Convert latitude and longitude to numbers if they are strings
    const lat = latitude != null ? (typeof latitude === 'string' ? parseFloat(latitude) : latitude) : null;
    const lng = longitude != null ? (typeof longitude === 'string' ? parseFloat(longitude) : longitude) : null;

    if (!name) {
      return res.status(400).json({ error: 'Project name is required' });
    }

    // Get company_id from the requesting user
    let companyId = req.body.company_id;
    if (!companyId) {
      const userId = req.query.userId || req.body.created_by_user_id;
      if (userId) {
        const userResult = await pool.query('SELECT company_id FROM users WHERE id = $1', [userId]);
        if (userResult.rows.length > 0) {
          companyId = userResult.rows[0].company_id;
        }
      }
    }

    const id = uuidv4();
    // Try to insert with company_id, fallback if column doesn't exist
    let result;
    try {
      result = await pool.query(
        `INSERT INTO projects (
          id, name, address, latitude, longitude, description, is_active, is_completed,
          before_photo, after_photo, completed_at, type, category, photos, drawings,
          assigned_staff_ids, assigned_supervisor_ids, start_date, company_id
        )
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
         RETURNING *`,
        [
          id, name, address || null, lat, lng,
          description || null, is_active, is_completed,
          before_photo || null, after_photo || null, completed_at || null,
          type, category || null, JSON.stringify(photos), JSON.stringify(drawings),
          assigned_staff_ids, assigned_supervisor_ids, start_date || null, companyId || null
        ]
      );
    } catch (err) {
      // Fallback if company_id column doesn't exist
      if (err.message.includes('column "company_id"')) {
        result = await pool.query(
          `INSERT INTO projects (
            id, name, address, latitude, longitude, description, is_active, is_completed,
            before_photo, after_photo, completed_at, type, category, photos, drawings,
            assigned_staff_ids, assigned_supervisor_ids, start_date
          )
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
           RETURNING *`,
          [
            id, name, address || null, lat, lng,
            description || null, is_active, is_completed,
            before_photo || null, after_photo || null, completed_at || null,
            type, category || null, JSON.stringify(photos), JSON.stringify(drawings),
            assigned_staff_ids, assigned_supervisor_ids, start_date || null
          ]
        );
      } else {
        throw err;
      }
    }

    const project = result.rows[0];
    project.photos = typeof project.photos === 'string' ? JSON.parse(project.photos) : (project.photos || []);
    project.drawings = typeof project.drawings === 'string' ? JSON.parse(project.drawings) : (project.drawings || []);
    project.assigned_staff_ids = project.assigned_staff_ids || [];
    project.assigned_supervisor_ids = project.assigned_supervisor_ids || [];

    // Create notifications for assigned staff members
    if (assigned_staff_ids && assigned_staff_ids.length > 0) {
      for (const staffId of assigned_staff_ids) {
        try {
          await pool.query(
            `INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [
              staffId,
              'Project Assignment',
              `You have been assigned to project: ${name}`,
              'info',
              'project',
              id
            ]
          );
        } catch (notifError) {
          console.error(`Error creating notification for staff ${staffId}:`, notifError);
          // Don't fail the request if notification creation fails
        }
      }
    }

    // Create notifications for assigned supervisors
    if (assigned_supervisor_ids && assigned_supervisor_ids.length > 0) {
      for (const supervisorId of assigned_supervisor_ids) {
        try {
          await pool.query(
            `INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [
              supervisorId,
              'Project Assignment',
              `You have been assigned as supervisor to project: ${name}`,
              'info',
              'project',
              id
            ]
          );
        } catch (notifError) {
          console.error(`Error creating notification for supervisor ${supervisorId}:`, notifError);
          // Don't fail the request if notification creation fails
        }
      }
    }

    res.status(201).json(project);
  } catch (error) {
    console.error('Error creating project:', error);
    res.status(500).json({ error: 'Failed to create project', details: error.message });
  }
});

// PUT update project
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    // Build dynamic update query
    let updateFields = [];
    let values = [];
    let paramIndex = 1;

    const allowedFields = [
      'name', 'address', 'latitude', 'longitude', 'description',
      'is_active', 'is_completed', 'before_photo', 'after_photo',
      'completed_at', 'type', 'category', 'photos', 'drawings',
      'assigned_staff_ids', 'assigned_supervisor_ids', 'start_date'
    ];

    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        if (field === 'photos' || field === 'drawings') {
          updateFields.push(`${field} = $${paramIndex++}`);
          values.push(JSON.stringify(updateData[field]));
        } else if (field === 'latitude' || field === 'longitude') {
          // Convert latitude/longitude to numbers if they are strings
          const numValue = updateData[field] != null 
            ? (typeof updateData[field] === 'string' ? parseFloat(updateData[field]) : updateData[field])
            : null;
          updateFields.push(`${field} = $${paramIndex++}`);
          values.push(numValue);
        } else {
          updateFields.push(`${field} = $${paramIndex++}`);
          values.push(updateData[field]);
        }
      }
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(id);

    const result = await pool.query(
      `UPDATE projects SET ${updateFields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const project = result.rows[0];
    project.photos = typeof project.photos === 'string' ? JSON.parse(project.photos) : (project.photos || []);
    project.drawings = typeof project.drawings === 'string' ? JSON.parse(project.drawings) : (project.drawings || []);
    project.assigned_staff_ids = project.assigned_staff_ids || [];
    project.assigned_supervisor_ids = project.assigned_supervisor_ids || [];

    // Check for newly assigned staff members and create notifications
    if (updateData.assigned_staff_ids !== undefined) {
      // Get previous assignments to find new ones
      const previousResult = await pool.query('SELECT assigned_staff_ids FROM projects WHERE id = $1', [id]);
      const previousStaffIds = previousResult.rows[0]?.assigned_staff_ids || [];
      const previousSet = new Set(previousStaffIds.map(String)); // Convert to strings for comparison
      const newStaffIds = (updateData.assigned_staff_ids || []).filter(staffId => !previousSet.has(String(staffId)));
      
      // Create notifications for newly assigned staff
      for (const staffId of newStaffIds) {
        try {
          await pool.query(
            `INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [
              staffId,
              'Project Assignment',
              `You have been assigned to project: ${project.name}`,
              'info',
              'project',
              id
            ]
          );
        } catch (notifError) {
          console.error(`Error creating notification for staff ${staffId}:`, notifError);
          // Don't fail the request if notification creation fails
        }
      }
    }

    // Check for newly assigned supervisors and create notifications
    if (updateData.assigned_supervisor_ids !== undefined) {
      // Get previous assignments to find new ones
      const previousResult = await pool.query('SELECT assigned_supervisor_ids FROM projects WHERE id = $1', [id]);
      const previousSupervisorIds = previousResult.rows[0]?.assigned_supervisor_ids || [];
      const previousSet = new Set(previousSupervisorIds.map(String)); // Convert to strings for comparison
      const newSupervisorIds = (updateData.assigned_supervisor_ids || []).filter(supervisorId => !previousSet.has(String(supervisorId)));
      
      // Create notifications for newly assigned supervisors
      for (const supervisorId of newSupervisorIds) {
        try {
          await pool.query(
            `INSERT INTO notifications (user_id, title, message, type, related_entity_type, related_entity_id)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [
              supervisorId,
              'Project Assignment',
              `You have been assigned as supervisor to project: ${project.name}`,
              'info',
              'project',
              id
            ]
          );
        } catch (notifError) {
          console.error(`Error creating notification for supervisor ${supervisorId}:`, notifError);
        }
      }
    }

    res.json(project);
  } catch (error) {
    console.error('Error updating project:', error);
    res.status(500).json({ error: 'Failed to update project', details: error.message });
  }
});

// DELETE project
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM projects WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Project not found' });
    }

    res.json({ message: 'Project deleted successfully', project: result.rows[0] });
  } catch (error) {
    console.error('Error deleting project:', error);
    res.status(500).json({ error: 'Failed to delete project' });
  }
});

module.exports = router;

