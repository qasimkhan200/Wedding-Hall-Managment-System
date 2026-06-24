import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/models/order_model.dart';
import 'rider_assignment_screen.dart';
import '../../../core/services/review_service.dart';
import '../../../core/models/review_model.dart';
import '../../common/widgets/rating_dialog.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'new';
  String _orderSearchQuery = '';
  final TextEditingController _orderSearchController = TextEditingController();
  bool _showOrderSearch = false;

  @override
  void dispose() {
    _orderSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context.read<OrderProvider>().loadOrdersByVendor(authProvider.user!.id);
      }
    });
  }

  void _showRateHostDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        title: 'Rate Host',
        message: 'How was your experience with ${order.hostName}?',
        onSubmit: (rating, comment) async {
          final authProvider = context.read<AuthProvider>();
          final user = authProvider.user;
          if (user == null) return;

          final review = ReviewModel(
            id: '',
            orderId: order.id,
            reviewerId: user.id,
            reviewerName: user.name, // Vendor uses name from UserModel
            revieweeId: order.hostId,
            revieweeRole: 'host',
            rating: rating,
            comment: comment,
            createdAt: DateTime.now(),
          );

          await ReviewService.submitReview(review);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Review submitted successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<OrderProvider>().loadOrdersByVendor(user.id);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Orders',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showOrderSearch
                  ? Icons.search_off_rounded
                  : Icons.search_rounded,
              color:
                  _showOrderSearch ? AppColors.primary : AppColors.textPrimary,
              size: 24.sp,
            ),
            onPressed: () {
              setState(() {
                _showOrderSearch = !_showOrderSearch;
                if (!_showOrderSearch) {
                  _orderSearchQuery = '';
                  _orderSearchController.clear();
                }
              });
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final newOrders = orderProvider.pendingOrders;
          final activeOrders = _getActiveOrders(orderProvider.orders);
          final cancelledOrders = _getCancelledOrders(orderProvider.orders);
          final completedOrders = orderProvider.completedOrders;

          final Map<String, List<OrderModel>> tabData = {
            'new': newOrders,
            'active': activeOrders,
            'cancelled': cancelledOrders,
            'completed': completedOrders,
          };

          return Column(
            children: [
              // Search Bar
              if (_showOrderSearch)
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                  child: TextField(
                    controller: _orderSearchController,
                    autofocus: true,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'Search by order number...',
                      hintStyle: TextStyle(
                          fontSize: 13.sp, color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.primary, size: 20.sp),
                      suffixIcon: _orderSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  size: 18.sp, color: AppColors.textSecondary),
                              onPressed: () => setState(() {
                                _orderSearchQuery = '';
                                _orderSearchController.clear();
                              }),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _orderSearchQuery = v.trim()),
                  ),
                ),
              // Filter Bar
              _buildFilterBar(
                newCount: newOrders.length,
                activeCount: activeOrders.length,
                cancelledCount: cancelledOrders.length,
                completedCount: completedOrders.length,
              ),
              // Orders List
              Expanded(
                child: _buildOrdersList(
                  _applyOrderSearch(tabData[_selectedFilter] ?? []),
                  _selectedFilter,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar({
    required int newCount,
    required int activeCount,
    required int cancelledCount,
    required int completedCount,
  }) {
    final filters = [
      {
        'key': 'new',
        'label': 'New',
        'count': newCount,
        'icon': Icons.fiber_new_rounded,
        'color': AppColors.primary,
      },
      {
        'key': 'active',
        'label': 'Active',
        'count': activeCount,
        'icon': Icons.local_shipping_rounded,
        'color': AppColors.accepted,
      },
      {
        'key': 'cancelled',
        'label': 'Cancelled',
        'count': cancelledCount,
        'icon': Icons.cancel_rounded,
        'color': AppColors.error,
      },
      {
        'key': 'completed',
        'label': 'Done',
        'count': completedCount,
        'icon': Icons.check_circle_rounded,
        'color': AppColors.success,
      },
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          final color = f['color'] as Color;
          final count = f['count'] as int;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: 1.5.w,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          f['icon'] as IconData,
                          size: 22.sp,
                          color: isSelected ? Colors.white : color,
                        ),
                        if (count > 0)
                          Positioned(
                            top: -4.h,
                            right: -6.w,
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : color,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? color : Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<OrderModel> _applyOrderSearch(List<OrderModel> orders) {
    if (_orderSearchQuery.isEmpty) return orders;
    final q = _orderSearchQuery.toLowerCase();
    return orders
        .where((o) =>
            o.id.toLowerCase().contains(q) ||
            o.id
                .substring(0, o.id.length.clamp(0, 8))
                .toLowerCase()
                .contains(q))
        .toList();
  }

  List<OrderModel> _getActiveOrders(List<OrderModel> orders) {
    return orders
        .where((o) =>
            o.status == AppConstants.statusAccepted ||
            o.status == AppConstants.statusPreparing ||
            o.status == AppConstants.statusPickedUp ||
            o.status == AppConstants.statusInTransit)
        .toList();
  }

  List<OrderModel> _getCancelledOrders(List<OrderModel> orders) {
    return orders
        .where((o) => o.status == AppConstants.statusCancelled)
        .toList();
  }

  Widget _buildOrdersList(List<OrderModel> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(28.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 52.sp,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No ${type == 'new' ? 'New' : type == 'active' ? 'Active' : type == 'cancelled' ? 'Cancelled' : 'Completed'} Orders',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Orders will appear here',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: orders.length,
      itemBuilder: (context, index) =>
          _buildVendorOrderCard(context, orders[index], type),
    );
  }

  Widget _buildVendorOrderCard(
      BuildContext context, OrderModel order, String type) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.receipt_rounded,
                      size: 16.sp, color: statusColor),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Body ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_rounded,
                        size: 15.sp, color: AppColors.textSecondary),
                    SizedBox(width: 6.w),
                    Text(
                      order.hostName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 15.sp, color: AppColors.textSecondary),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Divider(color: Colors.grey.shade100, height: 1),
                ),
                // Items
                ...order.items.map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        children: [
                          Container(
                            width: 22.w,
                            height: 22.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(item.productName,
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.textPrimary)),
                          ),
                          Text(
                            'Rs. ${(item.price * item.quantity).toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    )),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Divider(color: Colors.grey.shade100, height: 1),
                ),
                // Financials
                _financeRow(
                    'Subtotal', 'Rs. ${order.subtotal.toStringAsFixed(0)}'),
                SizedBox(height: 4.h),
                _financeRow('Commission',
                    '- Rs. ${order.commissionAmount.toStringAsFixed(0)}',
                    color: AppColors.error),
                SizedBox(height: 8.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Earnings',
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success)),
                      Text(
                        'Rs. ${(order.subtotal - order.commissionAmount).toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success),
                      ),
                    ],
                  ),
                ),
                // ── Action Buttons ───────────────────────
                if (type == 'new') ...[
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                          child: _actionButton(
                              label: 'Reject',
                              icon: Icons.close_rounded,
                              color: AppColors.error,
                              outlined: true,
                              onTap: () => _rejectOrder(order.id))),
                      SizedBox(width: 10.w),
                      Expanded(
                          child: _actionButton(
                              label: 'Accept',
                              icon: Icons.check_rounded,
                              color: AppColors.success,
                              onTap: () => _acceptOrder(order.id))),
                    ],
                  ),
                ],
                if (type == 'active' &&
                    order.status == AppConstants.statusAccepted) ...[
                  SizedBox(height: 14.h),
                  _actionButton(
                      label: 'Mark as Ready',
                      icon: Icons.done_all_rounded,
                      color: AppColors.secondary,
                      fullWidth: true,
                      onTap: () => _markAsReady(order.id)),
                ],
                if (type == 'active' &&
                    order.status == AppConstants.statusPreparing &&
                    (order.riderId == null || order.riderId!.isEmpty)) ...[
                  SizedBox(height: 14.h),
                  _actionButton(
                      label: 'Assign Rider',
                      icon: Icons.delivery_dining_rounded,
                      color: AppColors.primary,
                      fullWidth: true,
                      onTap: () => _assignRider(order)),
                ],
                if (type == 'active' &&
                    order.status == AppConstants.statusPreparing &&
                    order.riderId != null &&
                    order.riderId!.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(8.r)),
                          child: Icon(Icons.delivery_dining_rounded,
                              color: Colors.white, size: 16.sp),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rider Assigned',
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success)),
                              if (order.riderName != null)
                                Text(order.riderName!,
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _viewRiderAssignment(order),
                          child: Text('Details',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 12.sp)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (type == 'completed' && !order.isHostReviewed) ...[
                  SizedBox(height: 14.h),
                  _actionButton(
                      label: 'Rate Host',
                      icon: Icons.star_rounded,
                      color: Colors.amber.shade700,
                      fullWidth: true,
                      onTap: () => _showRateHostDialog(context, order)),
                ],
                if (type == 'cancelled') ...[
                  if (order.cancellationReason != null &&
                      order.cancellationReason!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_rounded,
                              color: AppColors.error, size: 16.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(order.cancellationReason!,
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  _actionButton(
                      label: 'Reassign Rider',
                      icon: Icons.refresh_rounded,
                      color: AppColors.primary,
                      fullWidth: true,
                      onTap: () => _reassignRider(order)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.sp, color: color ?? AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.textPrimary)),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color, width: 1.5.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: outlined ? color : Colors.white),
            SizedBox(width: 6.w),
            Text(label,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: outlined ? color : Colors.white)),
          ],
        ),
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
        return 'In Transit';
      case AppConstants.statusDelivered:
        return 'Delivered';
      default:
        return status;
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.updateOrderStatus(
      orderId,
      AppConstants.statusAccepted,
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

  Future<void> _rejectOrder(String orderId) async {
    final orderProvider = context.read<OrderProvider>();
    final success =
        await orderProvider.cancelOrder(orderId, 'Rejected by vendor');

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order rejected'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _markAsReady(String orderId) async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.updateOrderStatus(
      orderId,
      AppConstants.statusPreparing,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as ready for pickup'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _assignRider(OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RiderAssignmentScreen(order: order),
      ),
    );
  }

  void _viewRiderAssignment(OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RiderAssignmentScreen(order: order),
      ),
    );
  }

  Future<void> _reassignRider(OrderModel order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Rider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This order was cancelled by the rider.'),
            SizedBox(height: 8.h),
            const Text('Would you like to assign a new rider?'),
            if (order.cancellationReason != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Reason: ${order.cancellationReason}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Assign New Rider'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Update order status back to preparing so it can be reassigned
        await context.read<OrderProvider>().updateOrderStatus(
              order.id,
              AppConstants.statusPreparing,
            );

        if (mounted) {
          // Navigate to rider assignment screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RiderAssignmentScreen(order: order),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order ready for rider assignment'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reassign: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
