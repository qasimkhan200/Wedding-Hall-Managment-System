import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rider_assignment_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'order_service.dart';

class RiderAssignmentService {
  // Get available riders for assignment
  static Stream<List<UserModel>> getAvailableRiders({
    double? latitude,
    double? longitude,
    double maxDistance = 10.0,
    double minRating = 4.0,
  }) {
    return FirebaseService.users
        .where('role', isEqualTo: 'rider')
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final riders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data, doc.id);
      }).where((rider) {
        // Add basic filtering logic here
        // In a real implementation, you'd calculate distance and filter by rating
        return true; // For now, return all approved active riders
      }).toList();

      // Sort by rating (highest first)
      riders.sort((a, b) => b.name.compareTo(a.name)); // Placeholder sorting
      return riders;
    });
  }

  // Assign rider to order
  static Future<RiderAssignmentModel> assignRider({
    required String orderId,
    required String vendorId,
    required String riderId,
    required String riderName,
    required String riderPhone,
    required double deliveryFee,
    String? specialInstructions,
    int estimatedMinutes = 30,
  }) async {
    try {
      // Get rider's current location from users collection
      double? riderLatitude;
      double? riderLongitude;

      try {
        final riderDoc = await FirebaseService.users.doc(riderId).get();
        if (riderDoc.exists) {
          final riderData = riderDoc.data() as Map<String, dynamic>?;
          if (riderData != null) {
            riderLatitude = riderData['latitude']?.toDouble();
            riderLongitude = riderData['longitude']?.toDouble();
          }
        }
      } catch (e) {
        // Continue without location if we can't fetch it
        print('Warning: Could not fetch rider location: $e');
      }

      final assignmentRef =
          FirebaseService.firestore.collection('rider_assignments').doc();

      final assignment = RiderAssignmentModel(
        id: assignmentRef.id,
        orderId: orderId,
        vendorId: vendorId,
        riderId: riderId,
        riderName: riderName,
        riderPhone: riderPhone,
        status: 'assigned',
        deliveryFee: deliveryFee,
        specialInstructions: specialInstructions,
        assignedAt: DateTime.now(),
        estimatedMinutes: estimatedMinutes,
        riderLatitude: riderLatitude,
        riderLongitude: riderLongitude,
      );

      await assignmentRef.set(assignment.toMap());

      // Update the order with rider information including location
      final orderUpdates = <String, dynamic>{
        'riderId': riderId,
        'riderName': riderName,
        'riderPhone': riderPhone,
        'status': 'preparing', // Update order status
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add rider location to order if available
      if (riderLatitude != null && riderLongitude != null) {
        orderUpdates['riderLatitude'] = riderLatitude;
        orderUpdates['riderLongitude'] = riderLongitude;
      }

      print(
          '🔍 RiderAssignmentService: Updating order $orderId with rider $riderId');
      print('🔍 Order updates: $orderUpdates');

      await FirebaseService.orders.doc(orderId).update(orderUpdates);

      print('✅ RiderAssignmentService: Order updated successfully');

      // Send notifications to host and rider
      print('📱 RiderAssignmentService: Sending notifications...');
      await OrderService.sendRiderAssignmentNotifications(
        orderId: orderId,
        riderId: riderId,
        riderName: riderName,
      );

      return assignment;
    } catch (e) {
      throw 'Failed to assign rider: $e';
    }
  }

  // Get rider assignments for a vendor
  static Stream<List<RiderAssignmentModel>> getVendorAssignments(
      String vendorId) {
    return FirebaseService.firestore
        .collection('rider_assignments')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return RiderAssignmentModel.fromMap(data, doc.id);
            }).toList());
  }

  // Get rider assignments for a rider
  static Stream<List<RiderAssignmentModel>> getRiderAssignments(
      String riderId) {
    return FirebaseService.firestore
        .collection('rider_assignments')
        .where('riderId', isEqualTo: riderId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return RiderAssignmentModel.fromMap(data, doc.id);
            }).toList());
  }

  // Update assignment status
  static Future<void> updateAssignmentStatus({
    required String assignmentId,
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (status) {
        case 'accepted':
          updates['acceptedAt'] = FieldValue.serverTimestamp();
          break;
        case 'picked_up':
          updates['pickedUpAt'] = FieldValue.serverTimestamp();
          break;
        case 'delivered':
          updates['deliveredAt'] = FieldValue.serverTimestamp();
          break;
      }

      if (latitude != null && longitude != null) {
        updates['riderLatitude'] = latitude;
        updates['riderLongitude'] = longitude;
      }

      await FirebaseService.firestore
          .collection('rider_assignments')
          .doc(assignmentId)
          .update(updates);
    } catch (e) {
      throw 'Failed to update assignment status: $e';
    }
  }

  // Cancel assignment
  static Future<void> cancelAssignment({
    required String assignmentId,
    required String reason,
  }) async {
    try {
      await FirebaseService.firestore
          .collection('rider_assignments')
          .doc(assignmentId)
          .update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to cancel assignment: $e';
    }
  }

  // Auto-assign rider (simplified version)
  static Future<RiderAssignmentModel?> autoAssignRider({
    required String orderId,
    required String vendorId,
    required double deliveryFee,
    double? pickupLatitude,
    double? pickupLongitude,
  }) async {
    try {
      // Get available riders with their locations
      final ridersSnapshot = await FirebaseService.users
          .where('role', isEqualTo: 'rider')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .limit(10)
          .get();

      if (ridersSnapshot.docs.isEmpty) {
        throw 'No available riders found';
      }

      // Simple selection: pick the first available rider
      // In a real implementation, you'd use distance-based smart matching
      final selectedRider = ridersSnapshot.docs.first;
      final riderData = selectedRider.data() as Map<String, dynamic>;

      return await assignRider(
        orderId: orderId,
        vendorId: vendorId,
        riderId: selectedRider.id,
        riderName: riderData['name'] ?? 'Rider',
        riderPhone: riderData['phone'] ?? '',
        deliveryFee: deliveryFee,
        specialInstructions: 'Auto-assigned delivery',
      );
    } catch (e) {
      throw 'Failed to auto-assign rider: $e';
    }
  }

  // Get assignment by order ID
  static Future<RiderAssignmentModel?> getAssignmentByOrderId(
      String orderId) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('rider_assignments')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return RiderAssignmentModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    } catch (e) {
      return null;
    }
  }

  // Manual fix: Update order with rider info from existing assignment
  static Future<void> fixOrderFromAssignment(String assignmentId) async {
    try {
      print('🔧 Fixing order from assignment: $assignmentId');

      // Get the assignment
      final assignmentDoc = await FirebaseService.firestore
          .collection('rider_assignments')
          .doc(assignmentId)
          .get();

      if (!assignmentDoc.exists) {
        throw 'Assignment $assignmentId not found';
      }

      final assignmentData = assignmentDoc.data() as Map<String, dynamic>;
      final orderId = assignmentData['orderId'];
      final riderId = assignmentData['riderId'];
      final riderName = assignmentData['riderName'];
      final riderPhone = assignmentData['riderPhone'];
      final riderLatitude = assignmentData['riderLatitude'];
      final riderLongitude = assignmentData['riderLongitude'];

      print('🔧 Assignment data: orderId=$orderId, riderId=$riderId');

      // Check if order exists
      final orderDoc = await FirebaseService.orders.doc(orderId).get();
      if (!orderDoc.exists) {
        throw 'Order $orderId not found';
      }

      // Update the order
      final orderUpdates = <String, dynamic>{
        'riderId': riderId,
        'riderName': riderName,
        'riderPhone': riderPhone,
        'status': 'preparing',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (riderLatitude != null && riderLongitude != null) {
        orderUpdates['riderLatitude'] = riderLatitude;
        orderUpdates['riderLongitude'] = riderLongitude;
      }

      await FirebaseService.orders.doc(orderId).update(orderUpdates);

      print('✅ Order $orderId fixed successfully with rider $riderId');
    } catch (e) {
      print('❌ Error fixing order: $e');
      throw 'Failed to fix order: $e';
    }
  }
}
