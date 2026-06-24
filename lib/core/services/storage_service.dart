import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:orginizeapp/core/services/firebase_service.dart';
import 'package:orginizeapp/core/services/local_storage_service.dart';
import 'package:orginizeapp/core/config/env_config.dart';

/// Storage Service — backed by the custom Node.js storage backend.
/// All image uploads go to the backend REST API.
/// Firebase/Firestore updates remain here (unchanged).
class StorageService {
  static String get _baseUrl => EnvConfig.storageBackendUrl;

  // ─── Upload helpers ────────────────────────────────────────────────────────

  /// Upload a [File] to the given [endpoint] with [fields].
  /// Returns the public URL string.
  static Future<String> _uploadFile({
    required String endpoint,
    required File file,
    required Map<String, String> fields,
  }) async {
    final compressed = await _compressImage(file);
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Optional API key header
    final apiKey = EnvConfig.storageApiKey;
    if (apiKey.isNotEmpty) {
      request.headers['x-api-key'] = apiKey;
    }

    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      compressed.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 201) {
      throw Exception('Upload failed (${streamed.statusCode}): $body');
    }

    // Parse {"url":"...","path":"..."}
    final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(body);
    if (urlMatch == null)
      throw Exception('Invalid response from storage server');
    return urlMatch.group(1)!;
  }

  /// Upload raw [Uint8List] bytes to the given [endpoint].
  static Future<String> _uploadBytes({
    required String endpoint,
    required Uint8List bytes,
    required String filename,
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    final apiKey = EnvConfig.storageApiKey;
    if (apiKey.isNotEmpty) {
      request.headers['x-api-key'] = apiKey;
    }

    request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 201) {
      throw Exception('Upload failed (${streamed.statusCode}): $body');
    }

    final urlMatch = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(body);
    if (urlMatch == null)
      throw Exception('Invalid response from storage server');
    return urlMatch.group(1)!;
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Upload delivery proof photo → updates Firestore order doc.
  static Future<String> uploadOrderProof({
    required File file,
    required String orderId,
  }) async {
    try {
      final publicUrl = await _uploadFile(
        endpoint: '/api/order-proofs',
        file: file,
        fields: {'orderId': orderId},
      );

      await FirebaseService.orders.doc(orderId).update({
        'deliveryProofUrl': publicUrl,
        'status': 'delivered',
        'deliveredAt': DateTime.now().toIso8601String(),
      });

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload order proof: $e');
    }
  }

  /// Upload item image → updates Firestore item doc.
  static Future<String> uploadItemImage({
    required File file,
    required String itemId,
  }) async {
    try {
      final publicUrl = await _uploadFile(
        endpoint: '/api/item-images',
        file: file,
        fields: {'itemId': itemId},
      );

      await FirebaseService.items.doc(itemId).update({'imageUrl': publicUrl});
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload item image: $e');
    }
  }

  /// Upload product image only (no Firestore update — caller saves the URL).
  static Future<String> uploadProductImageOnly({
    required File file,
    required String vendorId,
  }) async {
    try {
      return await _uploadFile(
        endpoint: '/api/item-images',
        file: file,
        fields: {'vendorId': vendorId},
      );
    } catch (e) {
      throw Exception('Failed to upload product image: $e');
    }
  }

  /// Upload venue photo → updates Firestore venue doc.
  static Future<String> uploadVenuePhoto({
    required File file,
    required String venueId,
  }) async {
    try {
      final publicUrl = await _uploadFile(
        endpoint: '/api/venue-photos',
        file: file,
        fields: {'venueId': venueId},
      );

      await FirebaseService.firestore
          .collection('peshawar_venues')
          .doc(venueId)
          .update({'photoUrl': publicUrl});

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload venue photo: $e');
    }
  }

  /// Upload identity document (CNIC, license, logo, cover, vehicle).
  static Future<String> uploadIdentityDocument({
    required File file,
    required String userId,
    required String docType,
  }) async {
    try {
      return await _uploadFile(
        endpoint: '/api/identity-docs',
        file: file,
        fields: {'userId': userId, 'docType': docType},
      );
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Upload profile image from raw bytes.
  static Future<String> uploadProfileImage({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    try {
      return await _uploadBytes(
        endpoint: '/api/profiles',
        bytes: imageBytes,
        filename: 'profile_$userId.jpg',
        fields: {'userId': userId},
      );
    } catch (e) {
      // Fallback to local storage if backend is unreachable
      debugPrint('Profile upload to backend failed, using local storage: $e');
      return await LocalStorageService.saveImage(
        imageName: 'profile_$userId.jpg',
        imageBytes: imageBytes,
      );
    }
  }

  // ─── Legacy / compatibility ────────────────────────────────────────────────

  static Future<String> uploadProductImage({
    required String productId,
    required Uint8List imageBytes,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp_product_$productId.jpg');
      await file.writeAsBytes(imageBytes);
      return await uploadItemImage(file: file, itemId: productId);
    } catch (e) {
      return await LocalStorageService.saveImage(
        imageName: 'product_$productId.jpg',
        imageBytes: imageBytes,
      );
    }
  }

  static Future<List<int>?> downloadImage(String filePath) async {
    if (filePath.startsWith('http')) return null;
    return await LocalStorageService.getImage(filePath);
  }

  static Future<String> uploadFile({
    required String fileName,
    required Uint8List fileBytes,
    String? folder,
  }) async {
    return await LocalStorageService.saveFile(
      fileName: fileName,
      bytes: fileBytes,
      subDirectory: folder ?? 'files',
    );
  }

  static Future<List<int>?> downloadFile(String filePath) async {
    return await LocalStorageService.readFile(filePath);
  }

  static Future<String> getCacheSize() async {
    final size = await LocalStorageService.getCacheSize();
    return LocalStorageService.formatBytes(size);
  }

  static Future<void> clearCache() async {
    await LocalStorageService.clearCache();
  }

  static Future<bool> imageExists(String filePath) async {
    return await LocalStorageService.fileExists(filePath);
  }

  static Future<bool> deleteImage(String filePath) async {
    return await LocalStorageService.deleteImage(filePath);
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  static Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('Compression failed: $e');
      return file;
    }
  }
}
