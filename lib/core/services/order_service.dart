import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../constants/app_constants.dart';
import 'firebase_service.dart';
import 'commercial_rates_service.dart';
import '../config/env_config.dart';

class OrderService {
  // Create a new order
  static Future<OrderModel> createOrder({
    required String hostId,
    required String hostName,
    required String hostPhone,
    required String vendorId,
    required String vendorName,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? specialInstructions,
    required String requiredVehicle,
    required double estimatedDistanceKm,
  }) async {
    try {
      // 1. Prepare data outside transaction (Vendor info, Fee calculation)
      // This reduces transaction duration and contention
      String vendorTier = 'free';
      double vendorLat = 0.0;
      double vendorLng = 0.0;
      List<String> vendorCategories = [];

      try {
        final vendorDoc = await FirebaseService.users
            .doc(vendorId)
            .get(); // Use users collection for vendor
        if (vendorDoc.exists) {
          final data =
              vendorDoc.data() as Map<String, dynamic>?; // explicit cast
          if (data != null) {
            if (data.containsKey('subscriptionTier')) {
              vendorTier = data['subscriptionTier'];
            }
            if (data.containsKey('latitude')) {
              vendorLat = (data['latitude'] ?? 0.0).toDouble();
            }
            if (data.containsKey('longitude')) {
              vendorLng = (data['longitude'] ?? 0.0).toDouble();
            }
            if (data.containsKey('categories')) {
              vendorCategories = List<String>.from(data['categories'] ?? []);
            }
          }
        }
      } catch (e) {
        print('Error fetching vendor data: $e');
      }

      String calculatedVehicle = determineRequiredVehicle(vendorCategories);
      // Use the stricter of the two vehicles if needed, or just trust the passed one
      // For now, let's keep the passed one or recalculate.
      // The passed 'requiredVehicle' usually comes from cart provider which might not have full logic.
      // Let's use the calculated one for safety, or consistency.

      final ratesService = CommercialRatesService();
      await ratesService.getRates();

      final feeBreakdown = ratesService.calculateOrderFees(
        subtotal: subtotal,
        baseDeliveryFee: deliveryFee,
        isEmergency:
            specialInstructions?.toLowerCase().contains('emergency') ?? false,
        vendorTier: vendorTier,
        vehicleType: calculatedVehicle,
        distanceKm: estimatedDistanceKm,
      );

      // Generate ID beforehand
      final orderRef = FirebaseService.orders.doc();
      final orderId = orderRef.id;
      final now = DateTime.now();

      final order = OrderModel(
        id: orderId,
        hostId: hostId,
        hostName: hostName,
        hostPhone: hostPhone,
        vendorId: vendorId,
        vendorName: vendorName,
        items: items,
        subtotal: subtotal,
        deliveryFee: feeBreakdown.deliveryFee,
        totalAmount: feeBreakdown.totalAmount,
        commissionAmount: feeBreakdown.platformCommission,
        riderFee: feeBreakdown.riderFee,
        platformFee: feeBreakdown.platformDeliveryCut,
        isEmergency: feeBreakdown.emergencySurcharge > 0,
        requiredVehicle: calculatedVehicle,
        estimatedDistanceKm: estimatedDistanceKm,
        timelineEvents: [
          {
            'title': 'Order Placed',
            'timestamp': now.millisecondsSinceEpoch,
            'description': 'Order received by system',
          }
        ],
        status: AppConstants.statusPending,
        deliveryAddress: deliveryAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        specialInstructions: specialInstructions,
        estimatedDeliveryMinutes: AppConstants.estimatedDeliveryMinutes,
        createdAt: now,
        updatedAt: now,
      );

      // PRE-CHECK: Validate products availability before starting transaction
      // This prevents "Bad State" errors and provides cleaner feedback
      print('DEBUG: Validating ${items.length} items before transaction...');
      for (final item in items) {
        final doc = await FirebaseService.items.doc(item.productId).get();
        if (!doc.exists) {
          throw 'Product "${item.productName}" is no longer available. Please remove it from your cart.';
        }
      }

      // 2. Run Transaction to check stock and create order
      print('DEBUG: Starting transaction...');
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        print('DEBUG: Transaction started.');
        // Prepare list of updates to perform after all reads are done
        // Map<DocumentReference, int> seems risky if we can't use complex keys easily,
        // but Reference is hashable.
        // Better: List of objects or just parallel arrays.
        final List<Map<String, dynamic>> updatesToApply = [];

        // A. READ PASS: Check all stocks
        for (final item in items) {
          print(
              'DEBUG: Checking stock for ${item.productName} (${item.productId})');
          final productRef = FirebaseService.items.doc(item.productId);
          final productDoc = await transaction.get(productRef);

          if (!productDoc.exists) {
            print('DEBUG: Product not found: ${item.productId}');
            throw Exception('Product ${item.productName} no longer exists');
          }

          final productData = productDoc.data() as Map<String, dynamic>?;
          final quantityRaw = productData?['quantity'];
          int currentStock = 0;

          // Robust casting
          if (quantityRaw is int) {
            currentStock = quantityRaw;
          } else if (quantityRaw is double) {
            currentStock = quantityRaw.toInt();
          } else if (quantityRaw is String) {
            currentStock = int.tryParse(quantityRaw) ?? 0;
          }
          print(
              'DEBUG: Stock for ${item.productName}: $currentStock (Requested: ${item.quantity})');

          if (currentStock < item.quantity) {
            print('DEBUG: Insufficient stock for ${item.productName}');
            throw Exception(
                'Insufficient stock for ${item.productName}. Available: $currentStock');
          }

          updatesToApply.add({
            'ref': productRef,
            'newQuantity': currentStock - item.quantity,
          });
        }

        // B. WRITE PASS: Apply all updates
        print(
            'DEBUG: All checks passed. Applying ${updatesToApply.length} updates...');
        for (final update in updatesToApply) {
          transaction.update(update['ref'] as DocumentReference, {
            'quantity': update['newQuantity'],
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // C. Create Order
        print('DEBUG: Creating order document...');
        transaction.set(orderRef, order.toMap());
        print('DEBUG: Transaction actions queued.');
      });

      print('DEBUG: Transaction completed successfully.');

      // Notify vendor about the new order
      print('DEBUG: Sending notification to vendor ($vendorId)...');
      _sendOrderNotification(
        orderId: order.id,
        hostUserId: vendorId,
        status: 'new_order',
        vendorName: hostName,
      );

      // Also notify the host that their order was placed successfully
      print('DEBUG: Sending notification to host ($hostId)...');
      _sendOrderNotification(
        orderId: order.id,
        hostUserId: hostId,
        status: 'order_placed',
        vendorName: vendorName,
      );

      return order;
    } catch (e, stack) {
      print('DEBUG: Order creation failed: $e');
      print('DEBUG: Stack trace: $stack');
      throw 'Order Failed: $e';
    }
  }

  // Get orders by host
  static Stream<List<OrderModel>> getOrdersByHost(String hostId) {
    return FirebaseService.orders
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get orders by vendor
  static Stream<List<OrderModel>> getOrdersByVendor(String vendorId) {
    return FirebaseService.orders
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get orders by rider
  static Stream<List<OrderModel>> getOrdersByRider(String riderId) {
    return FirebaseService.orders
        .where('riderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get available orders for riders (orders that need pickup)
  static Stream<List<OrderModel>> getAvailableOrdersForRiders({
    String? vehicleType,
  }) {
    return FirebaseService.orders
        .where('status', isEqualTo: AppConstants.statusPreparing)
        .where('riderId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) =>
              OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (vehicleType == null) return orders;

      return orders.where((order) {
        // Filter logic: Rider can take orders for their vehicle type or smaller (if we allow that)
        // For strict enforcement:
        // if (order.requiredVehicle != vehicleType) return false;

        // OR Hierarchical: Van > Car > Bike
        if (vehicleType == 'van') return true; // Van can take anything
        if (vehicleType == 'car') {
          return ['bike', 'car'].contains(order.requiredVehicle);
        }
        // Bike can only take bike orders
        return order.requiredVehicle == 'bike';
      }).toList();
    });
  }

  // Get single order
  static Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await FirebaseService.orders.doc(orderId).get();
      if (!doc.exists) return null;
      return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Update order status
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      OrderModel? order;

      switch (status) {
        case AppConstants.statusAccepted:
          updates['acceptedAt'] = FieldValue.serverTimestamp();
          order = await getOrder(orderId);
          if (order != null) {
            updates['estimatedDeliveryTime'] = Timestamp.fromDate(
              DateTime.now()
                  .add(Duration(minutes: order.estimatedDeliveryMinutes)),
            );
          }
          break;
        case AppConstants.statusPickedUp:
          updates['pickedUpAt'] = FieldValue.serverTimestamp();
          break;
        case AppConstants.statusDelivered:
          updates['deliveredAt'] = FieldValue.serverTimestamp();
          updates['paymentStatus'] = 'completed';
          break;
      }

      await FirebaseService.orders.doc(orderId).update(updates);

      // Get order details for notifications
      order ??= await getOrder(orderId);
      if (order != null) {
        // Always notify host about status changes
        print('[Notify] Sending status update to host...');
        _sendOrderNotification(
          orderId: orderId,
          hostUserId: order.hostId,
          status: status,
          vendorName: order.vendorName,
        );

        // Notify rider for relevant status changes
        if (order.riderId != null &&
            [
              AppConstants.statusAccepted,
              AppConstants.statusPreparing,
              AppConstants.statusInTransit
            ].contains(status)) {
          print('[Notify] Sending status update to rider...');
          _sendOrderNotification(
            orderId: orderId,
            hostUserId: order.riderId!,
            status: '${status}_rider',
            vendorName: order.vendorName,
          );
        }

        // Notify vendor when order is delivered
        if (status == AppConstants.statusDelivered) {
          print('[Notify] Sending delivery confirmation to vendor...');
          _sendOrderNotification(
            orderId: orderId,
            hostUserId: order.vendorId,
            status: 'delivered_vendor',
            vendorName: order.hostName,
          );
        }

        // Notify vendor and rider when order is cancelled
        if (status == AppConstants.statusCancelled) {
          print('[Notify] Sending cancellation notification to vendor...');
          _sendOrderNotification(
            orderId: orderId,
            hostUserId: order.vendorId,
            status: 'cancelled_vendor',
            vendorName: order.hostName,
          );

          if (order.riderId != null) {
            print('[Notify] Sending cancellation notification to rider...');
            _sendOrderNotification(
              orderId: orderId,
              hostUserId: order.riderId!,
              status: 'cancelled_rider',
              vendorName: order.vendorName,
            );
          }
        }
      }
    } catch (e) {
      throw 'Failed to update order status: $e';
    }
  }

  /// Fire-and-forget: notify host of order status change via backend.
  static void _sendOrderNotification({
    required String orderId,
    required String hostUserId,
    required String status,
    required String vendorName,
  }) {
    print('[Notify] Preparing notification...');
    print('[Notify] - Order ID: $orderId');
    print('[Notify] - Target User: $hostUserId');
    print('[Notify] - Status: $status');
    print('[Notify] - Vendor Name: $vendorName');

    final url = Uri.parse(
        '${EnvConfig.storageBackendUrl}/api/notifications/send-order');

    final body = jsonEncode({
      'orderId': orderId,
      'hostUserId': hostUserId,
      'status': status,
      'vendorName': vendorName,
    });

    print('[Notify] Sending to: $url');
    print('[Notify] Body: $body');

    http
        .post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (EnvConfig.storageApiKey.isNotEmpty)
          'x-api-key': EnvConfig.storageApiKey,
      },
      body: body,
    )
        .then((res) {
      if (res.statusCode == 200) {
        print('[Notify] ✅ send-order success: ${res.body}');
      } else if (res.statusCode == 404) {
        print(
            '[Notify] ⚠️  send-order 404: User has not registered device token');
        print('[Notify] 💡 User needs to log in to receive notifications');
        print('[Notify] Response: ${res.body}');
      } else {
        print('[Notify] ❌ send-order failed (${res.statusCode}): ${res.body}');
      }
    }).catchError((e) {
      print('[Notify] ❌ send-order error: $e');
    });
  }

