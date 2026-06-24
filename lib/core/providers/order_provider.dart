import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../services/order_service.dart';
import '../constants/app_constants.dart';

class OrderProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _ordersSubscription;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Admin Dashboard Metrics ---
  int get totalOrders => _orders.length;
  int get emergencyCount => _orders.where((o) => o.isEmergency).length;
  double get totalRevenue =>
      _orders.fold(0, (sum, item) => sum + item.totalAmount);

  // Filter state
  bool _filterEmergencyOnly = false;
  String _filterTimeRange = 'today'; // placeholder logic

  void setEmergencyFilter(bool value) {
    _filterEmergencyOnly = value;
    notifyListeners();
  }

  OrderStatus? _filterStatus;

  void setFilterStatus(OrderStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  List<OrderModel> get filteredOrders {
    var result = _orders;
    if (_filterEmergencyOnly) {
      result = result.where((o) => o.isEmergency).toList();
    }
    if (_filterStatus != null) {
      result = result.where((o) => o.orderStatus == _filterStatus).toList();
    }
    return result;
  }

  List<OrderModel> get pendingOrders =>
      _orders.where((o) => o.status == AppConstants.statusPending).toList();

  List<OrderModel> get activeOrders => _orders
      .where((o) =>
          o.status != AppConstants.statusDelivered &&
          o.status != AppConstants.statusCancelled)
      .toList();

  List<OrderModel> get completedOrders =>
      _orders.where((o) => o.status == AppConstants.statusDelivered).toList();

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Load orders by host
  void loadOrdersByHost(String hostId) {
    _ordersSubscription?.cancel();
    _ordersSubscription = OrderService.getOrdersByHost(hostId).listen(
      (orders) {
        _orders = orders;
        notifyListeners();
      },
      onError: (error) {
        setError(error.toString());
      },
    );
  }

  // Load orders by vendor
  void loadOrdersByVendor(String vendorId) {
    _ordersSubscription?.cancel();
    _ordersSubscription = OrderService.getOrdersByVendor(vendorId).listen(
      (orders) {
        _orders = orders;
        notifyListeners();
      },
      onError: (error) {
        setError(error.toString());
      },
    );
  }

  // Load orders by rider
  void loadOrdersByRider(String riderId) {
    _ordersSubscription?.cancel();
    _ordersSubscription = OrderService.getOrdersByRider(riderId).listen(
      (orders) {
        _orders = orders;
        notifyListeners();
      },
      onError: (error) {
        setError(error.toString());
      },
    );
  }

  // Get available orders stream for riders
  Stream<List<OrderModel>> getAvailableOrdersStream({String? vehicleType}) {
    return OrderService.getAvailableOrdersForRiders(vehicleType: vehicleType);
  }

  // Load all orders (for admin)
  void loadAllOrders() {
    _ordersSubscription?.cancel();
    _ordersSubscription = OrderService.getAllOrders().listen(
      (orders) {
        _orders = orders;
        notifyListeners();
      },
      onError: (error) {
        setError(error.toString());
      },
    );
  }

  // Create order
  Future<OrderModel?> createOrder({
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
    String requiredVehicle = 'bike',
    double estimatedDistanceKm = 0.0,
  }) async {
    try {
      setLoading(true);
      setError(null);

      final order = await OrderService.createOrder(
        hostId: hostId,
        hostName: hostName,
        hostPhone: hostPhone,
        vendorId: vendorId,
        vendorName: vendorName,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        deliveryAddress: deliveryAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        specialInstructions: specialInstructions,
        requiredVehicle: requiredVehicle,
        estimatedDistanceKm: estimatedDistanceKm,
      );

      _currentOrder = order;
      setLoading(false);
      return order;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await OrderService.updateOrderStatus(orderId, status);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  // Assign rider
  Future<bool> assignRider({
    required String orderId,
    required String riderId,
    required String riderName,
    required String riderPhone,
  }) async {
    try {
      await OrderService.assignRider(
        orderId: orderId,
        riderId: riderId,
        riderName: riderName,
        riderPhone: riderPhone,
      );
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  // Update rider location
  Future<bool> updateRiderLocation({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await OrderService.updateRiderLocation(
        orderId: orderId,
        latitude: latitude,
        longitude: longitude,
      );
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  // Upload proof of delivery
  Future<bool> uploadProofOfDelivery(String orderId, String imageUrl) async {
    try {
      await OrderService.uploadProofOfDelivery(orderId, imageUrl);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      await OrderService.cancelOrder(orderId, reason);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  void setCurrentOrder(OrderModel? order) {
    _currentOrder = order;
    notifyListeners();
  }

  List<OrderModel> getOrdersByHost(String hostId) {
    return _orders.where((o) => o.hostId == hostId).toList();
  }

  List<OrderModel> getOrdersByVendor(String vendorId) {
    return _orders.where((o) => o.vendorId == vendorId).toList();
  }

  List<OrderModel> getOrdersByRider(String riderId) {
    return _orders.where((o) => o.riderId == riderId).toList();
  }

  // Clear data on logout
  void clearData() {
    _ordersSubscription?.cancel();
    _orders = [];
    _currentOrder = null;
    _error = null;
    _isLoading = false;
    _filterEmergencyOnly = false;
    _filterStatus = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
