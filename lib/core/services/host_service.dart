import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/host_model.dart';

class HostService {
  static final CollectionReference _hostsCollection =
      FirebaseFirestore.instance.collection('hosts');

  // Create or Update Host Profile
  static Future<void> saveHostProfile(HostModel host) async {
    try {
      if (host.id.isEmpty) {
        // Create new
        final docRef = _hostsCollection.doc();
        // Create a copy with the new ID
        final newHost = host.copyWith(id: docRef.id);
        await docRef.set(newHost.toMap());
      } else {
        // Update existing
        await _hostsCollection.doc(host.id).update(host.toMap());
      }
    } catch (e) {
      throw 'Failed to save host profile: $e';
    }
  }

  // Get Host by User ID
  static Future<HostModel?> getHostByUserId(String userId) async {
    try {
      final querySnapshot = await _hostsCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return HostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      // Return null or throw depending on error handling strategy
      // For now, return null to indicate "not found" gracefully
      return null;
    }
  }

  // Stream Host Profile
  static Stream<HostModel?> streamHostByUserId(String userId) {
    return _hostsCollection
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return HostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }
}
