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
 * Returns results ranked by leaderboard criteria.
 * - Examiners see only students they registered.
 * - Super Admins see all students.
 * - Optional ?grade=X query parameter filters by grade.
 * Requires authentication.
 */
router.get('/leaderboard', authenticateToken, async (req, res) => {
  try {
    const { grade } = req.query;
    const role = req.user.role;

    let query;
    const params = [];

    if (role === 'superadmin') {
      // Super admin sees all results
      query = `SELECT r.*, (g.timer_seconds - r.time_remaining_seconds) AS time_taken_seconds 
               FROM results r CROSS JOIN global_settings g WHERE g.id = 1`;
      if (grade) {
        query += ` AND r.grade = ?`;
        params.push(grade);
      }
    } else {
      // Examiner sees only their students' results
      query = `SELECT r.*, (g.timer_seconds - r.time_remaining_seconds) AS time_taken_seconds 
               FROM results r
               CROSS JOIN global_settings g
               INNER JOIN students s ON r.student_id = s.id
               WHERE s.examiner_id = ? AND g.id = 1`;
      params.push(req.user.userId);
      if (grade) {
        query += ` AND r.grade = ?`;
        params.push(grade);
      }
    }

    query += ` ORDER BY r.final_score DESC, r.correct_answers DESC, r.wrong_answers ASC, r.time_remaining_seconds DESC`;

    const [rows] = await pool.execute(query, params);
    res.json({ results: rows });
  } catch (err) {
    console.error('Leaderboard error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/leaderboard/public
 * Public leaderboard — no authentication required.
 * Returns all results for the shareable link.
 * Optional ?grade=X query parameter filters by grade.
 */
router.get('/leaderboard/public', async (req, res) => {
  try {
    const { grade } = req.query;
    let query = `SELECT r.*, (g.timer_seconds - r.time_remaining_seconds) AS time_taken_seconds 
                 FROM results r CROSS JOIN global_settings g WHERE g.id = 1`;
    const params = [];

    if (grade) {
      query += ` AND r.grade = ?`;
      params.push(grade);
    }

    query += ` ORDER BY final_score DESC, correct_answers DESC, wrong_answers ASC, time_remaining_seconds DESC`;

    const [rows] = await pool.execute(query, params);
    res.json({ results: rows });
  } catch (err) {
    console.error('Public leaderboard error:', err);
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

/**
 * DELETE /api/examiner/students/:id
 * Deletes a student registered by the authenticated examiner.
 * Associated results will have student_id set to NULL (ON DELETE SET NULL).
 */
router.delete('/students/:id', authenticateToken, requireExaminer, async (req, res) => {
  try {
    const { id } = req.params;

    // Ensure student belongs to the examiner
    const [existing] = await pool.execute(
      'SELECT id FROM students WHERE id = ? AND examiner_id = ?',
      [id, req.user.userId]
    );
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Student not found or access denied' });
    }

    await pool.execute('DELETE FROM students WHERE id = ?', [id]);

    res.json({ message: 'Student deleted successfully' });
  } catch (err) {
    console.error('Delete student error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