  // Assign rider to order
  static Future<void> assignRider({
    required String orderId,
    required String riderId,
    required String riderName,
    required String riderPhone,
  }) async {
    try {
      await FirebaseService.orders.doc(orderId).update({
        'riderId': riderId,
        'riderName': riderName,
        'riderPhone': riderPhone,
        'status': AppConstants.statusPreparing,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notifications
      await sendRiderAssignmentNotifications(
        orderId: orderId,
        riderId: riderId,
        riderName: riderName,
      );
    } catch (e) {
      throw 'Failed to assign rider: $e';
    }
  }

  // Send notifications when rider is assigned (can be called independently)
  static Future<void> sendRiderAssignmentNotifications({
    required String orderId,
    required String riderId,
    required String riderName,
  }) async {
    try {
      // Get order details for notifications
      final order = await getOrder(orderId);
      if (order != null) {
        // Notify host that rider has been assigned
        print('[Notify] Sending rider assignment notification to host...');
        _sendOrderNotification(
          orderId: orderId,
          hostUserId: order.hostId,
          status: 'rider_assigned',
          vendorName: riderName,
        );

        // Notify rider about new delivery assignment
        print('[Notify] Sending new delivery notification to rider...');
        _sendOrderNotification(
          orderId: orderId,
          hostUserId: riderId,
          status: 'new_delivery',
          vendorName: order.vendorName,
        );
      }
    } catch (e) {
      print('[Notify] ❌ Failed to send rider assignment notifications: $e');
    }
  }

  // Update rider location
  static Future<void> updateRiderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await FirebaseService.orders.doc(orderId).update({
        'riderLatitude': latitude,
        'riderLongitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update rider location: $e';
    }
  }

  // Update order delivery location
  static Future<void> updateOrderLocation(
      String orderId, double lat, double lng, String address) async {
    try {
      await FirebaseService.orders.doc(orderId).update({
        'deliveryLatitude': lat,
        'deliveryLongitude': lng,
        'deliveryAddress': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update delivery location: $e';
    }
  }

  // Upload proof of delivery
  static Future<void> uploadProofOfDelivery(
      String orderId, String imageUrl) async {
    try {
      await FirebaseService.orders.doc(orderId).update({
        'proofOfDeliveryImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to upload proof of delivery: $e';
    }
  }

  // Cancel order
  static Future<void> cancelOrder(String orderId, String reason) async {
    try {
      // Get the order first to check if it has a rider assigned
      final orderDoc = await FirebaseService.orders.doc(orderId).get();

      if (!orderDoc.exists) {
        throw 'Order not found';
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final String? riderId = orderData['riderId'];
      final String vendorId = orderData['vendorId'];
      final String hostId = orderData['hostId'];

      // Update order status and clear rider assignment
      await FirebaseService.orders.doc(orderId).update({
        'status': AppConstants.statusCancelled,
        'cancellationReason': reason,
        'riderId': null, // Clear rider assignment
        'riderName': null,
        'riderPhone': null,
        'updatedAt': FieldValue.serverTimestamp(),
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Send notifications to vendor and host
      // Note: Notifications will be sent via backend or notification service
      print('Order $orderId cancelled. Reason: $reason');
      print('Vendor $vendorId needs to reassign a new rider');
    } catch (e) {
      throw 'Failed to cancel order: $e';
    }
  }

  // Get all orders (for admin)
  static Stream<List<OrderModel>> getAllOrders() {
    return FirebaseService.orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Helper: Calculate distance between two points in km
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0 || lon1 == 0 || lat2 == 0 || lon2 == 0) return 0.0;

    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  // Helper: Determine vehicle type based on vendor categories
  static String determineRequiredVehicle(List<String> categories) {
    final lowerCategories = categories.map((e) => e.toLowerCase()).toList();

    if (lowerCategories.any((c) =>
        c.contains('furniture') ||
        c.contains('decor') ||
        c.contains('generator') ||
        c.contains('stage') ||
        c.contains('large'))) {
      return 'van';
    }

    if (lowerCategories.any((c) =>
        c.contains('catering') ||
        c.contains('floral') ||
        c.contains('medium'))) {
      return 'car';
    }

    return 'bike';
  }
}
