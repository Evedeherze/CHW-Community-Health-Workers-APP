/ server/server.js
    const express = require('express');
    const cors = require('cors');
    const path = require('path');
    const db = require('./db');
    const { validateRecord } = require('./validator');

    const app = express();

    // ---------- Middleware ----------
    app.use(cors());
    app.use(express.json({ limit: '5mb' }));

    // ---------- Prepared Statements & Transactions ----------
    const insertVisit = db.prepare(`
      INSERT INTO visits (
        local_id, chw_id, patient_name, village_name, visit_type,
        vitals_bp, vitals_temp, urgency_level, visit_notes, created_at_local
      ) VALUES (
        @local_id, @chw_id, @patient_name, @village_name, @visit_type,
        @vitals_bp, @vitals_temp, @urgency_level, @visit_notes, @created_at_local
      )
      ON CONFLICT(local_id) DO NOTHING
    `);

    const processBatch = db.transaction((records) => {
      const results = [];
      for (const r of records) {
        const { valid, errors } = validateRecord(r);
        if (!valid) {
          results.push({
            local_id: r.local_id || null,
            status: 'invalid',
            errors
          });
          continue;
        }

        const info = insertVisit.run({
          local_id: r.local_id,
          chw_id: r.chw_id,
          patient_name: r.patient_name,
          village_name: r.village_name,
          visit_type: r.visit_type,
          vitals_bp: r.vitals_bp ?? null,
          vitals_temp: r.vitals_temp !== undefined && r.vitals_temp !== '' ? Number(r.vitals_temp) : null,
          urgency_level: r.urgency_level,
          visit_notes: r.visit_notes ?? null,
          created_at_local: r.created_at_local
        });

        results.push({
          local_id: r.local_id,
          status: info.changes === 1 ? 'created' : 'duplicate'
        });
      }
      return results;
    });

    // ---------- Routes ----------
    app.get('/health', (req, res) => {
      res.json({ ok: true, status: 'ok' });
    });

    app.get('/api/records', (req, res) => {
      try {
        const rows = db.prepare('SELECT * FROM visits ORDER BY created_at_local DESC').all();
        res.json(rows);
      } catch (err) {
        res.status(500).json({ error: err.message });
      }
    });

    app.post('/api/sync', (req, res) => {
      const { records } = req.body;

      if (!Array.isArray(records)) {
        return res.status(400).json({ error: 'Body must contain a records array' });
      }

      try {
        const results = processBatch(records);
        res.json({ results });
      } catch (err) {
        console.error('Batch sync failure:', err);
        res.status(500).json({ error: 'Internal server error processing sync batch' });
      }
    });