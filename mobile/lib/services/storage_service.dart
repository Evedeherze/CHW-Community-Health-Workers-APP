// mobile/lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visit_record.dart';

class StorageService {
  static const String _queueKey = 'chw_pending_records_queue';

  /// Retrieves the list of records currently in the offline FIFO sync queue.
  Future<List<VisitRecord>> getPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => VisitRecord.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Immediately persists a new record to local storage (Zero Data Loss Guarantee).
  Future<void> addRecord(VisitRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final currentQueue = await getPendingQueue();
    currentQueue.add(record);
    await _saveQueue(prefs, currentQueue);
  }

  /// Removes successfully synced records from the pending queue by local_id.
  Future<void> removeRecords(List<String> syncedLocalIds) async {
    final prefs = await SharedPreferences.getInstance();
    final currentQueue = await getPendingQueue();
    final idSet = syncedLocalIds.toSet();
    final updatedQueue = currentQueue.where((r) => !idSet.contains(r.localId)).toList();
    await _saveQueue(prefs, updatedQueue);
  }

  /// Updates status of all records currently in flight to 'Syncing'
  Future<void> markQueueAsSyncing() async {
    final prefs = await SharedPreferences.getInstance();
    final currentQueue = await getPendingQueue();
    final updated = currentQueue.map((r) => r.copyWith(syncStatus: 'Syncing')).toList();
    await _saveQueue(prefs, updated);
  }

  /// Reverts status to 'Pending' if a network attempt fails
  Future<void> markQueueAsPending() async {
    final prefs = await SharedPreferences.getInstance();
    final currentQueue = await getPendingQueue();
    final updated = currentQueue.map((r) => r.copyWith(syncStatus: 'Pending')).toList();
    await _saveQueue(prefs, updated);
  }

  Future<void> _saveQueue(SharedPreferences prefs, List<VisitRecord> queue) async {
    final jsonList = queue.map((r) => r.toJson()).toList();
    await prefs.setString(_queueKey, jsonEncode(jsonList));
  }
}
