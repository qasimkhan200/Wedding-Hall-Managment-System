import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/order_model.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_widgets.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ResponsiveText(
                  'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                ),
              ),
              ResponsiveContainer(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.sm,
                  vertical: ResponsiveUtils.xs,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.radiusXs),
                ),
                child: ResponsiveText(
                  _getStatusText(order.status),
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontSize: ResponsiveUtils.caption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.mdHeight),
          Row(
            children: [
              Icon(Icons.store,
                  size: ResponsiveUtils.iconSm, color: AppColors.textSecondary),
              SizedBox(width: ResponsiveUtils.xs),
              Expanded(
                child: ResponsiveText(
                  order.vendorName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.smHeight),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: ResponsiveUtils.iconSm, color: AppColors.textSecondary),
              SizedBox(width: ResponsiveUtils.xs),
              Expanded(
                child: ResponsiveText(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Divider(height: ResponsiveUtils.xlHeight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                '${order.items.length} items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              ResponsiveText(
                'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          if (order.status != AppConstants.statusDelivered &&
              order.status != AppConstants.statusCancelled) ...[
            SizedBox(height: ResponsiveUtils.mdHeight),
            Row(
              children: [
                Expanded(
                  child: ResponsiveText(
                    order.status == AppConstants.statusInTransit
                        ? 'Rider is on the way'
                        : 'Estimated delivery: ${order.estimatedDeliveryMinutes} mins',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 2,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: ResponsiveUtils.iconSm,
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

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusAccepted:
        return 'Accepted';
      case AppConstants.statusPreparing:
        return 'Preparing';
      case AppConstants.statusPickedUp:
        return 'Picked Up';
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
