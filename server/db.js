// server/db.js
const Database = require('better-sqlite3');
const path = require('path');

const db = new Database(path.join(__dirname, 'chw.db'));
db.pragma('journal_mode = WAL');

db.exec(`
  CREATE TABLE IF NOT EXISTS visits (
    local_id         TEXT PRIMARY KEY,
    chw_id           TEXT NOT NULL,
    patient_name     TEXT NOT NULL,
    village_name     TEXT NOT NULL,
    visit_type       TEXT NOT NULL CHECK (visit_type IN ('Maternal','Child','General')),
    vitals_bp        TEXT,
    vitals_temp      REAL CHECK (vitals_temp IS NULL OR (vitals_temp BETWEEN 35.0 AND 43.0)),
    urgency_level    TEXT NOT NULL CHECK (urgency_level IN ('Routine','Urgent','Emergency')),
    visit_notes      TEXT,
    created_at_local TEXT NOT NULL,
    received_at      TEXT NOT NULL DEFAULT (datetime('now'))
  );
  CREATE INDEX IF NOT EXISTS idx_visits_chw ON visits(chw_id);
`);

module.exports = db;