import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env_config.dart';

/// Service to check backend connectivity on app startup.
/// Helps diagnose connection issues immediately.
class BackendConnectivityService {
  static bool _hasChecked = false;
  static bool _isConnected = false;
  static String? _errorMessage;
  static Map<String, dynamic>? _serverInfo;

  static bool get isConnected => _isConnected;
  static String? get errorMessage => _errorMessage;
  static Map<String, dynamic>? get serverInfo => _serverInfo;

  /// Check if the backend is accessible.
  /// Call this on app startup to diagnose connectivity issues.
  static Future<bool> checkConnectivity() async {
    if (_hasChecked) {
      debugPrint('[Backend] Using cached connectivity result: $_isConnected');
      return _isConnected;
    }

    final backendUrl = EnvConfig.storageBackendUrl;
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 BACKEND CONNECTIVITY CHECK');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[Backend] Testing connection to: $backendUrl');
    debugPrint('[Backend] Endpoint: $backendUrl/api/debug/ping');

    try {
      final uri = Uri.parse('$backendUrl/api/debug/ping');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _isConnected = true;
        _serverInfo = data;
        _errorMessage = null;
        _hasChecked = true;

        debugPrint('✅ [Backend] Connection successful!');
        debugPrint('✅ [Backend] Server message: ${data['message']}');
        debugPrint(
            '✅ [Backend] Server uptime: ${data['server']?['uptime']} seconds');
        debugPrint(
            '✅ [Backend] Firebase initialized: ${data['firebase']?['initialized']}');
        debugPrint('═══════════════════════════════════════════════════════');
        return true;
      } else {
        _isConnected = false;
        _errorMessage = 'Server returned status ${response.statusCode}';
        _hasChecked = true;

        debugPrint('❌ [Backend] Connection failed!');
        debugPrint('❌ [Backend] Status code: ${response.statusCode}');
        debugPrint('❌ [Backend] Response: ${response.body}');
        debugPrint('═══════════════════════════════════════════════════════');
        return false;
      }
    } catch (e) {
      _isConnected = false;
      _errorMessage = e.toString();
      _hasChecked = true;

      debugPrint('❌ [Backend] Connection failed!');
      debugPrint('❌ [Backend] Error: $e');
      debugPrint('❌ [Backend] Backend URL: $backendUrl');
      debugPrint('');
      debugPrint('🔧 TROUBLESHOOTING:');
      debugPrint('   1. Is the backend server running?');
      debugPrint('      → Run: cd backend && npm run dev');
      debugPrint('   2. Check your .env file:');
      debugPrint('      → STORAGE_BACKEND_URL=$backendUrl');
      debugPrint('   3. For Android Emulator, use: http://10.0.2.2:3000');
      debugPrint(
          '   4. For Physical Device, use your PC IP: http://192.168.x.x:3000');
      debugPrint(
          '   5. Check firewall settings (Windows Defender may block port 3000)');
      debugPrint('═══════════════════════════════════════════════════════');
      return false;
    }
  }

  /// Reset the cached connectivity check (useful for retry)
  static void reset() {
    _hasChecked = false;
    _isConnected = false;
    _errorMessage = null;
    _serverInfo = null;
    debugPrint('[Backend] Connectivity check reset');
  }

  /// Get a user-friendly status message
  static String getStatusMessage() {
    if (!_hasChecked) {
      return 'Backend connectivity not checked yet';
    }

    if (_isConnected) {
      return '✅ Backend is accessible';
    }

    return '❌ Backend is not accessible: ${_errorMessage ?? "Unknown error"}';
  }

  /// Print detailed diagnostic information
  static void printDiagnostics() {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 BACKEND CONNECTIVITY DIAGNOSTICS');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Backend URL: ${EnvConfig.storageBackendUrl}');
    debugPrint('Has Checked: $_hasChecked');
    debugPrint('Is Connected: $_isConnected');
    debugPrint('Error Message: ${_errorMessage ?? "None"}');

    if (_serverInfo != null) {
      debugPrint('Server Info:');
      debugPrint('  - Message: ${_serverInfo!['message']}');
      debugPrint('  - Timestamp: ${_serverInfo!['timestamp']}');
      debugPrint('  - Port: ${_serverInfo!['server']?['port']}');
      debugPrint('  - Uptime: ${_serverInfo!['server']?['uptime']} seconds');
      debugPrint('  - Firebase: ${_serverInfo!['firebase']?['initialized']}');
    }

    debugPrint('═══════════════════════════════════════════════════════');
  }
}
