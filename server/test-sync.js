// server/test-sync.js
const fs = require('fs');
const path = require('path');

async function runTest() {
  const testFile = path.join(__dirname, '..', 'test.json');
  console.log(`\n========================================`);
  console.log(`  AFYASYNC OFFLINE-FIRST BACKEND TEST  `);
  console.log(`========================================\n`);

  if (!fs.existsSync(testFile)) {
    console.error(`Error: test.json not found at ${testFile}`);
    process.exit(1);
  }

  const payload = JSON.parse(fs.readFileSync(testFile, 'utf8'));
  console.log(`Loaded payload from test.json with ${payload.records.length} record(s):`);
  console.log(JSON.stringify(payload, null, 2));

  const BASE_URL = 'http://localhost:3000';

  // 1. Health check
  console.log(`\n--- 1. Testing GET /health ---`);
  try {
    const healthRes = await fetch(`${BASE_URL}/health`);
    const healthData = await healthRes.json();
    console.log(`Response [${healthRes.status}]:`, healthData);
  } catch (err) {
    console.error('Failed to connect to server. Ensure server is running on port 3000.', err.message);
    process.exit(1);
  }

  // 2. Sync test.json
  console.log(`\n--- 2. Testing POST /api/sync with test.json ---`);
  const syncRes = await fetch(`${BASE_URL}/api/sync`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  const syncData = await syncRes.json();
  console.log(`Response [${syncRes.status}]:`, JSON.stringify(syncData, null, 2));

  // 3. Idempotency test (re-sending same payload)
  console.log(`\n--- 3. Testing Idempotency (re-sending identical payload) ---`);
  const dupRes = await fetch(`${BASE_URL}/api/sync`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  const dupData = await dupRes.json();
  console.log(`Duplicate Response [${dupRes.status}]:`, JSON.stringify(dupData, null, 2));
  const isDuplicate = dupData.results && dupData.results[0] && dupData.results[0].status === 'duplicate';
  console.log(`Idempotency check: ${isDuplicate ? 'PASSED (status: duplicate)' : 'FAILED'}`);

  // 4. Validation error test
  console.log(`\n--- 4. Testing Validation Rejection (invalid record) ---`);
  const invalidPayload = {
    records: [
      {
        local_id: "invalid-record-001",
        chw_id: "CHW-TEST",
        patient_name: "A", // too short (min length 2)
        village_name: "Shibuye",
        visit_type: "UnknownType", // invalid enum
        vitals_bp: "999/999", // out of physiological range
        vitals_temp: 45.0, // out of 35.0 - 43.0 range
        urgency_level: "SuperEmergency", // invalid enum
        created_at_local: "invalid-date"
      }
    ]
  };
  const invalidRes = await fetch(`${BASE_URL}/api/sync`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(invalidPayload)
  });
  const invalidData = await invalidRes.json();
  console.log(`Invalid Record Response [${invalidRes.status}]:`, JSON.stringify(invalidData, null, 2));

  // 5. Query /api/records
  console.log(`\n--- 5. Testing GET /api/records ---`);
  const recordsRes = await fetch(`${BASE_URL}/api/records`);
  const recordsData = await recordsRes.json();
  const records = Array.isArray(recordsData) ? recordsData : recordsData.records;
  console.log(`Total records in DB: ${records.length}`);
  console.log(`Records:`, JSON.stringify(records, null, 2));

  console.log(`\n========================================`);
  console.log(`  ALL BACKEND TESTS EXECUTED SUCCESSFULLY `);
  console.log(`========================================\n`);
}

runTest().catch(err => {
  console.error('Test execution error:', err);
  process.exit(1);
});
