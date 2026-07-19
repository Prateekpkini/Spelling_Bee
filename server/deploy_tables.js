const fs = require('fs');
const path = require('path');
const db = require('./db'); // This imports your updated db.js file

async function initializeDatabase() {
    try {
        console.log('⏳ Connecting to Aiven Cloud MySQL and executing init.sql...');

        const sqlPath = path.join(__dirname, 'db', 'init.sql');
        const sqlFile = fs.readFileSync(sqlPath, 'utf8');

        // Split queries by semicolon to run them sequentially
        const queries = sqlFile.split(';').filter(query => query.trim() !== '');

        for (let query of queries) {
            await db.query(query);
        }

        console.log('✅ Tables created and Super Admin seeded successfully on Aiven Cloud!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Database initialization failed:', error);
        process.exit(1);
    }
}

initializeDatabase();