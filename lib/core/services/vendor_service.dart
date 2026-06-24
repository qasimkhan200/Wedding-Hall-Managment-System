import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor_model.dart';
import '../models/item_model.dart';
import 'firebase_service.dart';

class VendorService {
  // Get all approved vendors from users collection
  // Get all approved vendors from users collection
  static Stream<List<VendorModel>> getApprovedVendors() {
    return FirebaseService.users
        .where('role', isEqualTo: 'vendor')
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final userData = doc.data() as Map<String, dynamic>;
              // Convert user data to vendor model format
              return VendorModel(
                id: doc.id,
                userId: doc.id,
                businessName: userData['businessName'] ??
                    userData['name'] ??
                    'Unknown Business',
                description:
                    userData['description'] ?? 'Emergency supplies vendor',
                address: userData['address'] ?? '',
                latitude: userData['latitude']?.toDouble() ?? 0.0,
                longitude: userData['longitude']?.toDouble() ?? 0.0,
                phone: userData['phone'] ?? '',
                email: userData['email'] ?? '',
                categories: List<String>.from(
                    userData['categories'] ?? ['Emergency Supplies']),
                logoImage: userData['logoUrl'] ?? userData['profileImage'],
                isApproved: userData['isApproved'] ?? false,
                isActive: userData['isActive'] ?? true,
                rating: (userData['rating'] ?? 4.5).toDouble(),
                totalOrders: userData['totalOrders'] ?? 0,
                operatingHours:
                    Map<String, dynamic>.from(userData['businessHours'] ?? {}),
                createdAt: _parseDateTime(userData['createdAt']),
                updatedAt: _parseDateTime(userData['updatedAt']),
              );
            }).toList());
  }

  // Helper method to parse DateTime from various formats (same as UserModel)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) return value;

    try {
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
    } catch (e) {
      // Continue to other checks if Timestamp conversion fails
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return DateTime.fromMillisecondsSinceEpoch(intValue);
      }
    }

    return DateTime.now();
  }

  // Get vendor by ID from users collection
  static Future<VendorModel?> getVendor(String vendorId) async {
    try {
      final doc = await FirebaseService.users.doc(vendorId).get();
      if (!doc.exists) return null;

      final userData = doc.data() as Map<String, dynamic>;
      if (userData['role'] != 'vendor') return null;

      return VendorModel(
        id: doc.id,
        userId: doc.id,
        businessName:
            userData['businessName'] ?? userData['name'] ?? 'Unknown Business',
        description: userData['description'] ?? 'Emergency supplies vendor',
        address: userData['address'] ?? '',
        latitude: userData['latitude']?.toDouble() ?? 0.0,
        longitude: userData['longitude']?.toDouble() ?? 0.0,
        phone: userData['phone'] ?? '',
        email: userData['email'] ?? '',
        categories:
            List<String>.from(userData['categories'] ?? ['Emergency Supplies']),
        logoImage: userData['logoUrl'] ?? userData['profileImage'],
        isApproved: userData['isApproved'] ?? false,
        isActive: userData['isActive'] ?? true,
        rating: (userData['rating'] ?? 4.5).toDouble(),
        totalOrders: userData['totalOrders'] ?? 0,
        operatingHours:
            Map<String, dynamic>.from(userData['businessHours'] ?? {}),
        createdAt: _parseDateTime(userData['createdAt']),
        updatedAt: _parseDateTime(userData['updatedAt']),
      );
    } catch (e) {
      return null;
    }
  }

  // Get vendors by category from users collection
  static Stream<List<VendorModel>> getVendorsByCategory(String category) {
    return FirebaseService.users
        .where('role', isEqualTo: 'vendor')
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final userData = doc.data() as Map<String, dynamic>;
              // Helper to check category containment locally since simple array-contains can fail with complex queries or indexes
              // But for stream mapping it's fine.
              // Ideally we should use array-contains in query, but let's filter in memory for simplicity if list is small,
              // or adjust query.
              // For now, retaining original structure but adding category check if query didn't exist (it wasn't in original code either).
              // The original code returned EVERYTHING. We should filter.

              final vendor = VendorModel(
                id: doc.id,
                userId: doc.id,
                businessName: userData['businessName'] ??
                    userData['name'] ??
                    'Unknown Business',
                description:
                    userData['description'] ?? 'Emergency supplies vendor',
                address: userData['address'] ?? '',
                latitude: userData['latitude']?.toDouble() ?? 0.0,
                longitude: userData['longitude']?.toDouble() ?? 0.0,
                phone: userData['phone'] ?? '',
                email: userData['email'] ?? '',
                categories: List<String>.from(
                    userData['categories'] ?? ['Emergency Supplies']),
                logoImage: userData['logoUrl'] ?? userData['profileImage'],
                isApproved: userData['isApproved'] ?? false,
                isActive: userData['isActive'] ?? true,
                rating: (userData['rating'] ?? 4.5).toDouble(),
                totalOrders: userData['totalOrders'] ?? 0,
                operatingHours:
                    Map<String, dynamic>.from(userData['businessHours'] ?? {}),
                createdAt: _parseDateTime(userData['createdAt']),
                updatedAt: _parseDateTime(userData['updatedAt']),
              );
              return vendor;
            })
            .where((v) => v.categories.contains(category) || category == 'All')
            .toList());
  }

  // Update vendor profile
  static Future<void> updateVendorProfile({
    required String vendorId,
    String? businessName,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    List<String>? categories,
    String? logoUrl,
    Map<String, dynamic>? businessHours,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (businessName != null) updates['businessName'] = businessName;
      if (description != null) updates['description'] = description;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (phone != null)
        updates['phone'] = phone; // Update in user profile too? Ideally yes.
      if (categories != null) updates['categories'] = categories;
      if (logoUrl != null) updates['logoUrl'] = logoUrl;
      if (businessHours != null) updates['businessHours'] = businessHours;

      // Update the user document since vendors are users with role='vendor'
      await FirebaseService.users.doc(vendorId).update(updates);
    } catch (e) {
      throw 'Failed to update vendor profile: $e';
    }
  }

  // Update vendor status (online/offline)
  static Future<void> updateVendorStatus(String vendorId, bool isOnline) async {
    try {
      await FirebaseService.users.doc(vendorId).update({
        'isActive': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update vendor status: $e';
    }
  }

  // Get items by vendor
  static Stream<List<ItemModel>> getItemsByVendor(String vendorId,
      {bool includeInactive = false}) {
    Query query = FirebaseService.items.where('vendorId', isEqualTo: vendorId);

    if (!includeInactive) {
      query = query.where('isAvailable', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Add item
  static Future<ItemModel> addItem({
    required String vendorId,
    required String name,
    required String description,
    required String category,
    required double price,
    required int quantity,
    String? imageUrl,
  }) async {
    try {
      final itemRef = FirebaseService.items.doc();

      final item = ItemModel(
        id: itemRef.id,
        vendorId: vendorId,
        name: name,
        description: description,
        category: category,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await itemRef.set(item.toMap());
      return item;
    } catch (e) {
      throw 'Failed to add item: $e';
    }
  }

  // Update item
  static Future<void> updateItem({
    required String itemId,
    String? name,
    String? description,
    String? category,
    double? price,
    int? quantity,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (price != null) updates['price'] = price;
      if (quantity != null) updates['quantity'] = quantity;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      if (isAvailable != null) updates['isAvailable'] = isAvailable;

      await FirebaseService.items.doc(itemId).update(updates);
    } catch (e) {
      throw 'Failed to update item: $e';
    }
  }

  // Delete item
  static Future<void> deleteItem(String itemId) async {
    try {
      await FirebaseService.items.doc(itemId).delete();
    } catch (e) {
      throw 'Failed to delete item: $e';
    }
  }

  // Get items by category
  static Stream<List<ItemModel>> getItemsByCategory(String category) {
    return FirebaseService.items
        .where('category', isEqualTo: category)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all available items (for general browsing)
  static Stream<List<ItemModel>> getAllAvailableItems() {
    return FirebaseService.items
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Search items
  static Future<List<ItemModel>> searchItems(String query) async {
    try {
      final snapshot = await FirebaseService.items
          .where('isAvailable', isEqualTo: true)
          .get();

      final items = snapshot.docs
          .map((doc) =>
              ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()) ||
              item.category.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return items;
    } catch (e) {
      return [];
    }
  }
}
