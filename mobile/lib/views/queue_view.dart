// mobile/lib/views/queue_view.dart
import 'package:flutter/material.dart';
import '../models/visit_record.dart';
import '../services/sync_service.dart';

class QueueView extends StatefulWidget {
  final SyncService syncService;

  const QueueView({super.key, required this.syncService});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  List<VisitRecord> _queue = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();
    widget.syncService.addListener(_onSyncServiceUpdated);
  }

  @override
  void dispose() {
    widget.syncService.removeListener(_onSyncServiceUpdated);
    super.dispose();
  }

  void _onSyncServiceUpdated() {
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final records = await widget.syncService.storageService.getPendingQueue();
    if (mounted) {
      setState(() {
        _queue = records;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerSync() async {
    try {
      final res = await widget.syncService.flushQueue();
      if (!mounted) return;
      if (res != null && res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully synced ${res.handledIds.length} records!'),
            backgroundColor: Colors.green[800],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e. Records remain queued locally.'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Local Sync Queue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${_queue.length} record(s) pending sync',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: (widget.syncService.isOnline && _queue.isNotEmpty && !widget.syncService.isSyncing)
                    ? _triggerSync
                    : null,
                icon: widget.syncService.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync),
                label: Text(widget.syncService.isSyncing ? 'Syncing...' : 'Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_queue.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'All records are synchronized!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No offline visits waiting to be uploaded.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _queue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final record = _queue[index];
                  return Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            record.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: record.syncStatus == 'Syncing'
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.syncStatus,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: record.syncStatus == 'Syncing' ? Colors.blue[300] : Colors.orange[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Village: ${record.villageName}  •  Type: ${record.visitType}',
                            style: TextStyle(color: Colors.grey[300], fontSize: 13),
                          ),
                          Text(
                            'BP: ${record.vitalsBp}  •  Temp: ${record.vitalsTemp}°C  •  Triage: ${record.urgencyLevel}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          Text(
                            'Local ID: ${record.localId}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
