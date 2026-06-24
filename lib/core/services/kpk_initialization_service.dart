import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'kpk_optimized_map_service.dart';

/// Service to initialize KPK-specific optimizations on app startup
class KpkInitializationService {
  static bool _isInitialized = false;

  /// Initialize KPK optimizations
  static Future<void> initialize() async {
    if (_isInitialized) return;

    developer.log('Initializing KPK optimizations...');

    try {
      // Check if we have internet connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = connectivity != ConnectivityResult.none;

      if (hasInternet) {
        // Preload KPK data in background (don't await to avoid blocking app startup)
        _preloadKpkDataInBackground();
      } else {
        developer.log('No internet connection - skipping KPK data preload');
      }

      _isInitialized = true;
      developer.log('KPK optimizations initialized successfully');
    } catch (e) {
      developer.log('KPK initialization error: $e');
      // Don't throw - app should still work without optimizations
    }
  }

  /// Preload KPK data in background without blocking app startup
  static void _preloadKpkDataInBackground() {
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        developer.log('Starting background KPK data preload...');
        await KpkOptimizedMapService.preloadKpkData();
        developer.log('KPK data preload completed');
      } catch (e) {
        developer.log('Background preload error: $e');
      }
    });
  }

  /// Check if KPK optimizations are available
  static bool get isInitialized => _isInitialized;

  /// Get initialization status for debugging
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
