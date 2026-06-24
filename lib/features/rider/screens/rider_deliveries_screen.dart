import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/models/order_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/delivery_calculation_service.dart';
import 'package:latlong2/latlong.dart';
import 'rider_navigation_screen.dart';
import '../widgets/delivery_confirmation_sheet.dart';
import '../widgets/responsive_cancel_dialog.dart';

class RiderDeliveriesScreen extends StatefulWidget {
  const RiderDeliveriesScreen({super.key});

  @override
  State<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load fresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context.read<OrderProvider>().loadOrdersByRider(authProvider.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries',
            style: TextStyle(color: AppColors.primary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeDeliveries = orderProvider.activeOrders;
          final completedDeliveries = orderProvider.completedOrders;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDeliveriesList(activeDeliveries, isActive: true),
              _buildDeliveriesList(completedDeliveries, isActive: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeliveriesList(List<OrderModel> deliveries,
      {required bool isActive}) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛵', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active deliveries' : 'No completed deliveries',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        return _buildDeliveryCard(context, delivery, isActive);
      },
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context,
    OrderModel delivery,
    bool isActive,
  ) {
    final statusColor = _getStatusColor(delivery.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                'Order #${delivery.id.substring(0, 8)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatStatus(delivery.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
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
              Expanded(
                child: Text(
                  'Pickup: ${delivery.vendorName}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Drop: ${delivery.deliveryAddress}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<LocationProvider>(
                builder: (context, locationProvider, child) {
                  // Calculate dynamic estimated time based on rider and delivery location
                  String estimatedTime = '30 min';

                  if (locationProvider.hasLocation &&
                      delivery.deliveryLatitude != 0 &&
                      delivery.deliveryLongitude != 0) {
                    final distanceKm =
                        DeliveryCalculationService.calculateDistance(
                      lat1: locationProvider.latitude!,
                      lon1: locationProvider.longitude!,
                      lat2: delivery.deliveryLatitude,
                      lon2: delivery.deliveryLongitude,
                    );

                    final estimatedMinutes =
                        DeliveryCalculationService.calculateDeliveryTime(
                      distanceKm: distanceKm,
                      vehicleType: 'bike',
                      preparationTime:
                          5, // Reduced since order is already prepared
                    );

                    estimatedTime =
                        DeliveryCalculationService.formatDeliveryTime(
                            estimatedMinutes);
                  }

                  return Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Est: $estimatedTime',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  );
                },
              ),
              Text(
                'Earned: Rs. ${(delivery.riderFee > 0 ? delivery.riderFee : delivery.deliveryFee * 0.7).toStringAsFixed(0)}', // Fallback to 70% if riderFee not set (old orders)
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RiderNavigationScreen(
                            destination: LatLng(
                              delivery.deliveryLatitude,
                              delivery.deliveryLongitude,
                            ),
                            destinationAddress: delivery.deliveryAddress,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 8),
                // Cancel button - only show for certain statuses
                if (_canCancelDelivery(delivery.status))
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, delivery),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                    ),
                  ),
                if (_canCancelDelivery(delivery.status))
                  const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, delivery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: Text(_getNextActionText(delivery.status)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusDelivered:
        return AppColors.delivered;
      case AppConstants.statusInTransit:
        return AppColors.inTransit;
      case AppConstants.statusPickedUp:
        return Colors.blue;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'Unknown';
    // Capitalize first letter
    return status[0].toUpperCase() + status.substring(1);
  }

  String _getNextActionText(String status) {
    if (status == AppConstants.statusPickedUp ||
        status == AppConstants.statusInTransit) {
      return 'Delivered';
    } else if (status == AppConstants.statusPreparing ||
        status == AppConstants.statusAccepted) {
      return 'Picked Up';
    }
    return 'Update Status';
  }

  void _updateStatus(BuildContext context, OrderModel delivery) {
    // Determine next status
    if (delivery.status == AppConstants.statusPickedUp ||
        delivery.status == AppConstants.statusInTransit) {
      _showDeliveryConfirmation(context, delivery);
    } else {
      // Just update to picked up directly for now, or add logic
      context
          .read<OrderProvider>()
          .updateOrderStatus(delivery.id, AppConstants.statusPickedUp);
    }
  }

  void _showDeliveryConfirmation(BuildContext context, OrderModel delivery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DeliveryConfirmationSheet(
        order: delivery,
        onSuccess: () {
          // No need to manually update provider status here as StorageService does it via Firestore listener
          // But refreshing local list might be good if not using streams (OrderProvider uses streams)
        },
      ),
    );
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
