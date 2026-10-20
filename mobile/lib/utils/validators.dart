// mobile/lib/utils/validators.dart

class FormValidators {
  static final RegExp bpRegex = RegExp(r'^\d{2,3}\/\d{2,3}$');

  static String? validatePatientName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Patient name is required';
    }
    if (value.trim().length < 2) {
      return 'Patient name must be at least 2 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateBp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Blood pressure is required';
    }
    final trimmed = value.trim();
    if (!bpRegex.hasMatch(trimmed)) {
      return 'Must be SYS/DIA format (e.g. 120/80)';
    }
    final parts = trimmed.split('/');
    final sys = int.tryParse(parts[0]);
    final dia = int.tryParse(parts[1]);
    if (sys == null || dia == null || sys < 50 || sys > 260 || dia < 30 || dia > 180) {
      return 'Values outside realistic physiological range';
    }
    return null;
  }

  static String? validateTemp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Temperature is required';
    }
    final temp = double.tryParse(value.trim());
    if (temp == null) {
      return 'Must be a valid numeric temperature';
    }
    if (temp < 35.0 || temp > 43.0) {
      return 'Temperature must be between 35.0°C and 43.0°C';
    }
    return null;
  }
}
