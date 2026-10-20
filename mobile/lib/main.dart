// mobile/lib/main.dart
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  final apiService = ApiService();
  final syncService = SyncService(
    storageService: storageService,
    apiService: apiService,
  );

  runApp(AfyaSyncApp(
    storageService: storageService,
    apiService: apiService,
    syncService: syncService,
  ));
}

class AfyaSyncApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;
  final SyncService syncService;

  const AfyaSyncApp({
    super.key,
    required this.storageService,
    required this.apiService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfyaSync - Offline-First CHW',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4FBF7),
        primaryColor: const Color(0xFF059669),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF059669),
          secondary: Color(0xFF10B981),
          surface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      home: HomePage(
        syncService: syncService,
        apiService: apiService,
      ),
    );
  }
}
