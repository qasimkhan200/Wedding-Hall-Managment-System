import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

/// Utility class to migrate old category names to new standardized names
class CategoryMigration {
  static const Map<String, String> _categoryMapping = {
    'Crockery': 'Crockery & Utensils',
    'Ice': 'Ice & Beverages',
    'Decor': 'Decor Items',
    // 'Chairs & Tables' remains the same
  };

  /// Migrate items with old category names to new standardized names
  static Future<void> migrateCategories() async {
    try {
      print('Starting category migration...');

      final batch = FirebaseService.firestore.batch();
      int updateCount = 0;

      for (final entry in _categoryMapping.entries) {
        final oldCategory = entry.key;
        final newCategory = entry.value;

        print('Migrating "$oldCategory" to "$newCategory"...');

        final querySnapshot = await FirebaseService.items
            .where('category', isEqualTo: oldCategory)
            .get();

        for (final doc in querySnapshot.docs) {
          batch.update(doc.reference, {
            'category': newCategory,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updateCount++;
        }

        print(
            'Found ${querySnapshot.docs.length} items with category "$oldCategory"');
      }

      if (updateCount > 0) {
        await batch.commit();
        print('Migration completed! Updated $updateCount items.');
      } else {
        print('No items found that need migration.');
      }
    } catch (e) {
      print('Migration failed: $e');
      rethrow;
    }
  }

  /// Check if migration is needed by looking for items with old category names
  static Future<bool> isMigrationNeeded() async {
    try {
      for (final oldCategory in _categoryMapping.keys) {
        final querySnapshot = await FirebaseService.items
            .where('category', isEqualTo: oldCategory)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }

  /// Get count of items that need migration
  static Future<Map<String, int>> getMigrationStats() async {
    final stats = <String, int>{};

    try {
      for (final entry in _categoryMapping.entries) {
        final oldCategory = entry.key;
        final querySnapshot = await FirebaseService.items
            .where('category', isEqualTo: oldCategory)
            .get();

        stats[oldCategory] = querySnapshot.docs.length;
      }
    } catch (e) {
      print('Error getting migration stats: $e');
    }

    return stats;
  }

  /// Debug function to get all unique categories currently in the database
  static Future<List<String>> getAllCategories() async {
    try {
      final querySnapshot = await FirebaseService.items.get();
      final categories = <String>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error getting all categories: $e');
      return [];
    }
  }

  /// Debug function to get count of items per category
  static Future<Map<String, int>> getCategoryStats() async {
    try {
      final querySnapshot = await FirebaseService.items.get();
      final stats = <String, int>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          stats[category] = (stats[category] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting category stats: $e');
      return {};
    }
  }
}
