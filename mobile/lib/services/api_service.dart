// mobile/lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/visit_record.dart';

class ApiService {
  // Configurable base URL: uses page origin on web, 10.0.2.2 for Android emulator, localhost otherwise
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  String baseUrl;

  ApiService({String? url}) : baseUrl = url ?? defaultBaseUrl;

  /// Health check
  Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends batched records to the backend ingestion endpoint POST /api/sync
  Future<SyncResponse> syncBatch(List<VisitRecord> records) async {
    final payload = {
      'records': records.map((r) => r.toJson()).toList(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = (data['results'] as List<dynamic>?) ?? [];
      final List<String> successfullyHandledIds = [];

      for (final item in results) {
        final status = item['status'];
        final id = item['local_id'];
        if ((status == 'created' || status == 'duplicate') && id != null) {
          successfullyHandledIds.add(id as String);
        }
      }

      return SyncResponse(
        success: true,
        handledIds: successfullyHandledIds,
        rawResults: results,
      );
    } else {
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    }
  }

  /// Fetches central database records from GET /api/records
  Future<List<Map<String, dynamic>>> fetchServerRecords() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/records'),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final records = data['records'] as List<dynamic>?;
      return records != null ? List<Map<String, dynamic>>.from(records) : [];
    } else {
      throw Exception('Failed to fetch records: ${response.statusCode}');
    }
  }

  /// Resets server database (stress test evaluation reset)
  Future<void> resetServerDatabase() async {
    await http.post(Uri.parse('$baseUrl/api/reset')).timeout(const Duration(seconds: 5));
  }
}

class SyncResponse {
  final bool success;
  final List<String> handledIds;
  final List<dynamic> rawResults;

  SyncResponse({
    required this.success,
    required this.handledIds,
    required this.rawResults,
  });
}
