// client/app.js

const QUEUE_STORAGE_KEY = 'chw_pending_records';

// State
let isSimulatedOffline = false;
let isSyncing = false;

// DOM Elements
const statusBar = document.getElementById('statusBar');
const statusText = document.getElementById('statusText');
const simToggle = document.getElementById('simToggle');
const queueCountEl = document.getElementById('queueCount');
const queueListEl = document.getElementById('queueList');
const syncNowBtn = document.getElementById('syncNowBtn');
const refreshServerBtn = document.getElementById('refreshServerBtn');
const clearServerBtn = document.getElementById('clearServerBtn');
const serverListEl = document.getElementById('serverList');
const visitForm = document.getElementById('visitForm');
const toastEl = document.getElementById('toast');
const localIdEl = document.getElementById('local_id');
const newIdBtn = document.getElementById('newIdBtn');

// ---------- Helpers & Notifications ----------

function showToast(message, duration = 3000) {
  toastEl.textContent = message;
  toastEl.classList.add('show');
  setTimeout(() => {
    toastEl.classList.remove('show');
  }, duration);
}

function generateLocalId() {
  if (window.crypto && crypto.randomUUID) {
    return 'chw-' + crypto.randomUUID();
  }
  return 'client-uuid-' + Date.now() + '-' + Math.random().toString(36).substring(2, 8);
}

function allocateNewEntryId() {
  const newId = generateLocalId();
  if (localIdEl) {
    localIdEl.value = newId;
  }
  return newId;
}

if (newIdBtn) {
  newIdBtn.addEventListener('click', () => {
    const id = allocateNewEntryId();
    showToast(`Allocated new ID: ${id}`);
  });
}

// ---------- Network Observer ----------

function isAppOnline() {
  return navigator.onLine && !isSimulatedOffline;
}

function updateNetworkUI() {
  const online = isAppOnline();
  if (online) {
    statusBar.classList.remove('offline');
    statusBar.classList.add('online');
    statusText.textContent = 'ONLINE';
    syncNowBtn.disabled = getPendingQueue().length === 0 || isSyncing;
  } else {
    statusBar.classList.remove('online');
    statusBar.classList.add('offline');
    statusText.textContent = 'OFFLINE';
    syncNowBtn.disabled = true;
  }
}

window.addEventListener('online', () => {
  updateNetworkUI();
  showToast('Network restored: System is ONLINE');
  autoSyncQueue();
});

window.addEventListener('offline', () => {
  updateNetworkUI();
  showToast('Network disconnected: System is OFFLINE');
});

simToggle.addEventListener('change', (e) => {
  isSimulatedOffline = e.target.checked;
  updateNetworkUI();
  if (isSimulatedOffline) {
    showToast('Simulated Disconnect: System is OFFLINE');
  } else {
    showToast('Simulated Reconnect: System is ONLINE');
    autoSyncQueue();
  }
});

// ---------- Queue Manager (LocalStorage Engine) ----------

