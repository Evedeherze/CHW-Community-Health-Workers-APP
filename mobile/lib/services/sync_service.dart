// mobile/lib/services/sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/visit_record.dart';
import 'api_service.dart';
import 'storage_service.dart';

class SyncService extends ChangeNotifier {
  final StorageService storageService;
  final ApiService apiService;

  bool _isDeviceConnected = true;
  bool _isSimulatedOffline = false;
  bool _isSyncing = false;
  String? _lastError;
  int _pendingCount = 0;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncService({
    required this.storageService,
    required this.apiService,
  }) {
    _initConnectivity();
    refreshQueueCount();
  }

  bool get isOnline => _isDeviceConnected && !_isSimulatedOffline;
  bool get isSimulatedOffline => _isSimulatedOffline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  String? get lastError => _lastError;

  void _initConnectivity() {
    Connectivity().checkConnectivity().then((results) {
      _isDeviceConnected = !results.contains(ConnectivityResult.none);
      notifyListeners();
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = isOnline;
      _isDeviceConnected = !results.contains(ConnectivityResult.none);
      notifyListeners();

      if (!wasOnline && isOnline) {
        autoSync();
      }
    });
  }

  /// Toggles simulated offline mode (for judging protocol stress testing)
  void setSimulatedOffline(bool simulate) {
    if (_isSimulatedOffline == simulate) return;
    _isSimulatedOffline = simulate;
    notifyListeners();

    if (isOnline) {
      autoSync();
    }
  }

  Future<void> refreshQueueCount() async {
    final queue = await storageService.getPendingQueue();
    _pendingCount = queue.length;
    notifyListeners();
  }

  /// Adds a new visit to local storage and attempts immediate sync if online
  Future<void> saveRecordLocallyAndTrySync(VisitRecord record) async {
    await storageService.addRecord(record);
    await refreshQueueCount();

    if (isOnline) {
      await flushQueue();
    }
  }

  /// Auto-sync helper
  Future<void> autoSync() async {
    if (!isOnline || _isSyncing) return;
    await flushQueue();
  }

  /// Flushes all pending records to the backend ingestion API
  Future<SyncResponse?> flushQueue() async {
    if (!isOnline) {
      _lastError = 'Cannot sync while offline';
      notifyListeners();
      return null;
    }

    final queue = await storageService.getPendingQueue();
    if (queue.isEmpty) {
      _pendingCount = 0;
      notifyListeners();
      return null;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    await storageService.markQueueAsSyncing();

    try {
      final response = await apiService.syncBatch(queue);
      if (response.success) {
        await storageService.removeRecords(response.handledIds);
      }
      await refreshQueueCount();
      return response;
    } catch (e) {
      _lastError = e.toString();
      await storageService.markQueueAsPending();
      await refreshQueueCount();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
