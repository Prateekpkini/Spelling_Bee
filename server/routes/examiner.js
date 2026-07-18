const express = require('express');
const { v4: uuidv4 } = require('uuid');
const pool = require('../db');
const { authenticateToken, requireExaminer } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/examiner/students
 * Body: { name, grade, section, school_name, school_address, city, district, state, parent_mobile }
 * Registers a student, generates a secure token, returns student data + game URL.
 * Requires authenticated examiner (or super admin).
 */
router.post('/students', authenticateToken, requireExaminer, async (req, res) => {
  try {
    const {
      name, grade, section, school_name, school_address,
      city, district, state, parent_mobile,
    } = req.body;

    if (!name || !grade) {
      return res.status(400).json({ error: 'Name and grade are required' });
    }

    // Generate a secure unique token
    const token = uuidv4().replace(/-/g, '');

    const [result] = await pool.execute(
      `INSERT INTO students
        (examiner_id, name, grade, section, school_name, school_address, city, district, state, parent_mobile, token, token_status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')`,
      [
        req.user.userId,
        name,
        grade,
        section || null,
        school_name || null,
        school_address || null,
        city || null,
        district || null,
        state || null,
        parent_mobile || null,
        token,
      ]
    );

    const student = {
      id: result.insertId,
      name,
      grade,
      section: section || '',
      school_name: school_name || '',
      school_address: school_address || '',
      city: city || '',
      district: district || '',
      state: state || '',
      parent_mobile: parent_mobile || '',
      token,
      token_status: 'active',
    };

    res.status(201).json({
      message: 'Student registered successfully',
      student,
      token,
    });
  } catch (err) {
    console.error('Register student error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/leaderboard
 * Returns all results ranked by leaderboard criteria.
 * Accessible to any authenticated user.
 */
router.get('/leaderboard', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT * FROM results
       ORDER BY final_score DESC, correct_answers DESC, wrong_answers ASC, time_remaining_seconds DESC`
    );
    res.json({ results: rows });
  } catch (err) {
    console.error('Leaderboard error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/examiner/students
 * Returns all students registered by the authenticated examiner.
 */
router.get('/students', authenticateToken, requireExaminer, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT * FROM students WHERE examiner_id = ? ORDER BY created_at DESC`,
      [req.user.userId]
    );
    res.json({ students: rows });
  } catch (err) {
    console.error('Get students error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PUT /api/examiner/students/:id/regenerate_token
 * Regenerates the game token for a specific student.
 */
router.put('/students/:id/regenerate_token', authenticateToken, requireExaminer, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Ensure student belongs to the examiner
    const [existing] = await pool.execute('SELECT id FROM students WHERE id = ? AND examiner_id = ?', [id, req.user.userId]);
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Student not found or access denied' });
    }

    const token = uuidv4().replace(/-/g, '');
    
    await pool.execute(
      `UPDATE students SET token = ?, token_status = 'active' WHERE id = ?`,
      [token, id]
    );
    
    res.json({ message: 'Token regenerated successfully', token });
  } catch (err) {
    console.error('Regenerate token error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
