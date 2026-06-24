import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rider_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class RiderService {
  // Create rider profile - this should be handled by the user registration process
  // Keeping for compatibility but riders are stored in users collection
  static Future<RiderModel> createRiderProfile({
    required String userId,
    required String name,
    required String phone,
    required String email,
    required String vehicleType,
    required String vehicleNumber,
    String? licenseImage,
    String? profileImage,
  }) async {
    try {
      final rider = RiderModel(
        id: userId,
        userId: userId,
        name: name,
        phone: phone,
        email: email,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        licenseImage: licenseImage,
        profileImage: profileImage,
        isActive: false,
        isApproved: false,
        isAvailable: false,
        rating: 0.0,
        totalDeliveries: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store in users collection with role 'rider'
      await FirebaseService.users.doc(userId).set({
        ...rider.toMap(),
        'role': 'rider',
      });
      return rider;
    } catch (e) {
      throw 'Failed to create rider profile: $e';
    }
  }

  // Get rider by ID from users collection
  static Future<RiderModel?> getRider(String riderId) async {
    try {
      final doc = await FirebaseService.users.doc(riderId).get();
      if (!doc.exists) return null;

      final userData = doc.data() as Map<String, dynamic>;
      if (userData['role'] != 'rider') return null;

      return RiderModel.fromMap(userData, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Update rider availability in users collection
  static Future<void> updateAvailability(
      String riderId, bool isAvailable) async {
    try {
      await FirebaseService.users.doc(riderId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update availability: $e';
    }
  }

  // Update rider location in users collection
  static Future<void> updateLocation({
    required String riderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await FirebaseService.users.doc(riderId).update({
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update location: $e';
    }
  }

  // Update rider profile in users collection
  static Future<void> updateProfile({
    required String riderId,
    String? name,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseImage,
    String? profileImage,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (vehicleType != null) updates['vehicleType'] = vehicleType;
      if (vehicleNumber != null) updates['vehicleNumber'] = vehicleNumber;
      if (licenseImage != null) updates['licenseImage'] = licenseImage;
      if (profileImage != null) updates['profileImage'] = profileImage;

      await FirebaseService.users.doc(riderId).update(updates);
    } catch (e) {
      throw 'Failed to update rider profile: $e';
    }
  }

  // Get available riders from users collection
  static Future<List<RiderModel>> getAvailableRiders() async {
    try {
      final snapshot = await FirebaseService.users
          .where('role', isEqualTo: 'rider')
          .where('isActive', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              RiderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get all riders from users collection
  static Stream<List<UserModel>> getAllRiders() {
    return FirebaseService.users
        .where('role', isEqualTo: 'rider')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Update rider stats after delivery in users collection
  static Future<void> updateDeliveryStats({
    required String riderId,
    required double rating,
  }) async {
    try {
      final doc = await FirebaseService.users.doc(riderId).get();
      if (!doc.exists) return;

      final userData = doc.data() as Map<String, dynamic>;
      if (userData['role'] != 'rider') return;

      final currentTotalDeliveries = userData['totalDeliveries'] ?? 0;
      final currentRating = userData['rating']?.toDouble() ?? 0.0;

      final newTotalDeliveries = currentTotalDeliveries + 1;
      final newRating = ((currentRating * currentTotalDeliveries) + rating) /
          newTotalDeliveries;

      await FirebaseService.users.doc(riderId).update({
        'totalDeliveries': newTotalDeliveries,
        'rating': newRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update delivery stats: $e';
    }
  }
}
