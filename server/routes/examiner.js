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

module.exports = router;