function getPendingQueue() {
  try {
    const raw = localStorage.getItem(QUEUE_STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch (err) {
    console.error('Failed to read queue from localStorage', err);
    return [];
  }
}

function savePendingQueue(queue) {
  try {
    localStorage.setItem(QUEUE_STORAGE_KEY, JSON.stringify(queue));
    renderQueue();
    updateNetworkUI();
  } catch (err) {
    console.error('Failed to write queue to localStorage', err);
    showToast('Storage error: unable to save locally');
  }
}

function addToQueue(record) {
  const queue = getPendingQueue();
  queue.push(record);
  savePendingQueue(queue);
}

function removeFromQueue(localIds) {
  const idSet = new Set(localIds);
  const queue = getPendingQueue().filter(r => !idSet.has(r.local_id));
  savePendingQueue(queue);
}

function renderQueue() {
  const queue = getPendingQueue();
  queueCountEl.textContent = queue.length;

  if (queue.length === 0) {
    queueListEl.className = 'queue-list empty-state';
    queueListEl.innerHTML = '<p>No records currently pending sync.</p>';
    syncNowBtn.disabled = true;
    return;
  }

  queueListEl.className = 'queue-list';
  queueListEl.innerHTML = queue.map(r => `
    <div class="record-item">
      <div class="record-top">
        <span class="record-name">${escapeHtml(r.patient_name)} (${escapeHtml(r.village_name)})</span>
        <span class="status-badge ${r.sync_status.toLowerCase()}">${escapeHtml(r.sync_status)}</span>
      </div>
      <div class="record-meta">
        <span><strong>Type:</strong> ${escapeHtml(r.visit_type)}</span>
        <span><strong>BP:</strong> ${escapeHtml(r.vitals_bp)}</span>
        <span><strong>Temp:</strong> ${r.vitals_temp}°C</span>
        <span class="record-urgency ${escapeHtml(r.urgency_level)}">${escapeHtml(r.urgency_level)}</span>
        <span><strong>CHW:</strong> ${escapeHtml(r.chw_id)}</span>
      </div>
    </div>
  `).join('');

  if (isAppOnline() && !isSyncing) {
    syncNowBtn.disabled = false;
  }
}

// ---------- Client-side Form Validation ----------

function validateForm() {
  let isValid = true;

  // Clear previous errors
  document.querySelectorAll('.field-error').forEach(el => el.textContent = '');

  const chwId = document.getElementById('chw_id').value.trim();
  const villageName = document.getElementById('village_name').value.trim();
  const patientName = document.getElementById('patient_name').value.trim();
  const visitType = document.getElementById('visit_type').value;
  const urgencyLevel = document.getElementById('urgency_level').value;
  const vitalsBp = document.getElementById('vitals_bp').value.trim();
  const vitalsTemp = parseFloat(document.getElementById('vitals_temp').value);

  if (!chwId) {
    document.getElementById('err-chw_id').textContent = 'CHW ID is required';
    isValid = false;
  }

  if (!villageName) {
    document.getElementById('err-village_name').textContent = 'Village name is required';
    isValid = false;
  }

  if (!patientName || patientName.length < 2) {
    document.getElementById('err-patient_name').textContent = 'Patient name must be at least 2 characters';
    isValid = false;
  }

  if (!visitType) {
    document.getElementById('err-visit_type').textContent = 'Visit type is required';
    isValid = false;
  }

  if (!urgencyLevel) {
    document.getElementById('err-urgency_level').textContent = 'Urgency level is required';
    isValid = false;
  }

  const bpRegex = /^\d{2,3}\/\d{2,3}$/;
  if (!vitalsBp || !bpRegex.test(vitalsBp)) {
    document.getElementById('err-vitals_bp').textContent = 'Must be SYS/DIA format (e.g. 120/80)';
    isValid = false;
  }

  if (isNaN(vitalsTemp) || vitalsTemp < 35.0 || vitalsTemp > 43.0) {
    document.getElementById('err-vitals_temp').textContent = 'Temperature must be between 35.0 and 43.0 °C';
    isValid = false;
  }

  return isValid;
}

// ---------- Form Submission & Persistence ----------

visitForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  if (!validateForm()) {
    showToast('Please correct form errors before saving');
    return;
  }

  const assignedId = (localIdEl && localIdEl.value.trim()) || generateLocalId();

  const record = {
    local_id: assignedId,
    chw_id: document.getElementById('chw_id').value.trim(),
    patient_name: document.getElementById('patient_name').value.trim(),
    village_name: document.getElementById('village_name').value.trim(),
    visit_type: document.getElementById('visit_type').value,
    vitals_bp: document.getElementById('vitals_bp').value.trim(),
    vitals_temp: parseFloat(document.getElementById('vitals_temp').value),
    urgency_level: document.getElementById('urgency_level').value,
    visit_notes: document.getElementById('visit_notes').value.trim(),
    created_at_local: new Date().toISOString(),
    sync_status: 'Pending'
  };

  // Immediate local write (Zero Data Loss Guarantee)
  addToQueue(record);
  showToast(`Saved locally: ${record.patient_name} [ID: ${record.local_id}]`);

  // Immediately allocate a fresh, new unique ID for the next entry
  allocateNewEntryId();

  // Reset form inputs (keep CHW ID and village for rapid entry)
  document.getElementById('patient_name').value = '';
  document.getElementById('vitals_bp').value = '';
  document.getElementById('vitals_temp').value = '';
  document.getElementById('visit_notes').value = '';
  document.getElementById('patient_name').focus();

  // If online, immediately trigger background sync
  if (isAppOnline()) {
    await syncQueueToServer();
  }
});

