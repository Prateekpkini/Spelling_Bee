const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../db');
const { authenticateToken, requireSuperAdmin } = require('../middleware/auth');

const router = express.Router();

// All routes in this file require Super Admin authentication
router.use(authenticateToken, requireSuperAdmin);

/**
 * POST /api/admin/teachers
 * Body: { name, school, email, password }
 * Creates a new examiner user.
 */
router.post('/teachers', async (req, res) => {
  try {
    const { name, school, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required' });
    }

    // Check for duplicate email
    const [existing] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'A user with this email already exists' });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const [result] = await pool.execute(
      'INSERT INTO users (role, name, school, email, password_hash) VALUES (?, ?, ?, ?, ?)',
      ['examiner', name, school || null, email, passwordHash]
    );

    res.status(201).json({
      message: 'Examiner created successfully',
      teacher: {
        id: result.insertId,
        name,
        school: school || null,
        email,
        role: 'examiner',
      },
    });
  } catch (err) {
    console.error('Create teacher error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/admin/teachers
 * Returns list of all examiners.
 */
router.get('/teachers', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      "SELECT id, name, school, email, created_at FROM users WHERE role = 'examiner' ORDER BY created_at DESC"
    );
    res.json({ teachers: rows });
  } catch (err) {
    console.error('Get teachers error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * DELETE /api/admin/teachers/:id
 * Deletes an examiner by ID.
 */
router.delete('/teachers/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // First check if the user is an examiner
    const [existing] = await pool.execute("SELECT id FROM users WHERE id = ? AND role = 'examiner'", [id]);
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Teacher not found' });
    }

    await pool.execute('DELETE FROM users WHERE id = ?', [id]);
    res.json({ message: 'Teacher deleted successfully' });
  } catch (err) {
    console.error('Delete teacher error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * DELETE /api/admin/students/:id
 * Deletes a student by ID.
 */
router.delete('/students/:id', async (req, res) => {
  try {
    const { id } = req.params;
    // Delete results first to avoid foreign key constraints (if any)
    await pool.execute('DELETE FROM results WHERE student_id = ?', [id]);
    await pool.execute('DELETE FROM students WHERE id = ?', [id]);
    
    res.json({ message: 'Student deleted successfully' });
  } catch (err) {
    console.error('Delete student error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/admin/settings
 * Returns current global game settings.
 */
router.get('/settings', async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM global_settings WHERE id = 1');
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Settings not found' });
    }
    res.json({ settings: rows[0] });
  } catch (err) {
    console.error('Get settings error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PUT /api/admin/settings
 * Body: { timer_seconds, initial_shields, initial_passes, event_name }
 * Updates global game settings.
 */
router.put('/settings', async (req, res) => {
  try {
    const { timer_seconds, initial_shields, initial_passes, event_name } = req.body;

    if (timer_seconds == null || initial_shields == null || initial_passes == null || !event_name) {
      return res.status(400).json({ error: 'timer_seconds, initial_shields, initial_passes, and event_name are required' });
    }

    await pool.execute(
      'UPDATE global_settings SET timer_seconds = ?, initial_shields = ?, initial_passes = ?, event_name = ? WHERE id = 1',
      [parseInt(timer_seconds), parseInt(initial_shields), parseInt(initial_passes), event_name]
    );

    res.json({
      message: 'Settings updated successfully',
      settings: {
        id: 1,
        timer_seconds: parseInt(timer_seconds),
        initial_shields: parseInt(initial_shields),
        initial_passes: parseInt(initial_passes),
        event_name: event_name,
      },
    });
  } catch (err) {
    console.error('Update settings error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
