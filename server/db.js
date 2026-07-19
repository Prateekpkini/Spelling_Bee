const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'spelling_bee',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // Aiven strictly requires SSL for all external connections. 
  // This turns on secure encryption automatically when connecting to the cloud.
  ssl: process.env.DB_HOST && process.env.DB_HOST !== 'localhost'
    ? { rejectUnauthorized: false }
    : false,
});

module.exports = pool;