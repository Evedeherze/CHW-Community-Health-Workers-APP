// mobile/lib/views/home_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import 'queue_view.dart';
import 'server_records_view.dart';
import 'visit_form_view.dart';

class HomePage extends StatefulWidget {
  final SyncService syncService;
  final ApiService apiService;

  const HomePage({
    super.key,
    required this.syncService,
    required this.apiService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.syncService.addListener(_onSyncUpdate);
  }

  @override
  void dispose() {
    widget.syncService.removeListener(_onSyncUpdate);
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.syncService.isOnline;

    final List<Widget> pages = [
      VisitFormView(syncService: widget.syncService),
      QueueView(syncService: widget.syncService),
      ServerRecordsView(apiService: widget.apiService),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(105),
        child: AppBar(
          backgroundColor: const Color(0xFF064E3B),
          elevation: 2,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AfyaSync CHW Logger',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Community Health Services • East Africa',
                style: TextStyle(fontSize: 12, color: Color(0xFFA7F3D0)),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(38),
            child: Container(
              color: isOnline ? const Color(0xFF059669) : const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFFA7F3D0) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Simulate Offline:',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: widget.syncService.isSimulatedOffline,
                        activeThumbColor: Colors.amber,
                        onChanged: (val) {
                          widget.syncService.setSimulatedOffline(val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: const Color(0xFF64748B),
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'New Visit',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: widget.syncService.pendingCount > 0,
              label: Text('${widget.syncService.pendingCount}'),
              child: const Icon(Icons.schedule),
            ),
            activeIcon: Badge(
              isLabelVisible: widget.syncService.pendingCount > 0,
              label: Text('${widget.syncService.pendingCount}'),
              child: const Icon(Icons.watch_later),
            ),
            label: 'Queue',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storage_outlined),
            activeIcon: Icon(Icons.storage),
            label: 'Central DB',
          ),
        ],
      ),
    );
  }
}
