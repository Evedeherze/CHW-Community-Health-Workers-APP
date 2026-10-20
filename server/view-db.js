// server/view-db.js
const db = require('./db');

console.log('\n========================================');
console.log('       CENTRAL SQLITE DATABASE VIEWER   ');
console.log('========================================\n');

try {
  // 1. Fetch total count
  const countRow = db.prepare('SELECT COUNT(*) as total FROM visits').get();
  console.log(`Total Visit Records: ${countRow.total}\n`);

  // 2. Fetch all records
  const visits = db.prepare(`
    SELECT 
      id, 
      local_id, 
      patient_name, 
      village_name, 
      visit_type, 
      vitals_bp, 
      vitals_temp, 
      urgency_level, 
      created_at_local, 
      sync_status,
      server_received_at 
    FROM visits 
    ORDER BY id DESC
  `).all();

  if (visits.length === 0) {
    console.log('The "visits" table is currently empty.');
  } else {
    console.table(visits);
  }

  // 3. Breakdown by visit type
  const typeStats = db.prepare(`
    SELECT visit_type, COUNT(*) as count 
    FROM visits 
    GROUP BY visit_type
  `).all();

  if (typeStats.length > 0) {
    console.log('\nVisits by Type:');
    console.table(typeStats);
  }

  // 4. Breakdown by urgency
  const urgencyStats = db.prepare(`
    SELECT urgency_level, COUNT(*) as count 
    FROM visits 
    GROUP BY urgency_level
  `).all();

  if (urgencyStats.length > 0) {
    console.log('\nVisits by Urgency Level:');
    console.table(urgencyStats);
  }

} catch (err) {
  console.error('Failed to read database:', err.message);
} finally {
  console.log('\n========================================\n');
}
