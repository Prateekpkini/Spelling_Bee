const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

async function updatePassword() {
  try {
    const password = 'Admin370';
    const hash = await bcrypt.hash(password, 10);
    console.log(`Generated hash for ${password}: ${hash}`);

    const pool = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '3306'),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'spelling_bee',
    });

    const [result] = await pool.execute(
      'UPDATE users SET password_hash = ? WHERE email = ?',
      [hash, 'superadmin@gmail.com']
    );

    console.log('Password updated successfully. Rows affected:', result.affectedRows);
    await pool.end();
  } catch (err) {
    console.error('Error:', err);
  }
}

updatePassword();
