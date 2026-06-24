import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/vendor_model.dart';
import '../models/rider_model.dart';
import 'firebase_service.dart';

class AdminService {
  // Get pending vendor approvals
  static Stream<List<VendorModel>> getPendingVendors() {
    return FirebaseService.users
        .where('role', isEqualTo: 'vendor')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) {
              try {
                // Admin needs full vendor details including documents
                return VendorModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
              } catch (e) {
                print('Error parsing vendor user ${doc.id}: $e');
                return null;
              }
            })
            .where((vendor) => vendor != null)
            .cast<VendorModel>()
            .toList();
      } catch (e) {
        print('Error in getPendingVendors stream: $e');
        return <VendorModel>[];
      }
    });
  }

  // Get pending rider approvals
  static Stream<List<RiderModel>> getPendingRiders() {
    return FirebaseService.users
        .where('role', isEqualTo: 'rider')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) {
              try {
                // Admin needs full rider details including documents
                return RiderModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
              } catch (e) {
                print('Error parsing rider user ${doc.id}: $e');
                return null;
              }
            })
            .where((rider) => rider != null)
            .cast<RiderModel>()
            .toList();
      } catch (e) {
        print('Error in getPendingRiders stream: $e');
        return <RiderModel>[];
      }
    });
  }

  // Approve vendor (simplified - only update users collection)
  static Future<void> approveVendor(String vendorId) async {
    try {
      await FirebaseService.users.doc(vendorId).update({
        'isApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to approve vendor: $e';
    }
  }

  // Reject vendor (simplified - only update users collection)
  static Future<void> rejectVendor(String vendorId, String reason) async {
    try {
      await FirebaseService.users.doc(vendorId).update({
        'isApproved': false,
        'isActive': false,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to reject vendor: $e';
    }
  }

  // Approve rider (simplified - only update users collection)
  static Future<void> approveRider(String riderId) async {
    try {
      await FirebaseService.users.doc(riderId).update({
        'isApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to approve rider: $e';
    }
  }

  // Reject rider (simplified - only update users collection)
  static Future<void> rejectRider(String riderId, String reason) async {
    try {
      await FirebaseService.users.doc(riderId).update({
        'isApproved': false,
        'isActive': false,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to reject rider: $e';
    }
  }

  // Get all users (simplified query to avoid index requirement)
  static Stream<List<UserModel>> getAllUsers() {
    return FirebaseService.users.snapshots().map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) {
              try {
                return UserModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
              } catch (e) {
                print('Error parsing user ${doc.id}: $e');
                return null;
              }
            })
            .where((user) => user != null)
            .cast<UserModel>()
            .toList();
      } catch (e) {
        print('Error in getAllUsers stream: $e');
        return <UserModel>[];
      }
    });
  }

  // Get all vendors
  static Stream<List<VendorModel>> getAllVendors() {
    return FirebaseService.vendors
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all riders
  static Stream<List<RiderModel>> getAllRiders() {
    return FirebaseService.riders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                RiderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Deactivate user
  static Future<void> deactivateUser(String userId) async {
    try {
      await FirebaseService.users.doc(userId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to deactivate user: $e';
    }
  }

  // Activate user
  static Future<void> activateUser(String userId) async {
    try {
      await FirebaseService.users.doc(userId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to activate user: $e';
    }
  }

  // Deactivate vendor
  static Future<void> deactivateVendor(String vendorId) async {
    try {
      await FirebaseService.vendors.doc(vendorId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to deactivate vendor: $e';
    }
  }

  // Activate vendor
  static Future<void> activateVendor(String vendorId) async {
    try {
      await FirebaseService.vendors.doc(vendorId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to activate vendor: $e';
    }
  }

  // Deactivate rider
  static Future<void> deactivateRider(String riderId) async {
    try {
      await FirebaseService.riders.doc(riderId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseService.users.doc(riderId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to deactivate rider: $e';
    }
  }

  // Activate rider
  static Future<void> activateRider(String riderId) async {
    try {
      await FirebaseService.riders.doc(riderId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseService.users.doc(riderId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to activate rider: $e';
    }
  }

  // Get platform statistics
  static Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      final usersSnapshot = await FirebaseService.users.get();
      final vendorsSnapshot = await FirebaseService.vendors.get();
      final ridersSnapshot = await FirebaseService.riders.get();
      final ordersSnapshot = await FirebaseService.orders.get();

      final activeVendors = vendorsSnapshot.docs
          .where((doc) => (doc.data() as Map)['isActive'] == true)
          .length;

      final activeRiders = ridersSnapshot.docs
          .where((doc) => (doc.data() as Map)['isActive'] == true)
          .length;

      final pendingOrders = ordersSnapshot.docs
          .where((doc) => (doc.data() as Map)['status'] == 'pending')
          .length;

      final completedOrders = ordersSnapshot.docs
          .where((doc) => (doc.data() as Map)['status'] == 'delivered')
          .length;

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalVendors': vendorsSnapshot.docs.length,
        'activeVendors': activeVendors,
        'totalRiders': ridersSnapshot.docs.length,
        'activeRiders': activeRiders,
        'totalOrders': ordersSnapshot.docs.length,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
      };
    } catch (e) {
      // Error handled silently, return empty stats
      return {};
    }
  }
}
