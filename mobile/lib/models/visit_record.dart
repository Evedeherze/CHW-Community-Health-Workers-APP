// mobile/lib/models/visit_record.dart

class VisitRecord {
  final String localId;
  final String chwId;
  final String patientName;
  final String villageName;
  final String visitType;
  final String vitalsBp;
  final double vitalsTemp;
  final String urgencyLevel;
  final String visitNotes;
  final String createdAtLocal;
  final String syncStatus; // 'Pending', 'Syncing', 'Synced'

  VisitRecord({
    required this.localId,
    required this.chwId,
    required this.patientName,
    required this.villageName,
    required this.visitType,
    required this.vitalsBp,
    required this.vitalsTemp,
    required this.urgencyLevel,
    this.visitNotes = '',
    required this.createdAtLocal,
    this.syncStatus = 'Pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'chw_id': chwId,
      'patient_name': patientName,
      'village_name': villageName,
      'visit_type': visitType,
      'vitals_bp': vitalsBp,
      'vitals_temp': vitalsTemp,
      'urgency_level': urgencyLevel,
      'visit_notes': visitNotes,
      'created_at_local': createdAtLocal,
      'sync_status': syncStatus,
    };
  }

  factory VisitRecord.fromJson(Map<String, dynamic> json) {
    return VisitRecord(
      localId: json['local_id'] ?? '',
      chwId: json['chw_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      villageName: json['village_name'] ?? '',
      visitType: json['visit_type'] ?? 'General',
      vitalsBp: json['vitals_bp'] ?? '',
      vitalsTemp: (json['vitals_temp'] as num?)?.toDouble() ?? 37.0,
      urgencyLevel: json['urgency_level'] ?? 'Routine',
      visitNotes: json['visit_notes'] ?? '',
      createdAtLocal: json['created_at_local'] ?? DateTime.now().toIso8601String(),
      syncStatus: json['sync_status'] ?? 'Pending',
    );
  }

  VisitRecord copyWith({
    String? localId,
    String? chwId,
    String? patientName,
    String? villageName,
    String? visitType,
    String? vitalsBp,
    double? vitalsTemp,
    String? urgencyLevel,
    String? visitNotes,
    String? createdAtLocal,
    String? syncStatus,
  }) {
    return VisitRecord(
      localId: localId ?? this.localId,
      chwId: chwId ?? this.chwId,
      patientName: patientName ?? this.patientName,
      villageName: villageName ?? this.villageName,
      visitType: visitType ?? this.visitType,
      vitalsBp: vitalsBp ?? this.vitalsBp,
      vitalsTemp: vitalsTemp ?? this.vitalsTemp,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      visitNotes: visitNotes ?? this.visitNotes,
      createdAtLocal: createdAtLocal ?? this.createdAtLocal,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
