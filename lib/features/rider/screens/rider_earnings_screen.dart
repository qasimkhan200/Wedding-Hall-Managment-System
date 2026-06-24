import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/order_service.dart';
import '../../../core/models/order_model.dart';
import 'package:intl/intl.dart';

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  String _selectedPeriod = 'week'; // week, month, all

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final riderId = authProvider.user?.id;

    if (riderId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Earnings',
              style: TextStyle(color: AppColors.primary)),
        ),
        body: const Center(child: Text('Please log in to view earnings')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Earnings',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
                  SizedBox(height: 16.h),
                  Text('Error loading earnings',
                      style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  Text(snapshot.error.toString(),
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          final allOrders = snapshot.data ?? [];
          final riderOrders =
              allOrders.where((order) => order.riderId == riderId).toList();
          final completedOrders = riderOrders
              .where((order) =>
                  order.status == 'delivered' || order.status == 'completed')
              .toList();

          if (completedOrders.isEmpty) {
            return _buildEmptyState();
          }

          final earnings = _calculateEarnings(completedOrders);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalEarningsCard(earnings),
                  SizedBox(height: 16.h),
                  _buildPeriodSelector(),
                  SizedBox(height: 16.h),
                  _buildEarningsBreakdown(earnings),
                  SizedBox(height: 16.h),
                  _buildStatsCards(completedOrders),
                  SizedBox(height: 24.h),
                  _buildSectionTitle('Recent Transactions'),
                  SizedBox(height: 12.h),
                  _buildTransactionsList(completedOrders),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60.r),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 60.w,
                color: AppColors.info,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Earnings Yet',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Complete deliveries to start earning',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalEarningsCard(Map<String, dynamic> earnings) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: Colors.white, size: 24.w),
              SizedBox(width: 8.w),
              Text(
                'Total Earnings',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Rs. ${earnings['total'].toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${earnings['totalDeliveries']} completed deliveries',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Row(
        children: [
          _buildPeriodButton('Today', 'today'),
          _buildPeriodButton('Week', 'week'),
          _buildPeriodButton('Month', 'month'),
          _buildPeriodButton('All Time', 'all'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown(Map<String, dynamic> earnings) {
    final periodEarnings = earnings[_selectedPeriod] as double;
    final periodDeliveries = earnings['${_selectedPeriod}Deliveries'] as int;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getPeriodLabel(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildBreakdownItem(
                  'Earnings',
                  'Rs. ${periodEarnings.toStringAsFixed(0)}',
                  Icons.attach_money,
                  AppColors.success,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildBreakdownItem(
                  'Deliveries',
                  '$periodDeliveries',
                  Icons.delivery_dining,
                  AppColors.info,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildBreakdownItem(
                  'Avg/Delivery',
                  periodDeliveries > 0
                      ? 'Rs. ${(periodEarnings / periodDeliveries).toStringAsFixed(0)}'
                      : 'Rs. 0',
                  Icons.trending_up,
                  AppColors.accent,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildBreakdownItem(
                  'Commission',
                  '70%',
                  Icons.percent,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<OrderModel> orders) {
    final avgDeliveryTime = _calculateAvgDeliveryTime(orders);
    final totalDistance = _calculateTotalDistance(orders);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Avg Time',
            avgDeliveryTime,
            Icons.timer_outlined,
            AppColors.info,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'Distance',
            '${totalDistance.toStringAsFixed(1)} km',
            Icons.route,
            AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.w),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTransactionsList(List<OrderModel> orders) {
    final recentOrders = orders.take(10).toList();

    return Column(
      children: recentOrders.map((order) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatDateTime(order.deliveredAt ?? order.updatedAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+Rs. ${order.riderFee.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _calculateEarnings(List<OrderModel> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    double totalEarnings = 0;
    double todayEarnings = 0;
    double weekEarnings = 0;
    double monthEarnings = 0;

    int todayDeliveries = 0;
    int weekDeliveries = 0;
    int monthDeliveries = 0;

    for (final order in orders) {
      final deliveryDate = order.deliveredAt ?? order.updatedAt;
      totalEarnings += order.riderFee;

      if (deliveryDate.isAfter(today)) {
        todayEarnings += order.riderFee;
        todayDeliveries++;
      }
      if (deliveryDate.isAfter(weekStart)) {
        weekEarnings += order.riderFee;
        weekDeliveries++;
      }
      if (deliveryDate.isAfter(monthStart)) {
        monthEarnings += order.riderFee;
        monthDeliveries++;
      }
    }

    return {
      'total': totalEarnings,
      'today': todayEarnings,
      'week': weekEarnings,
      'month': monthEarnings,
      'all': totalEarnings,
      'totalDeliveries': orders.length,
      'todayDeliveries': todayDeliveries,
      'weekDeliveries': weekDeliveries,
      'monthDeliveries': monthDeliveries,
      'allDeliveries': orders.length,
    };
  }

  String _calculateAvgDeliveryTime(List<OrderModel> orders) {
    if (orders.isEmpty) return '0 min';

    int totalMinutes = 0;
    int validOrders = 0;

    for (final order in orders) {
      if (order.pickedUpAt != null && order.deliveredAt != null) {
        final duration = order.deliveredAt!.difference(order.pickedUpAt!);
        totalMinutes += duration.inMinutes;
        validOrders++;
      }
    }

    if (validOrders == 0) return '0 min';

    final avgMinutes = totalMinutes ~/ validOrders;
    if (avgMinutes < 60) {
      return '$avgMinutes min';
    } else {
      final hours = avgMinutes ~/ 60;
      final minutes = avgMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  double _calculateTotalDistance(List<OrderModel> orders) {
    // Estimate: average 5km per delivery
    return orders.length * 5.0;
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Today\'s Earnings';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'all':
        return 'All Time';
      default:
        return 'Earnings';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }
}
