import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/rider_service.dart';
import '../../../core/services/offline_map_service.dart';
import '../../../core/models/order_model.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'rider_navigation_screen.dart';
import '../../../core/services/vendor_service.dart';
import 'dart:async';
import '../widgets/responsive_cancel_dialog.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  bool _isAvailable = false;
  bool _isLoading = false;
  String? _vehicleType;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        // Load rider's assigned orders
        context.read<OrderProvider>().loadOrdersByRider(authProvider.user!.id);
        // Load rider's current availability status
        _loadRiderAvailability(authProvider.user!.id);
        // Initialize location tracking
        _initializeLocation();
      }
    });
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.getCurrentLocation();
  }

  void _startLocationTracking(String riderId) {
    // Update location every 30 seconds when rider is available
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final locationProvider = context.read<LocationProvider>();

      // Get current location
      bool locationUpdated = await locationProvider.getCurrentLocation();

      if (locationUpdated && locationProvider.hasLocation) {
        try {
          // Update rider location in Firestore
          await RiderService.updateLocation(
            riderId: riderId,
            latitude: locationProvider.latitude!,
            longitude: locationProvider.longitude!,
          );
        } catch (e) {
          // Handle error silently to avoid spamming user
          debugPrint('Failed to update rider location: $e');
        }
      }
    });
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _loadRiderAvailability(String riderId) async {
    try {
      final rider = await RiderService.getRider(riderId);
      if (rider != null && mounted) {
        setState(() {
          _isAvailable = rider.isAvailable;
          _vehicleType = rider.vehicleType;
        });

        // Start location tracking if rider is available
        if (rider.isAvailable) {
          _startLocationTracking(riderId);
        }
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final riderId = authProvider.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🛵', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rider Mode', style: TextStyle(fontSize: 16)),
                Text('Ready for deliveries',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isAvailable ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isAvailable ? 'Available' : 'Unavailable',
                style: TextStyle(
                  color: _isAvailable ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: _isAvailable,
                onChanged: _isLoading
                    ? null
                    : (value) async {
                        if (riderId.isEmpty) return;

                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          // If becoming available, get current location first
                          if (value) {
                            final locationProvider =
                                context.read<LocationProvider>();
                            bool locationUpdated =
                                await locationProvider.getCurrentLocation();

                            if (locationUpdated &&
                                locationProvider.hasLocation) {
                              // Update location in Firestore
                              await RiderService.updateLocation(
                                riderId: riderId,
                                latitude: locationProvider.latitude!,
                                longitude: locationProvider.longitude!,
                              );
                            }
                          }

                          // Update availability status
                          await RiderService.updateAvailability(riderId, value);

                          if (mounted) {
                            setState(() {
                              _isAvailable = value;
                              _isLoading = false;
                            });

                            // Start or stop location tracking based on availability
                            if (value) {
                              _startLocationTracking(riderId);
                            } else {
                              _stopLocationTracking();
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to update availability: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                activeTrackColor: AppColors.success,
              ),
            ],
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final myOrders = orderProvider.orders;

          return Column(
            children: [
              _buildStatsCard(myOrders),
              const SizedBox(height: 16),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: AppColors.accent,
                        tabs: [
                          Tab(text: 'My Deliveries'),
                          Tab(text: 'Available Orders'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildMyDeliveries(myOrders),
                            _buildAvailableOrders(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(List<OrderModel> orders) {
    final activeOrders = orders
        .where((o) =>
            o.status != AppConstants.statusDelivered &&
            o.status != AppConstants.statusCancelled)
        .length;

    final completedToday = orders
        .where((o) =>
            o.status == AppConstants.statusDelivered &&
            o.deliveredAt != null &&
            o.deliveredAt!.day == DateTime.now().day)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Active', activeOrders.toString(), Icons.delivery_dining),
              _buildStatItem(
                  'Today', completedToday.toString(), Icons.check_circle),
              _buildStatItem(
                  'Earnings',
                  'Rs. ${orders.where((o) => o.status == AppConstants.statusDelivered && o.deliveredAt != null && o.deliveredAt!.day == DateTime.now().day).fold(0.0, (sum, order) => sum + order.riderFee).toStringAsFixed(0)}',
                  Icons.account_balance_wallet),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      locationProvider.hasLocation
                          ? Icons.location_on
                          : Icons.location_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationProvider.hasLocation
                            ? 'Location: ${locationProvider.address ?? 'Tracking...'}'
                            : 'Location: Not available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (locationProvider.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMyDeliveries(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📦', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            Text('No active deliveries'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index], true);
      },
    );
  }

  Widget _buildAvailableOrders() {
    return StreamBuilder<List<OrderModel>>(
      stream: context.read<OrderProvider>().getAvailableOrdersStream(
            vehicleType: _vehicleType,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('✅', style: TextStyle(fontSize: 60)),
                SizedBox(height: 16),
                Text('No available orders'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(orders[index], false);
          },
        );
      },
    );
  }

  Future<void> _onNavigate(OrderModel order) async {
    LatLng? destination;
    String destinationAddress = '';

    // Determine destination based on status
    if (order.status == AppConstants.statusPreparing ||
        order.status == AppConstants.statusAccepted) {
      // Navigate to Vendor for pickup
      final vendor = await VendorService.getVendor(order.vendorId);
      if (vendor != null) {
        destination = LatLng(vendor.latitude, vendor.longitude);
        destinationAddress = vendor.address;
      }
    } else if (order.status == AppConstants.statusPickedUp ||
        order.status == AppConstants.statusInTransit) {
      // Navigate to Customer for delivery
      destination = LatLng(order.deliveryLatitude, order.deliveryLongitude);
      destinationAddress = order.deliveryAddress;
    }

    if (destination != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RiderNavigationScreen(
            destination: destination!,
            destinationAddress: destinationAddress,
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not determine navigation destination')),
        );
      }
    }
  }

  Widget _buildOrderCard(OrderModel order, bool isMyOrder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.store, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(order.vendorName),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(order.deliveryAddress)),
            ],
          ),
          const SizedBox(height: 12),
          if (isMyOrder) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _onNavigate(order),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cancel button - only show for certain statuses
                if (_canCancelDelivery(order.status))
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: Text(_getActionText(order.status)),
              ),
            )
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: const Text('Accept Delivery'),
              ),
            ),
        ],
      ),
    );
  }

  String _getActionText(String status) {
    switch (status) {
      case AppConstants.statusPreparing:
        return 'Mark as Picked Up';
      case AppConstants.statusPickedUp:
      case AppConstants.statusInTransit:
        return 'Mark as Delivered';
      default:
        return 'Update Status';
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) return;

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.assignRider(
      orderId: order.id,
      riderId: user.id,
      riderName: user.name,
      riderPhone: user.phone,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _updateOrderStatus(OrderModel order) async {
    final orderProvider = context.read<OrderProvider>();
    String newStatus;

    if (order.status == AppConstants.statusPreparing) {
      newStatus = AppConstants.statusPickedUp;
    } else {
      newStatus = AppConstants.statusDelivered;
    }

    final success = await orderProvider.updateOrderStatus(order.id, newStatus);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _downloadOfflineMap() async {
    final offlineService = OfflineMapService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double progress = 0.0;
            return AlertDialog(
              title: const Text('Downloading Peshawar Map'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Caching map tiles for offline use...'),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toStringAsFixed(1)}%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    offlineService.cancelDownload();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      Navigator.pop(context); // Close the initial static dialog
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Map download started in background...')));

      await offlineService.downloadPeshawarRegion(
        onProgress: (p) {
          // Ideally update a global provider or notification
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Peshawar Map Cached Successfully!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }

  bool _canCancelDelivery(String status) {
    // Riders can cancel before delivery completion
    // Allow cancellation for: accepted, preparing, picked_up, in_transit
    return status == AppConstants.statusAccepted ||
        status == AppConstants.statusPreparing ||
        status == AppConstants.statusPickedUp ||
        status == AppConstants.statusInTransit;
  }

  void _showCancelDialog(BuildContext context, OrderModel delivery) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveCancelDialog(
        delivery: delivery,
        onConfirm: (reason) => _cancelDelivery(context, delivery, reason),
      ),
    );
  }

  Future<void> _cancelDelivery(
    BuildContext context,
    OrderModel delivery,
    String reason,
  ) async {
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for cancellation'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.pop(context); // Close dialog

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final orderProvider = context.read<OrderProvider>();
      final authProvider = context.read<AuthProvider>();

      // Cancel the order with rider-specific reason
      final success = await orderProvider.cancelOrder(
        delivery.id,
        'Cancelled by rider (${authProvider.user?.name}): $reason',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery cancelled successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel delivery. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
