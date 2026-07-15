/**
 * ══════════════════════════════════════════════════════════════════════
 * Everest Spelling Bee – Google Sheets → Firestore Word Sync
 * ══════════════════════════════════════════════════════════════════════
 *
 * SETUP INSTRUCTIONS:
 * 1. Open your Google Sheet with the word data.
 * 2. Go to Extensions → Apps Script.
 * 3. Paste this entire file into the script editor.
 * 4. Update FIREBASE_PROJECT_ID below with your Firebase project ID.
 * 5. Run the `syncWordsToFirestore` function.
 * 6. On first run, authorize the script when prompted.
 *
 * REQUIRED SHEET FORMAT (Row 1 = Headers):
 * | Grade | British Spelling | American Spelling | Part of Speech | Meaning | Jumbled Letters |
 *
 * AUTHENTICATION:
 * Uses the script owner's OAuth token via ScriptApp.getOAuthToken().
 * The script owner must have Firestore access on the Firebase project.
 * 
 * Required OAuth Scopes (add to appsscript.json):
 * - https://www.googleapis.com/auth/datastore
 * - https://www.googleapis.com/auth/script.external_request
 */

// ─── Configuration ────────────────────────────────────────────────────
const FIREBASE_PROJECT_ID = 'everest-spelling-bee-26';
const FIRESTORE_BASE_URL = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;
const COLLECTION_NAME = 'words';
const BATCH_SIZE = 20; // Firestore batch commit limit is 20

// ─── Main Sync Function ──────────────────────────────────────────────

function syncWordsToFirestore() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  const data = sheet.getDataRange().getValues();
  
  if (data.length <= 1) {
    Logger.log('No data rows found (only header row).');
    return;
  }

  // Validate header row
  const headers = data[0].map(h => h.toString().trim().toLowerCase());
  Logger.log('Headers found: ' + headers.join(', '));

  // Map header indices
  const colMap = {
    grade: findColumnIndex(headers, ['grade']),
    britishSpelling: findColumnIndex(headers, ['british spelling', 'british_spelling', 'spelling_british']),
    americanSpelling: findColumnIndex(headers, ['american spelling', 'american_spelling', 'spelling_american']),
    partOfSpeech: findColumnIndex(headers, ['part of speech', 'part_of_speech']),
    meaning: findColumnIndex(headers, ['meaning']),
    jumbledLetters: findColumnIndex(headers, ['jumbled letters', 'jumbled_letters']),
  };

  // Validate required columns
  for (const [key, index] of Object.entries(colMap)) {
    if (index === -1) {
      Logger.log(`ERROR: Required column "${key}" not found. Check header names.`);
      return;
    }
  }

  // Process data rows
  let successCount = 0;
  let skipCount = 0;
  let errorCount = 0;

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const britishSpelling = row[colMap.britishSpelling]?.toString().trim();

    if (!britishSpelling) {
      skipCount++;
      continue;
    }

    // Use British spelling (sanitized) as the document ID to avoid duplicates
    const docId = sanitizeDocId(britishSpelling);
    const grade = row[colMap.grade]?.toString().trim() || '';
    const americanSpelling = row[colMap.americanSpelling]?.toString().trim() || '';
    const partOfSpeech = row[colMap.partOfSpeech]?.toString().trim() || '';
    const meaning = row[colMap.meaning]?.toString().trim() || '';
    const jumbledLetters = row[colMap.jumbledLetters]?.toString().trim() || '';

    const docData = {
      fields: {
        grade: { stringValue: grade },
        spelling_british: { stringValue: britishSpelling },
        spelling_american: { stringValue: americanSpelling },
        part_of_speech: { stringValue: partOfSpeech },
        meaning: { stringValue: meaning },
        jumbled_letters: { stringValue: jumbledLetters },
      }
    };

    try {
      upsertDocument(docId, docData);
      successCount++;
      
      // Log progress every 50 rows
      if (successCount % 50 === 0) {
        Logger.log(`Progress: ${successCount} words synced...`);
      }
    } catch (e) {
      Logger.log(`ERROR on row ${i + 1} ("${britishSpelling}"): ${e.message}`);
      errorCount++;
    }
  }

  Logger.log('═══════════════════════════════════════════');
  Logger.log(`Sync complete!`);
  Logger.log(`  ✓ Synced: ${successCount}`);
  Logger.log(`  ⊘ Skipped (empty): ${skipCount}`);
  Logger.log(`  ✗ Errors: ${errorCount}`);
  Logger.log('═══════════════════════════════════════════');
}

// ─── Firestore Helpers ────────────────────────────────────────────────

/**
 * Upserts a document into Firestore using PATCH (creates or overwrites).
 */
function upsertDocument(docId, docData) {
  const url = `${FIRESTORE_BASE_URL}/${COLLECTION_NAME}/${docId}`;
  const token = ScriptApp.getOAuthToken();

  const options = {
    method: 'patch',
    contentType: 'application/json',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
    payload: JSON.stringify(docData),
    muteHttpExceptions: true,
  };

  const response = UrlFetchApp.fetch(url, options);
  const code = response.getResponseCode();

  if (code !== 200) {
    throw new Error(`HTTP ${code}: ${response.getContentText()}`);
  }
}

// ─── Utility Functions ────────────────────────────────────────────────

/**
 * Finds a column index from an array of possible header names.
 */
function findColumnIndex(headers, possibleNames) {
  for (const name of possibleNames) {
    const idx = headers.indexOf(name);
    if (idx !== -1) return idx;
  }
  return -1;
}

/**
 * Sanitizes a string for use as a Firestore document ID.
 * Removes characters that Firestore doesn't allow in document IDs.
 */
function sanitizeDocId(str) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9_-]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
}
