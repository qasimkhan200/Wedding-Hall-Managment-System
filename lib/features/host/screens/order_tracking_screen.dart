import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';
import 'location_picker_screen.dart';
import 'package:latlong2/latlong.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 8)}',
            style: TextStyle(color: AppColors.primary)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250.h,
            child: Stack(
              children: [
                // Map placeholder - Mapbox integration removed
                Container(
                  color: AppColors.inputBackground,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64.w,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Map View',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${order.deliveryLatitude.toStringAsFixed(4)}, ${order.deliveryLongitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          color: _getStatusColor(order.status),
                          size: 16.w,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Live Tracking',
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color:
                                _getStatusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              _getStatusEmoji(order.status),
                              style: TextStyle(fontSize: 30.sp),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(order.status),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(order.status),
                                    ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Estimated delivery: ${order.estimatedDeliveryMinutes} mins',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Order Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 16.h),
                  _buildStatusTimeline(context),
                  SizedBox(height: 24.h),
                  if (order.riderName != null) ...[
                    Text(
                      'Rider Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Center(
                              child:
                                  Text('🛵', style: TextStyle(fontSize: 24.sp)),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.riderName!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  order.riderPhone ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Icon(
                                  Icons.call,
                                  color: AppColors.success,
                                  size: 20.w,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Icon(
                                  Icons.message,
                                  color: AppColors.info,
                                  size: 20.w,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),

                  // Change Location Button
                  if (order.status == AppConstants.statusPending ||
                      order.status == AppConstants.statusAccepted ||
                      order.status == AppConstants.statusPreparing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Address',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit_location, size: 16),
                          label: const Text('Change'),
                          onPressed: () async {
                            final LatLng? result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocationPickerScreen(
                                  initialPosition: LatLng(
                                    order.deliveryLatitude,
                                    order.deliveryLongitude,
                                  ),
                                ),
                              ),
                            );

                            if (result != null && context.mounted) {
                              try {
                                await OrderService.updateOrderLocation(
                                  order.id,
                                  result.latitude,
                                  result.longitude,
                                  'Updated Location', // Ideally reverse geocode here
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Location updated successfully'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    )
                  else
                    Text(
                      'Delivery Address',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 24.w,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            order.deliveryAddress,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(BuildContext context) {
    final statuses = [
      {
        'status': AppConstants.statusPending,
        'title': 'Order Placed',
        'subtitle': 'Waiting for vendor'
      },
      {
        'status': AppConstants.statusAccepted,
        'title': 'Order Accepted',
        'subtitle': 'Vendor is preparing'
      },
      {
        'status': AppConstants.statusPreparing,
        'title': 'Preparing',
        'subtitle': 'Getting items ready'
      },
      {
        'status': AppConstants.statusPickedUp,
        'title': 'Picked Up',
        'subtitle': 'Rider collected order'
      },
      {
        'status': AppConstants.statusInTransit,
        'title': 'On the Way',
        'subtitle': 'Rider is coming'
      },
      {
        'status': AppConstants.statusDelivered,
        'title': 'Delivered',
        'subtitle': 'Order completed'
      },
    ];

    final currentIndex =
        statuses.indexWhere((s) => s['status'] == order.status);

    return Column(
      children: List.generate(statuses.length, (index) {
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.inputBackground,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: AppColors.success, width: 3.w)
                        : null,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, color: Colors.white, size: 14.w)
                      : null,
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2.w,
                    height: 40.h,
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.inputBackground,
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statuses[index]['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isCompleted
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      statuses[index]['subtitle'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppColors.pending;
      case AppConstants.statusAccepted:
        return AppColors.accepted;
      case AppConstants.statusPreparing:
        return AppColors.preparing;
      case AppConstants.statusPickedUp:
        return AppColors.pickedUp;
      case AppConstants.statusInTransit:
        return AppColors.inTransit;
      case AppConstants.statusDelivered:
        return AppColors.delivered;
      case AppConstants.statusCancelled:
        return AppColors.cancelled;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusEmoji(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return '⏳';
      case AppConstants.statusAccepted:
        return '✅';
      case AppConstants.statusPreparing:
        return '📦';
      case AppConstants.statusPickedUp:
        return '🛵';
      case AppConstants.statusInTransit:
        return '🚀';
      case AppConstants.statusDelivered:
        return '🎉';
      case AppConstants.statusCancelled:
        return '❌';
      default:
        return '📋';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Order Placed';
      case AppConstants.statusAccepted:
        return 'Order Accepted';
      case AppConstants.statusPreparing:
        return 'Preparing Your Order';
      case AppConstants.statusPickedUp:
        return 'Order Picked Up';
      case AppConstants.statusInTransit:
        return 'On the Way';
      case AppConstants.statusDelivered:
        return 'Delivered';
      case AppConstants.statusCancelled:
        return 'Cancelled';
      default:
        return 'Processing';
    }
  }
}
