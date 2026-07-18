const express = require('express');
const multer = require('multer');
const csv = require('csv-parser');
const { Readable } = require('stream');
const pool = require('../db');
const { authenticateToken, requireSuperAdmin } = require('../middleware/auth');

const router = express.Router();

// Configure multer for in-memory file storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'text/csv' || file.originalname.endsWith('.csv')) {
      cb(null, true);
    } else {
      cb(new Error('Only CSV files are allowed'), false);
    }
  },
});

// All routes require Super Admin authentication
router.use(authenticateToken, requireSuperAdmin);

/**
 * POST /api/admin/words/upload
 * Multipart form: file (CSV), grade (string)
 * CSV columns: spelling_british, spelling_american, part_of_speech, meaning, jumbled_letters
 * Upserts words into the words table for the specified grade.
 */
router.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const { grade } = req.body;

    if (!grade) {
      return res.status(400).json({ error: 'Grade is required' });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'CSV file is required' });
    }

    const words = [];

    // Parse CSV from buffer
    await new Promise((resolve, reject) => {
      const stream = Readable.from(req.file.buffer.toString());
      stream
        .pipe(csv())
        .on('data', (row) => {
          // Normalize column names (trim whitespace, lowercase)
          const normalized = {};
          for (const key of Object.keys(row)) {
            normalized[key.trim().toLowerCase()] = row[key]?.trim() || '';
          }

          if (normalized.spelling_british) {
            words.push({
              grade,
              spelling_british: normalized.spelling_british,
              spelling_american: normalized.spelling_american || normalized.spelling_british,
              part_of_speech: normalized.part_of_speech || '',
              meaning: normalized.meaning || '',
              jumbled_letters: normalized.jumbled_letters || '',
            });
          }
        })
        .on('end', resolve)
        .on('error', reject);
    });

    if (words.length === 0) {
      return res.status(400).json({ error: 'No valid words found in the CSV file' });
    }

    // Upsert words (INSERT ... ON DUPLICATE KEY UPDATE)
    let inserted = 0;
    let updated = 0;

    for (const word of words) {
      const [result] = await pool.execute(
        `INSERT INTO words (grade, spelling_british, spelling_american, part_of_speech, meaning, jumbled_letters)
         VALUES (?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
           spelling_american = VALUES(spelling_american),
           part_of_speech = VALUES(part_of_speech),
           meaning = VALUES(meaning),
           jumbled_letters = VALUES(jumbled_letters)`,
        [word.grade, word.spelling_british, word.spelling_american, word.part_of_speech, word.meaning, word.jumbled_letters]
      );

      if (result.affectedRows === 1) {
        inserted++;
      } else if (result.affectedRows === 2) {
        // ON DUPLICATE KEY UPDATE counts as 2 affected rows
        updated++;
      }
    }

    res.json({
      message: `Successfully processed ${words.length} words for Grade ${grade}`,
      inserted,
      updated,
      total: words.length,
    });
  } catch (err) {
    console.error('Word upload error:', err);
    res.status(500).json({ error: 'Failed to process CSV file' });
  }
});

module.exports = router;
