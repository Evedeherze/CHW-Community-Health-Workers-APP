// mobile/test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chw_mobile/utils/validators.dart';
import 'package:chw_mobile/models/visit_record.dart';

void main() {
  group('CHW Hackathon Validation Tests', () {
    test('Patient name validation requires at least 2 characters', () {
      expect(FormValidators.validatePatientName(''), isNotNull);
      expect(FormValidators.validatePatientName('A'), isNotNull);
      expect(FormValidators.validatePatientName('Mary Atieno'), isNull);
    });

    test('Blood pressure validation enforces SYS/DIA format', () {
      expect(FormValidators.validateBp('120'), isNotNull);
      expect(FormValidators.validateBp('abc/def'), isNotNull);
      expect(FormValidators.validateBp('120/80'), isNull);
    });

    test('Body temperature validation enforces 35.0 to 43.0 C range', () {
      expect(FormValidators.validateTemp('34.9'), isNotNull);
      expect(FormValidators.validateTemp('43.1'), isNotNull);
      expect(FormValidators.validateTemp('37.2'), isNull);
    });
  });

  group('VisitRecord Model Serialization Tests', () {
    test('Converts correctly to and from JSON', () {
      final record = VisitRecord(
        localId: 'client-uuid-001',
        chwId: 'CHW-KKG-04',
        patientName: 'Mary Atieno',
        villageName: 'Shibuye',
        visitType: 'Maternal',
        vitalsBp: '120/80',
        vitalsTemp: 37.2,
        urgencyLevel: 'Routine',
        visitNotes: 'First antenatal checkup',
        createdAtLocal: '2026-10-16T08:30:00.000Z',
        syncStatus: 'Pending',
      );

      final json = record.toJson();
      expect(json['local_id'], 'client-uuid-001');
      expect(json['vitals_temp'], 37.2);

      final fromJson = VisitRecord.fromJson(json);
      expect(fromJson.localId, record.localId);
      expect(fromJson.patientName, record.patientName);
    });
  });
}
