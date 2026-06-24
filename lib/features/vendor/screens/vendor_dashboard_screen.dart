import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/constants/app_constants.dart';

class VendorDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const VendorDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context.read<OrderProvider>().loadOrdersByVendor(authProvider.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final vendorId = authProvider.user?.id ?? '';
    final vendorName = authProvider.user?.name ?? 'Vendor';

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    // Adaptive grid columns
    final gridColumns = isLargeScreen ? 4 : (isTablet ? 3 : 2);
    final maxContentWidth = isLargeScreen ? 1200.0 : double.infinity;

    // Get current Orders and Revenue
    final todayOrders = orderProvider.orders.where((order) {
      final now = DateTime.now();
      return order.createdAt.year == now.year &&
          order.createdAt.month == now.month &&
          order.createdAt.day == now.day;
    }).toList();

    final todayRevenue = todayOrders.fold(
        0.0,
        (sum, order) =>
            sum + (order.status == 'completed' ? order.totalAmount : 0));

    final completedToday =
        todayOrders.where((order) => order.status == 'completed').length;

    final pendingOrders = orderProvider.pendingOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isTablet ? 24.sp : 22.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: isTablet,
        actions: [
          // Notification bell
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: isTablet ? 28.sp : 26.sp),
                if (pendingOrders.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.w,
                        minHeight: 16.w,
                      ),
                      child: Text(
                        '${pendingOrders.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => widget.onNavigateToTab?.call(1),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.logout_rounded,
                color: AppColors.error, size: isTablet ? 26.sp : 24.sp),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  title: Text('Logout',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  content: Text('Are you sure you want to logout?',
                      style: TextStyle(fontSize: 14.sp)),
                  actions: [
                    TextButton(
                      child: Text('Cancel',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14.sp)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text('Logout',
                          style:
                              TextStyle(color: Colors.white, fontSize: 14.sp)),
                      onPressed: () {
                        Navigator.pop(context);
                        final authProvider = context.read<AuthProvider>();
                        authProvider.signOut();
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (route) => false);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (mounted) {
              context.read<OrderProvider>().loadOrdersByVendor(vendorId);
            }
          },
          color: AppColors.primary,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 24.w : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(
                          vendorName: vendorName,
                          vendorId: vendorId,
                          todayOrders: todayOrders,
                          completedToday: completedToday,
                          todayRevenue: todayRevenue,
                          isTablet: isTablet,
                        ),
                        SizedBox(height: 24.h),
                        _buildQuickActionsSection(isTablet: isTablet),
                        SizedBox(height: 24.h),
                        _buildStatsGrid(
                          vendorId: vendorId,
                          todayOrders: todayOrders,
                          todayRevenue: todayRevenue,
                          pendingOrders: pendingOrders,
                          gridColumns: gridColumns,
                          isTablet: isTablet,
                        ),
                        SizedBox(height: 24.h),
                        _buildOrdersSection(
                          pendingOrders: pendingOrders,
                          isTablet: isTablet,
                        ),
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard({
    required String vendorName,
    required String vendorId,
    required List<OrderModel> todayOrders,
    required int completedToday,
    required double todayRevenue,
    required bool isTablet,
  }) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: isTablet ? 70.w : 60.w,
                height: isTablet ? 70.w : 60.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2.w,
                  ),
                ),
                child: Center(
                  child: Text('🏪',
                      style: TextStyle(fontSize: isTablet ? 36.sp : 32.sp)),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: TextStyle(
                        fontSize: isTablet ? 22.sp : 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: _isOnline ? AppColors.success : Colors.grey,
                            shape: BoxShape.circle,
                            boxShadow: _isOnline
                                ? [
                                    BoxShadow(
                                      color: AppColors.success
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isOnline
                                ? 'Online & Accepting Orders'
                                : 'Offline - Not Taking Orders',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: isTablet ? 1.1 : 1.0,
                child: Switch(
                  value: _isOnline,
                  onChanged: (value) async {
                    setState(() {
                      _isOnline = value;
                    });
                    try {
                      await VendorService.updateVendorStatus(vendorId, value);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'You are now online'
                                  : 'You are now offline',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            backgroundColor: value
                                ? AppColors.success
                                : AppColors.textSecondary,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to update status: $e',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        setState(() {
                          _isOnline = !value;
                        });
                      }
                    }
                  },
                  activeTrackColor: Colors.white.withValues(alpha: 0.5),
                  activeThumbColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: _buildQuickStat(
                    iconWidget: Icon(Icons.shopping_bag_outlined,
                        color: Colors.white, size: isTablet ? 26.sp : 24.sp),
                    label: 'Orders',
                    value: '${todayOrders.length}',
                    isTablet: isTablet,
                  ),
                ),
                Container(
                  width: 1.w,
                  height: 40.h,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Flexible(
                  child: _buildQuickStat(
                    iconWidget: Icon(Icons.check_circle_outline,
                        color: Colors.white, size: isTablet ? 26.sp : 24.sp),
                    label: 'Completed',
                    value: '$completedToday',
                    isTablet: isTablet,
                  ),
                ),
                Container(
                  width: 1.w,
                  height: 40.h,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Flexible(
                  child: _buildQuickStat(
                    iconWidget: Text(
                      'PKR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 16.sp : 14.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    label: 'Revenue',
                    value: '${todayRevenue.toStringAsFixed(0)}',
                    isTablet: isTablet,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required Widget iconWidget,
    required String label,
    required String value,
    required bool isTablet,
  }) {
    return Column(
      children: [
        iconWidget,
        SizedBox(height: 8.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 20.sp : 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection({required bool isTablet}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: isTablet ? 20.sp : 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.add_shopping_cart,
                  label: 'Add Item',
                  color: AppColors.primary,
                  onTap: () => widget.onNavigateToTab?.call(2),
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  color: AppColors.secondary,
                  onTap: () => widget.onNavigateToTab?.call(2),
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.receipt_long,
                  label: 'Orders',
                  color: AppColors.info,
                  onTap: () => widget.onNavigateToTab?.call(1),
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 24.h : 20.h),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 16.w : 14.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: isTablet ? 32.w : 28.w),
              ),
              SizedBox(height: 12.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 14.sp : 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid({
    required String vendorId,
    required List<OrderModel> todayOrders,
    required double todayRevenue,
    required List<OrderModel> pendingOrders,
    required int gridColumns,
    required bool isTablet,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.count(
        crossAxisCount: gridColumns,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: isTablet ? 1.4 : 1.25,
        children: [
          _buildStatCard(
            context,
            icon: Icons.receipt_long_outlined,
            title: "Today's Orders",
            value: "${todayOrders.length}",
            color: AppColors.info,
            bgColor: AppColors.info.withValues(alpha: 0.1),
            trend: '+12%',
            onTap: () => widget.onNavigateToTab?.call(1),
            isTablet: isTablet,
          ),
          _buildStatCard(
            context,
            icon: Icons.currency_rupee,
            iconWidget: Text(
              'PKR',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: isTablet ? 13.sp : 12.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            title: "Today's Revenue",
            value: "PKR ${todayRevenue.toStringAsFixed(0)}",
            color: AppColors.success,
            bgColor: AppColors.success.withValues(alpha: 0.1),
            trend: '+8%',
            isTablet: isTablet,
          ),
          _buildStatCard(
            context,
            icon: Icons.pending_actions_outlined,
            title: "Pending",
            value: "${pendingOrders.length}",
            color: AppColors.warning,
            bgColor: AppColors.warning.withValues(alpha: 0.1),
            onTap: () => widget.onNavigateToTab?.call(1),
            isTablet: isTablet,
          ),
          StreamBuilder<List<ItemModel>>(
            stream:
                VendorService.getItemsByVendor(vendorId, includeInactive: true),
            builder: (context, snapshot) {
              final itemCount = snapshot.data?.length ?? 0;
              return _buildStatCard(
                context,
                icon: Icons.inventory_2_outlined,
                title: "Total Items",
                value: "$itemCount",
                color: AppColors.secondary,
                bgColor: AppColors.secondary.withValues(alpha: 0.1),
                onTap: () => widget.onNavigateToTab?.call(2),
                isTablet: isTablet,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    Widget? iconWidget,
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    String? trend,
    VoidCallback? onTap,
    required bool isTablet,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16.w : 14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: color.withValues(alpha: 0.1),
              width: 1.5.w,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon and Trend Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 10.w : 8.w),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: iconWidget ??
                              Icon(icon,
                                  color: color, size: isTablet ? 24.w : 22.w),
                        ),
                      ),
                      if (trend != null) ...[
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                trend,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Spacer
                  SizedBox(height: 8.h),
                  // Value
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: isTablet ? 22.sp : 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  // Small spacer
                  SizedBox(height: 2.h),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersSection({
    required List<OrderModel> pendingOrders,
    required bool isTablet,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Orders',
                style: TextStyle(
                  fontSize: isTablet ? 20.sp : 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              if (pendingOrders.isNotEmpty)
                TextButton.icon(
                  onPressed: () => widget.onNavigateToTab?.call(1),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          pendingOrders.isEmpty
              ? Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(vertical: isTablet ? 60.h : 48.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border:
                        Border.all(color: Colors.grey.shade200, width: 1.5.w),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.inbox_outlined,
                            size: isTablet ? 56.w : 48.w,
                            color: AppColors.primary.withValues(alpha: 0.6)),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No pending orders',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: isTablet ? 18.sp : 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'New orders will appear here',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      pendingOrders.length > 5 ? 5 : pendingOrders.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) => _buildNewOrderCard(
                    context,
                    pendingOrders[index],
                    isTablet: isTablet,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildNewOrderCard(
    BuildContext context,
    OrderModel order, {
    required bool isTablet,
  }) {
    final timeAgo = _getTimeAgo(order.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20.w : 18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12.w : 10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.shopping_bag_outlined,
                      color: AppColors.primary, size: isTablet ? 24.w : 22.w),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 6).toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 16.sp : 15.sp,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14.sp, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 14.w : 12.w,
                      vertical: isTablet ? 10.h : 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 16.sp : 15.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Divider(
                  color: Colors.grey.shade200, height: 1, thickness: 1.5),
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(Icons.layers_outlined,
                            size: 16.w, color: AppColors.info),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          '${order.items.length} Items',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(Icons.location_on_outlined,
                            size: 16.w, color: AppColors.success),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          order.deliveryAddress.isEmpty
                              ? 'No address'
                              : order.deliveryAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectOrder(order.id),
                    icon: const Icon(Icons.close, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Reject'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error, width: 1.5.w),
                      padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16.h : 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptOrder(order.id),
                    icon: const Icon(Icons.check, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Accept'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16.h : 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12.w),
              const Expanded(child: Text('Order accepted successfully')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 12.w),
              const Expanded(child: Text('Order rejected')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }
}
