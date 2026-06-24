import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class MigrationService {
  static Future<void> migrateAddressFields() async {
    try {
      // Migrate users collection
      await _migrateCollection('users', {
        'addressId': 'address',
      });

      // Migrate vendors collection
      await _migrateCollection('vendors', {
        'addressId': 'address',
      });

      // Migrate orders collection
      await _migrateCollection('orders', {
        'deliveryAddressId': 'deliveryAddress',
      });

      print('Migration completed successfully');
    } catch (e) {
      print('Migration error: $e');
    }
  }

  static Future<void> _migrateCollection(
      String collectionName, Map<String, String> fieldMappings) async {
    final collection = FirebaseService.firestore.collection(collectionName);
    final querySnapshot = await collection.get();

    final batch = FirebaseService.firestore.batch();
    int batchCount = 0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      bool needsUpdate = false;
      final updates = <String, dynamic>{};

      for (final entry in fieldMappings.entries) {
        final oldField = entry.key;
        final newField = entry.value;

        if (data.containsKey(oldField) && !data.containsKey(newField)) {
          updates[newField] = data[oldField];
          updates[oldField] = FieldValue.delete();
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        batch.update(doc.reference, updates);
        batchCount++;

        // Commit batch every 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
    }

    // Commit remaining operations
    if (batchCount > 0) {
      await batch.commit();
    }
  }

  static Future<void> cleanupOldFields() async {
    try {
      // Remove any remaining addressId fields
      await _removeFieldsFromCollection('users', ['addressId']);
      await _removeFieldsFromCollection('vendors', ['addressId']);
      await _removeFieldsFromCollection('orders', ['deliveryAddressId']);

      print('Cleanup completed successfully');
    } catch (e) {
      print('Cleanup error: $e');
    }
  }

  static Future<void> _removeFieldsFromCollection(
      String collectionName, List<String> fieldsToRemove) async {
    final collection = FirebaseService.firestore.collection(collectionName);
    final querySnapshot = await collection.get();

    final batch = FirebaseService.firestore.batch();
    int batchCount = 0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      bool needsUpdate = false;
      final updates = <String, dynamic>{};

      for (final field in fieldsToRemove) {
        if (data.containsKey(field)) {
          updates[field] = FieldValue.delete();
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        batch.update(doc.reference, updates);
        batchCount++;

        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
  }
}
