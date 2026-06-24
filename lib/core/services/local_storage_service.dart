import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Local Storage Service
/// Handles local file storage and SharedPreferences
/// This is a temporary solution until server storage is implemented
class LocalStorageService {
  static SharedPreferences? _prefs;

  /// Initialize the service
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception(
          'LocalStorageService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ==================== KEY-VALUE STORAGE ====================

  /// Save string value
  static Future<bool> saveString(String key, String value) async {
    return await prefs.setString(key, value);
  }

  /// Get string value
  static String? getString(String key) {
    return prefs.getString(key);
  }

  /// Save int value
  static Future<bool> saveInt(String key, int value) async {
    return await prefs.setInt(key, value);
  }

  /// Get int value
  static int? getInt(String key) {
    return prefs.getInt(key);
  }

  /// Save bool value
  static Future<bool> saveBool(String key, bool value) async {
    return await prefs.setBool(key, value);
  }

  /// Get bool value
  static bool? getBool(String key) {
    return prefs.getBool(key);
  }

  /// Save double value
  static Future<bool> saveDouble(String key, double value) async {
    return await prefs.setDouble(key, value);
  }

  /// Get double value
  static double? getDouble(String key) {
    return prefs.getDouble(key);
  }

  /// Save list of strings
  static Future<bool> saveStringList(String key, List<String> value) async {
    return await prefs.setStringList(key, value);
  }

  /// Get list of strings
  static List<String>? getStringList(String key) {
    return prefs.getStringList(key);
  }

  /// Save JSON object
  static Future<bool> saveJson(String key, Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    return await prefs.setString(key, jsonString);
  }

  /// Get JSON object
  static Map<String, dynamic>? getJson(String key) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Remove a key
  static Future<bool> remove(String key) async {
    return await prefs.remove(key);
  }

  /// Clear all data
  static Future<bool> clearAll() async {
    return await prefs.clear();
  }

  /// Check if key exists
  static bool containsKey(String key) {
    return prefs.containsKey(key);
  }

  // ==================== FILE STORAGE ====================

  /// Get application documents directory
  static Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get temporary directory
  static Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  /// Save file to local storage
  /// Returns the file path
  static Future<String> saveFile({
    required String fileName,
    required List<int> bytes,
    String? subDirectory,
  }) async {
    try {
      final directory = await getAppDirectory();
      String path = directory.path;

      // Create subdirectory if specified
      if (subDirectory != null) {
        path = '$path/$subDirectory';
        final subDir = Directory(path);
        if (!await subDir.exists()) {
          await subDir.create(recursive: true);
        }
      }

      final filePath = '$path/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  /// Read file from local storage
  static Future<List<int>?> readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  /// Delete file from local storage
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size in bytes
  static Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== IMAGE STORAGE ====================

  /// Save image to local storage
  /// Returns the file path
  static Future<String> saveImage({
    required String imageName,
    required List<int> imageBytes,
  }) async {
    return await saveFile(
      fileName: imageName,
      bytes: imageBytes,
      subDirectory: 'images',
    );
  }

  /// Get image from local storage
  static Future<List<int>?> getImage(String imagePath) async {
    return await readFile(imagePath);
  }

  /// Delete image from local storage
  static Future<bool> deleteImage(String imagePath) async {
    return await deleteFile(imagePath);
  }

  // ==================== USER DATA STORAGE ====================

  /// Save user profile data
  static Future<bool> saveUserProfile(Map<String, dynamic> userData) async {
    return await saveJson('user_profile', userData);
  }

  /// Get user profile data
  static Map<String, dynamic>? getUserProfile() {
    return getJson('user_profile');
  }

  /// Clear user profile data
  static Future<bool> clearUserProfile() async {
    return await remove('user_profile');
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear cache directory
  static Future<void> clearCache() async {
    try {
      final tempDir = await getTempDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
      }
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTempDirectory();
      int totalSize = 0;

      if (await tempDir.exists()) {
        await for (var entity in tempDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
