// ignore_for_file: unused_element, avoid_print

import 'dart:typed_data';
import 'storage_service.dart';
import 'local_storage_service.dart';

/// Storage Service Usage Examples
/// This file demonstrates how to use the storage services in your app
///
/// DELETE THIS FILE before production - it's just for reference

class StorageExamples {
  // ==================== IMAGE STORAGE EXAMPLES ====================

  /// Example: Upload user profile image
  static Future<void> uploadProfileImageExample() async {
    // Simulate image bytes (in real app, get from ImagePicker)
    final Uint8List imageBytes = Uint8List.fromList([/* image data */]);

    try {
      // Upload profile image
      final imagePath = await StorageService.uploadProfileImage(
        userId: 'user123',
        imageBytes: imageBytes,
      );

      print('Profile image uploaded: $imagePath');

      // Save the path to user profile
      await LocalStorageService.saveString('user_profile_image', imagePath);
    } catch (e) {
      print('Error uploading profile image: $e');
    }
  }

  /// Example: Download and display profile image
  static Future<List<int>?> downloadProfileImageExample() async {
    try {
      // Get saved image path
      final imagePath = LocalStorageService.getString('user_profile_image');

      if (imagePath == null) {
        print('No profile image found');
        return null;
      }

      // Download image
      final imageData = await StorageService.downloadImage(imagePath);

      if (imageData != null) {
        print('Profile image downloaded: ${imageData.length} bytes');
        // Use imageData with Image.memory(imageData) in your UI
        return imageData;
      }
    } catch (e) {
      print('Error downloading profile image: $e');
    }

    return null;
  }

  /// Example: Upload product image
  static Future<String?> uploadProductImageExample(
    String productId,
    Uint8List imageBytes,
  ) async {
    try {
      final imagePath = await StorageService.uploadProductImage(
        productId: productId,
        imageBytes: imageBytes,
      );

      print('Product image uploaded: $imagePath');
      return imagePath;
    } catch (e) {
      print('Error uploading product image: $e');
      return null;
    }
  }

  // ==================== KEY-VALUE STORAGE EXAMPLES ====================

  /// Example: Save user preferences
  static Future<void> saveUserPreferencesExample() async {
    // Save simple values
    await LocalStorageService.saveString('username', 'john_doe');
    await LocalStorageService.saveBool('notifications_enabled', true);
    await LocalStorageService.saveInt('theme_mode', 1); // 0=light, 1=dark

    // Save complex data as JSON
    await LocalStorageService.saveJson('user_settings', {
      'language': 'en',
      'currency': 'USD',
      'location': {'lat': 28.6139, 'lng': 77.2090},
    });

    print('User preferences saved');
  }

  /// Example: Load user preferences
  static Future<void> loadUserPreferencesExample() async {
    // Load simple values
    final username = LocalStorageService.getString('username');
    final notificationsEnabled =
        LocalStorageService.getBool('notifications_enabled');
    final themeMode = LocalStorageService.getInt('theme_mode');

    // Load complex data
    final settings = LocalStorageService.getJson('user_settings');

    print('Username: $username');
    print('Notifications: $notificationsEnabled');
    print('Theme: $themeMode');
    print('Settings: $settings');
  }

  /// Example: Save user profile data
  static Future<void> saveUserProfileExample() async {
    final userData = {
      'id': 'user123',
      'name': 'John Doe',
      'email': 'john@example.com',
      'phone': '+1234567890',
      'role': 'host',
      'createdAt': DateTime.now().toIso8601String(),
    };

    await LocalStorageService.saveUserProfile(userData);
    print('User profile saved');
  }

  /// Example: Load user profile data
  static Future<Map<String, dynamic>?> loadUserProfileExample() async {
    final userData = LocalStorageService.getUserProfile();

    if (userData != null) {
      print('User profile loaded: ${userData['name']}');
      return userData;
    } else {
      print('No user profile found');
      return null;
    }
  }

  // ==================== FILE STORAGE EXAMPLES ====================

