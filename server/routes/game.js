const express = require('express');
const pool = require('../db');

const router = express.Router();

/**
 * GET /api/game/validate/:token
 * Checks if a game token is valid and active.
 * Public endpoint (no auth required).
 */
router.get('/validate/:token', async (req, res) => {
  try {
    const { token } = req.params;

    const [rows] = await pool.execute(
      'SELECT id, name, grade, section, school_name, city, token_status FROM students WHERE token = ?',
      [token]
    );

    const [settings] = await pool.execute('SELECT event_name FROM global_settings WHERE id = 1');
    const eventName = settings.length > 0 ? settings[0].event_name : 'Everest Spelling Bee Open Challenge';

    if (rows.length === 0) {
      return res.json({ status: 'not_found', student: null, event_name: eventName });
    }

    const student = rows[0];

    if (student.token_status === 'used') {
      return res.json({ status: 'used', student, event_name: eventName });
    }

    res.json({ status: 'active', student, event_name: eventName });
  } catch (err) {
    console.error('Validate token error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/game/start/:token
 * Marks the token as 'used' and returns:
 * - The student's grade word bank (shuffled)
 * - Global settings (timer, shields, passes)
 */
router.post('/start/:token', async (req, res) => {
  try {
    const { token } = req.params;

    // Get student
    const [students] = await pool.execute(
      'SELECT * FROM students WHERE token = ?',
      [token]
    );

    if (students.length === 0) {
      return res.status(404).json({ error: 'Token not found' });
    }

    const student = students[0];

    if (student.token_status === 'used') {
      return res.status(400).json({ error: 'Token has already been used' });
    }

    // Mark token as used
    await pool.execute(
      "UPDATE students SET token_status = 'used' WHERE id = ?",
      [student.id]
    );

    // Fetch word bank for the student's grade
    const [words] = await pool.execute(
      'SELECT id, grade, spelling_british, spelling_american, part_of_speech, meaning, jumbled_letters FROM words WHERE grade = ? ORDER BY RAND()',
      [student.grade]
    );

    // Fetch global settings
    const [settings] = await pool.execute('SELECT * FROM global_settings WHERE id = 1');

    res.json({
      student: {
        id: student.id,
        name: student.name,
        grade: student.grade,
        section: student.section,
        school_name: student.school_name,
        city: student.city,
      },
      words,
      settings: settings[0] || { timer_seconds: 1800, initial_shields: 5, initial_passes: 5 },
    });
  } catch (err) {
    console.error('Start game error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/game/submit
 * Body: { student_id, student_name, grade, final_score, correct_answers, wrong_answers, passes_used, time_remaining_seconds, accuracy }
 * Saves the final game result.
 */
router.post('/submit', async (req, res) => {
  try {
    const {
      student_id, student_name, grade, final_score,
      correct_answers, wrong_answers, passes_used,
      time_remaining_seconds, accuracy,
    } = req.body;

    if (!student_name || final_score == null) {
      return res.status(400).json({ error: 'student_name and final_score are required' });
    }

    const [result] = await pool.execute(
      `INSERT INTO results
        (student_id, student_name, grade, final_score, correct_answers, wrong_answers, passes_used, time_remaining_seconds, accuracy)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        student_id || null,
        student_name,
        grade || null,
        parseInt(final_score),
        parseInt(correct_answers || 0),
        parseInt(wrong_answers || 0),
        parseInt(passes_used || 0),
        parseInt(time_remaining_seconds || 0),
        parseFloat(accuracy || 0),
      ]
    );

    res.status(201).json({
      message: 'Result saved successfully',
      resultId: result.insertId,
    });
  } catch (err) {
    console.error('Submit result error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/game/config
 * Returns public global settings (like event_name).
 */
router.get('/config', async (req, res) => {
  try {
    const [settings] = await pool.execute('SELECT event_name FROM global_settings WHERE id = 1');
    const eventName = settings.length > 0 ? settings[0].event_name : 'Everest Spelling Bee Open Challenge';
    res.json({ event_name: eventName });
  } catch (err) {
    console.error('Get config error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/game/preload/:token
 * Pre-loads all game data (words, settings, student info) WITHOUT marking the token as used.
 * This allows the student to download everything before going into airplane mode.
 */
router.get('/preload/:token', async (req, res) => {
  try {
    const { token } = req.params;

    // Get student
    const [students] = await pool.execute(
      'SELECT * FROM students WHERE token = ?',
      [token]
    );

    if (students.length === 0) {
      return res.status(404).json({ error: 'Token not found' });
    }

    const student = students[0];

    if (student.token_status === 'used') {
      return res.status(400).json({ error: 'Token has already been used' });
    }

    // Fetch word bank for the student's grade (shuffled)
    const [words] = await pool.execute(
      'SELECT id, grade, spelling_british, spelling_american, part_of_speech, meaning, jumbled_letters FROM words WHERE grade = ? ORDER BY RAND()',
      [student.grade]
    );

    // Fetch global settings
    const [settings] = await pool.execute('SELECT * FROM global_settings WHERE id = 1');

    res.json({
      student: {
        id: student.id,
        name: student.name,
        grade: student.grade,
        section: student.section,
        school_name: student.school_name,
        school_address: student.school_address,
        city: student.city,
        district: student.district,
        state: student.state,
        parent_mobile: student.parent_mobile,
      },
      words,
      settings: settings[0] || { timer_seconds: 1800, initial_shields: 5, initial_passes: 5 },
      event_name: settings.length > 0 ? settings[0].event_name : 'Everest Spelling Bee Open Challenge',
    });
  } catch (err) {
    console.error('Preload game error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/game/submit-offline
 * Body: { token, student_id, student_name, grade, final_score, correct_answers, wrong_answers, passes_used, time_remaining_seconds, accuracy }
 * Saves the game result AND marks the token as used atomically.
 * Used when the game was played in offline/airplane mode.
 */
router.post('/submit-offline', async (req, res) => {
  try {
    const {
      token, student_id, student_name, grade, final_score,
      correct_answers, wrong_answers, passes_used,
      time_remaining_seconds, accuracy,
    } = req.body;

    if (!student_name || final_score == null) {
      return res.status(400).json({ error: 'student_name and final_score are required' });
    }

    if (!token) {
      return res.status(400).json({ error: 'token is required for offline submission' });
    }

    // Mark token as used (idempotent — if already used, that's fine)
    await pool.execute(
      "UPDATE students SET token_status = 'used' WHERE token = ?",
      [token]
    );

    // Save result
    const [result] = await pool.execute(
      `INSERT INTO results
        (student_id, student_name, grade, final_score, correct_answers, wrong_answers, passes_used, time_remaining_seconds, accuracy)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        student_id || null,
        student_name,
        grade || null,
        parseInt(final_score),
        parseInt(correct_answers || 0),
        parseInt(wrong_answers || 0),
        parseInt(passes_used || 0),
        parseInt(time_remaining_seconds || 0),
        parseFloat(accuracy || 0),
      ]
    );

    res.status(201).json({
      message: 'Offline result saved successfully',
      resultId: result.insertId,
    });
  } catch (err) {
    console.error('Submit offline result error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

