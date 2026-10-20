// server/validator.js
const VISIT_TYPES = ['Maternal', 'Child', 'General'];
const URGENCY_LEVELS = ['Routine', 'Urgent', 'Emergency'];
const BP_REGEX = /^\d{2,3}\/\d{2,3}$/;

const isNonEmptyString = (v) => typeof v === 'string' && v.trim().length > 0;

function validateRecord(r) {
  const errors = [];

  if (!r || typeof r !== 'object') {
    return { valid: false, errors: ['record must be an object'] };
  }

  if (!isNonEmptyString(r.local_id)) errors.push('local_id is required');
  if (!isNonEmptyString(r.chw_id)) errors.push('chw_id is required');

  if (!isNonEmptyString(r.patient_name) || r.patient_name.trim().length < 2) {
    errors.push('patient_name is required (min 2 characters)');
  }

  if (!isNonEmptyString(r.village_name)) errors.push('village_name is required');

  if (!VISIT_TYPES.includes(r.visit_type)) {
    errors.push('visit_type must be Maternal, Child or General');
  }

  if (!URGENCY_LEVELS.includes(r.urgency_level)) {
    errors.push('urgency_level must be Routine, Urgent or Emergency');
  }

  if (r.vitals_bp != null && r.vitals_bp !== '') {
    if (typeof r.vitals_bp !== 'string' || !BP_REGEX.test(r.vitals_bp)) {
      errors.push('vitals_bp must look like 120/80');
    }
  }

  if (r.vitals_temp != null && r.vitals_temp !== '') {
    const t = Number(r.vitals_temp);
    if (Number.isNaN(t) || t < 35.0 || t > 43.0) {
      errors.push('vitals_temp must be a number between 35.0 and 43.0');
    }
  }

  if (r.visit_notes != null && typeof r.visit_notes !== 'string') {
    errors.push('visit_notes must be text');
  }

  if (!isNonEmptyString(r.created_at_local) || Number.isNaN(Date.parse(r.created_at_local))) {
    errors.push('created_at_local must be a valid ISO 8601 timestamp');
  }

  return { valid: errors.length === 0, errors };
}

module.exports = { validateRecord, VISIT_TYPES, URGENCY_LEVELS };