  /// Example: Save a document file
  static Future<String?> saveDocumentExample(
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      final filePath = await StorageService.uploadFile(
        fileName: fileName,
        fileBytes: fileBytes,
        folder: 'documents',
      );

      print('Document saved: $filePath');
      return filePath;
    } catch (e) {
      print('Error saving document: $e');
      return null;
    }
  }

  /// Example: Read a document file
  static Future<List<int>?> readDocumentExample(String filePath) async {
    try {
      final fileData = await StorageService.downloadFile(filePath);

      if (fileData != null) {
        print('Document loaded: ${fileData.length} bytes');
        return fileData;
      }
    } catch (e) {
      print('Error reading document: $e');
    }

    return null;
  }

  // ==================== CACHE MANAGEMENT EXAMPLES ====================

  /// Example: Clear app cache
  static Future<void> clearCacheExample() async {
    try {
      // Get cache size before clearing
      final sizeBefore = await StorageService.getCacheSize();
      print('Cache size before: $sizeBefore');

      // Clear cache
      await StorageService.clearCache();
      print('Cache cleared');

      // Get cache size after clearing
      final sizeAfter = await StorageService.getCacheSize();
      print('Cache size after: $sizeAfter');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Example: Check storage usage
  static Future<void> checkStorageUsageExample() async {
    final cacheSize = await StorageService.getCacheSize();
    print('Current cache size: $cacheSize');

    // Check if specific file exists
    final imagePath = LocalStorageService.getString('user_profile_image');
    if (imagePath != null) {
      final exists = await StorageService.imageExists(imagePath);
      print('Profile image exists: $exists');

      if (exists) {
        final size = await LocalStorageService.getFileSize(imagePath);
        if (size != null) {
          print('Profile image size: ${LocalStorageService.formatBytes(size)}');
        }
      }
    }
  }

  // ==================== CLEANUP EXAMPLES ====================

  /// Example: Logout and clear user data
  static Future<void> logoutExample() async {
    try {
      // Clear user profile
      await LocalStorageService.clearUserProfile();

      // Delete profile image
      final imagePath = LocalStorageService.getString('user_profile_image');
      if (imagePath != null) {
        await StorageService.deleteImage(imagePath);
      }

      // Clear specific keys
      await LocalStorageService.remove('username');
      await LocalStorageService.remove('user_profile_image');

      // Clear cache
      await StorageService.clearCache();

      print('User data cleared');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  /// Example: Delete old files
  static Future<void> cleanupOldFilesExample() async {
    // In a real app, you'd track file paths and delete old ones
    // This is just a conceptual example

    final oldImagePaths = [
      '/path/to/old/image1.jpg',
      '/path/to/old/image2.jpg',
    ];

    for (final path in oldImagePaths) {
      final exists = await StorageService.imageExists(path);
      if (exists) {
        await StorageService.deleteImage(path);
        print('Deleted old image: $path');
      }
    }
  }
}

// ==================== WIDGET USAGE EXAMPLES ====================

/// Example: How to use in a Flutter widget
/// 
/// ```dart
/// class ProfileScreen extends StatefulWidget {
///   @override
///   _ProfileScreenState createState() => _ProfileScreenState();
/// }
/// 
/// class _ProfileScreenState extends State<ProfileScreen> {
///   Uint8List? _profileImage;
///   bool _isLoading = false;
/// 
///   @override
///   void initState() {
///     super.initState();
///     _loadProfileImage();
///   }
/// 
///   Future<void> _loadProfileImage() async {
///     setState(() => _isLoading = true);
///     
///     final imagePath = LocalStorageService.getString('user_profile_image');
///     if (imagePath != null) {
///       final imageData = await StorageService.downloadImage(imagePath);
///       setState(() {
///         _profileImage = imageData;
///         _isLoading = false;
///       });
///     } else {
///       setState(() => _isLoading = false);
///     }
///   }
/// 
///   Future<void> _uploadProfileImage() async {
///     // Get image from ImagePicker
///     // final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
///     // if (image == null) return;
///     
///     // final bytes = await image.readAsBytes();
///     
///     setState(() => _isLoading = true);
///     
///     final imagePath = await StorageService.uploadProfileImage(
///       userId: 'user123',
///       imageBytes: bytes,
///     );
///     
///     await LocalStorageService.saveString('user_profile_image', imagePath);
///     
///     await _loadProfileImage();
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Profile')),
///       body: Center(
///         child: Column(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: [
///             if (_isLoading)
///               CircularProgressIndicator()
///             else if (_profileImage != null)
///               CircleAvatar(
///                 radius: 50,
///                 backgroundImage: MemoryImage(_profileImage!),
///               )
///             else
///               CircleAvatar(
///                 radius: 50,
///                 child: Icon(Icons.person, size: 50),
///               ),
///             SizedBox(height: 20),
///             ElevatedButton(
///               onPressed: _uploadProfileImage,
///               child: Text('Upload Profile Image'),
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
