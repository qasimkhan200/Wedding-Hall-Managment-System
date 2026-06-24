import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/order_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/widgets/responsive_widgets.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onAssign;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onAccept,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              ResponsiveContainer(
                padding: ResponsiveUtils.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.radiusSm),
                ),
                child: Icon(Icons.receipt_long,
                    color: AppColors.primary, size: ResponsiveUtils.iconSm),
              ),
              SizedBox(width: ResponsiveUtils.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Order #${order.id.substring(0, 8)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.body1,
                        color: Colors.black87,
                      ),
                    ),
                    ResponsiveText(
                      DateFormat('MMM dd, hh:mm a').format(order.createdAt),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.caption,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(order.orderStatus),
            ],
          ),
          SizedBox(height: ResponsiveUtils.mdHeight),

          // Emergency Banner if needed
          if (order.isEmergency)
            ResponsiveContainer(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: ResponsiveUtils.mdHeight),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.md,
                vertical: ResponsiveUtils.smHeight,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(ResponsiveUtils.radiusSm),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: ResponsiveUtils.iconSm, color: Colors.red),
                  SizedBox(width: ResponsiveUtils.sm),
                  ResponsiveText(
                    'Emergency Priority',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.body2,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Info Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelValue('Customer', order.hostName),
                    SizedBox(height: ResponsiveUtils.smHeight),
                    _buildLabelValue('Vendor', order.vendorName),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildLabelValue(
                        'Amount', 'Rs ${order.totalAmount.toStringAsFixed(0)}',
                        isBold: true, alignRight: true),
                    SizedBox(height: ResponsiveUtils.smHeight),
                    _buildLabelValue('Items', '${order.items.length}'),
                  ],
                ),
              ),
            ],
          ),

          // Address (Full width)
          SizedBox(height: ResponsiveUtils.mdHeight),
          ResponsiveContainer(
            padding: ResponsiveUtils.paddingSm,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(ResponsiveUtils.radiusSm),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: ResponsiveUtils.iconSm, color: Colors.grey[600]),
                SizedBox(width: ResponsiveUtils.sm),
                Expanded(
                  child: ResponsiveText(
                    order.deliveryAddress,
                    style: TextStyle(
                        fontSize: ResponsiveUtils.body2,
                        color: Colors.grey[700]),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (onAccept != null || onAssign != null) ...[
            SizedBox(height: ResponsiveUtils.mdHeight),
            Row(
              children: [
                if (onAccept != null)
                  Expanded(
                    child: ResponsiveButton(
                      text: 'Accept Order',
                      onPressed: onAccept,
                      backgroundColor: Colors.green,
                    ),
                  ),
                if (onAccept != null && onAssign != null)
                  SizedBox(width: ResponsiveUtils.md),
                if (onAssign != null)
                  Expanded(
                    child: ResponsiveButton(
                      text: 'Assign Rider',
                      onPressed: onAssign,
                      backgroundColor: Colors.transparent,
                      textColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabelValue(String label, String value,
      {bool isBold = false, bool alignRight = false}) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.caption,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveUtils.xsHeight),
        ResponsiveText(
          value,
          style: TextStyle(
            fontSize: ResponsiveUtils.body2,
            color: isBold ? Colors.black : Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    Color bg;
    String label = status.toString().split('.').last.toUpperCase();

    // Map new logical names to UI labels
    if (status == OrderStatus.vendorAccepted) label = 'ACCEPTED';
    if (status == OrderStatus.riderAssigned) label = 'ASSIGNED';

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange.shade700;
        bg = Colors.orange.shade50;
        break;
      case OrderStatus.vendorAccepted:
        color = Colors.blue.shade700;
        bg = Colors.blue.shade50;
        break;
      case OrderStatus.riderAssigned:
        color = Colors.indigo.shade700;
        bg = Colors.indigo.shade50;
        break;
      case OrderStatus.inTransit:
        color = Colors.purple.shade700;
        bg = Colors.purple.shade50;
        break;
      case OrderStatus.delivered:
        color = Colors.green.shade700;
        bg = Colors.green.shade50;
        break;
      case OrderStatus.cancelled:
        color = Colors.red.shade700;
        bg = Colors.red.shade50;
        break;
      default:
        color = Colors.grey.shade700;
        bg = Colors.grey.shade100;
    }

    return ResponsiveContainer(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.sm,
        vertical: ResponsiveUtils.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ResponsiveUtils.radiusXl),
      ),
      child: ResponsiveText(
        label,
        style: TextStyle(
          fontSize: ResponsiveUtils.caption,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
