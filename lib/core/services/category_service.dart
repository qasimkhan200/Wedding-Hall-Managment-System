import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import 'firebase_service.dart';

class CategoryService {
  static final CollectionReference _categoriesRef =
      FirebaseService.firestore.collection('categories');
  static final CollectionReference _vendorCategoriesRef =
      FirebaseService.firestore.collection('vendor_categories');

  // --- Core CRUD ---

  // Get all categories stream
  static Stream<List<CategoryModel>> getCategoriesStream() {
    return _categoriesRef.orderBy('name').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) =>
            CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Get single category
  static Future<CategoryModel?> getCategory(String id) async {
    final doc = await _categoriesRef.doc(id).get();
    if (!doc.exists) return null;
    return CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Create category
  static Future<void> createCategory(CategoryModel category) async {
    await _categoriesRef.doc(category.id).set(category.toMap());
  }

  // Update category
  static Future<void> updateCategory(CategoryModel category) async {
    await _categoriesRef.doc(category.id).update(category.toMap());
  }

  // Delete category
  static Future<void> deleteCategory(String id) async {
    await _categoriesRef.doc(id).delete();
  }

  // --- Hierarchy ---

  // Get category tree (flat list for now, client can build tree)
  // In future we can optimize with recursive queries if needed, but for <100 categories flat is fine
  static Future<List<CategoryModel>> getCategoryTree() async {
    final snapshot = await _categoriesRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) =>
            CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // --- Vendor Operations ---

  // Approve vendor for category
  static Future<void> approveVendorForCategory(
      String vendorId, String categoryId) async {
    await _vendorCategoriesRef.add({
      'vendorId': vendorId,
      'categoryId': categoryId,
      'status': 'active',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  // Revoke vendor from category
  static Future<void> revokeVendorFromCategory(
      String vendorId, String categoryId) async {
    final snapshot = await _vendorCategoriesRef
        .where('vendorId', isEqualTo: vendorId)
        .where('categoryId', isEqualTo: categoryId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Get pending applications (Placeholder - requires 'category_applications' collection)
  static Stream<List<Map<String, dynamic>>> getPendingApplications() {
    return FirebaseService.firestore
        .collection('category_applications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- Pricing Management ---

  static Future<void> updateCategoryCommission(
      String categoryId, double commissionPercent) async {
    await _categoriesRef.doc(categoryId).update({
      'pricing.commissionPercent': commissionPercent,
    });
  }

  static Future<void> setPriceCap(
      String categoryId, double? min, double? max) async {
    await _categoriesRef.doc(categoryId).update({
      'pricing.minPrice': min,
      'pricing.maxPrice': max,
    });
  }

  // --- Wedding Emergency Specifics ---

  static Future<void> setEmergencySLA(String categoryId, int minutes) async {
    await _categoriesRef.doc(categoryId).update({
      'emergencyDeliveryMinutes': minutes,
    });
  }

  static Future<List<CategoryModel>> getEmergencyCategories() async {
    final snapshot = await _categoriesRef
        .where('emergencyDeliveryMinutes', isLessThanOrEqualTo: 60)
        .get();

    return snapshot.docs
        .map((doc) =>
            CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // --- Analytics ---

  // Placeholder for analytics
  static Future<Map<String, dynamic>> getCategoryAnalytics(
      String categoryId) async {
    // In a real app, this would aggregate from an 'orders' collection
    return {
      'totalOrders': 150,
      'revenue': 25000,
      'activeVendors': 12,
    };
  }

  // --- Bulk Operations ---

  static Future<void> bulkUpdateCategoryStatus(
      List<String> categoryIds, bool isActive) async {
    final batch = FirebaseService.firestore.batch();
    for (var id in categoryIds) {
      batch.update(_categoriesRef.doc(id), {'isActive': isActive});
    }
    await batch.commit();
  }

  static Future<String> generateCategoryCsv() async {
    // Placeholder for CSV generation
    return "id,name,type\n1,Chairs,Rental";
  }
}