// ---------- Synchronization Engine ----------

async function syncQueueToServer() {
  const queue = getPendingQueue();
  if (queue.length === 0 || !isAppOnline() || isSyncing) {
    return;
  }

  isSyncing = true;
  syncNowBtn.disabled = true;
  syncNowBtn.innerHTML = '<span class="icon">⏳</span> Syncing...';

  // Mark all pending as Syncing
  const markedQueue = queue.map(r => ({ ...r, sync_status: 'Syncing' }));
  savePendingQueue(markedQueue);

  try {
    const res = await fetch('/api/sync', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ records: markedQueue })
    });

    if (!res.ok) {
      throw new Error(`Server returned HTTP ${res.status}`);
    }

    const data = await res.json();
    if (Array.isArray(data.results)) {
      const successfulIds = data.results
        .filter(item => item.status === 'created' || item.status === 'duplicate')
        .map(item => item.local_id);

      removeFromQueue(successfulIds);
      showToast(`Sync successful: ${successfulIds.length} records processed`);
      fetchServerRecords();
    } else {
      throw new Error(data.error || 'Sync failed');
    }
  } catch (err) {
    console.error('Sync failed:', err);
    showToast(`Sync failed: ${err.message}. Records remain queued locally.`);
    // Revert status to Pending
    const reverted = getPendingQueue().map(r => ({ ...r, sync_status: 'Pending' }));
    savePendingQueue(reverted);
  } finally {
    isSyncing = false;
    syncNowBtn.innerHTML = '<span class="icon">🔄</span> Sync Queue to Server';
    updateNetworkUI();
  }
}

function autoSyncQueue() {
  if (isAppOnline() && getPendingQueue().length > 0) {
    syncQueueToServer();
  }
}

syncNowBtn.addEventListener('click', () => {
  syncQueueToServer();
});

// ---------- Server Records Viewer ----------

async function fetchServerRecords() {
  try {
    serverListEl.innerHTML = '<p class="text-muted">Fetching records from server...</p>';
    const res = await fetch('/api/records');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    const records = Array.isArray(data) ? data : (data.records || []);

    if (records.length === 0) {
      serverListEl.className = 'server-list empty-state';
      serverListEl.innerHTML = '<p>No records in server database yet.</p>';
      return;
    }

    serverListEl.className = 'server-list';
    serverListEl.innerHTML = records.map(r => `
      <div class="record-item">
        <div class="record-top">
          <span class="record-name">${escapeHtml(r.patient_name)} (${escapeHtml(r.village_name)})</span>
          <span class="status-badge synced">Synced</span>
        </div>
        <div class="record-meta">
          <span><strong>Type:</strong> ${escapeHtml(r.visit_type)}</span>
          <span><strong>BP:</strong> ${escapeHtml(r.vitals_bp)}</span>
          <span><strong>Temp:</strong> ${r.vitals_temp}°C</span>
          <span class="record-urgency ${escapeHtml(r.urgency_level)}">${escapeHtml(r.urgency_level)}</span>
          <span><strong>Local ID:</strong> ${escapeHtml(r.local_id)}</span>
        </div>
      </div>
    `).join('');
  } catch (err) {
    serverListEl.className = 'server-list empty-state';
    serverListEl.innerHTML = `<p class="field-error">Could not connect to server: ${escapeHtml(err.message)}</p>`;
  }
}

refreshServerBtn.addEventListener('click', () => {
  fetchServerRecords();
});

clearServerBtn.addEventListener('click', async () => {
  if (!confirm('Clear all central database records for stress test reset?')) return;
  try {
    const res = await fetch('/api/reset', { method: 'POST' });
    const data = await res.json();
    showToast(data.message || 'Server records cleared');
    fetchServerRecords();
  } catch (err) {
    showToast(`Reset failed: ${err.message}`);
  }
});

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// Initial bootstrap
allocateNewEntryId();
updateNetworkUI();
renderQueue();
fetchServerRecords();
