import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class ImageUploadHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Show image picker dialog and upload to storage backend
  static Future<String?> pickAndUploadImage({
    required BuildContext context,
    required String uploadType, // 'order-proof', 'item-image', 'venue-photo'
    required String itemId,
    String? title,
  }) async {
    try {
      // Show picker options
      final source = await _showImageSourceDialog(context);
      if (source == null) return null;

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return null;

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Uploading image...'),
              ],
            ),
          ),
        );
      }

      // Upload based on type
      String? imageUrl;
      final file = File(image.path);

      switch (uploadType) {
        case 'order-proof':
          imageUrl = await StorageService.uploadOrderProof(
            file: file,
            orderId: itemId,
          );
          break;
        case 'item-image':
          imageUrl = await StorageService.uploadItemImage(
            file: file,
            itemId: itemId,
          );
          break;
        case 'venue-photo':
          imageUrl = await StorageService.uploadVenuePhoto(
            file: file,
            venueId: itemId,
          );
          break;
        default:
          throw Exception('Unknown upload type: $uploadType');
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${title ?? 'Image'} uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return imageUrl;
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    }
  }

  /// Show dialog to choose image source
  static Future<ImageSource?> _showImageSourceDialog(
      BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Upload profile image (using local storage for now)
  static Future<String?> uploadProfileImage({
    required BuildContext context,
    required String userId,
  }) async {
    try {
      final source = await _showImageSourceDialog(context);
      if (source == null) return null;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return null;

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Uploading profile image...'),
              ],
            ),
          ),
        );
      }

      // Read image bytes and upload
      final bytes = await image.readAsBytes();
      final imageUrl = await StorageService.uploadProfileImage(
        userId: userId,
        imageBytes: bytes,
      );

      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return imageUrl;
    } catch (e) {
      // Close loading if open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    }
  }
}
