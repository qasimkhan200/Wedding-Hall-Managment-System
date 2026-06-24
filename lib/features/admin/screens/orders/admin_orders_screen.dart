import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/providers/order_provider.dart';
import '../../../../../core/models/order_model.dart'; // Import OrderStatus
import 'widgets/order_card.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabSelection);
    // Load all orders for admin
    Future.microtask(() => context.read<OrderProvider>().loadAllOrders());
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      final provider = context.read<OrderProvider>();
      switch (_tabController.index) {
        case 0: // All
          provider.setFilterStatus(null);
          break;
        case 1: // Pending
          provider.setFilterStatus(OrderStatus.pending);
          break;
        case 2: // Accepted
          provider.setFilterStatus(OrderStatus.vendorAccepted);
          break;
        case 3: // In Transit
          provider.setFilterStatus(OrderStatus.inTransit);
          break;
        case 4: // Delivered
          provider.setFilterStatus(OrderStatus.delivered);
          break;
        case 5: // Cancelled
          provider.setFilterStatus(OrderStatus.cancelled);
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> _filterBySearch(List<OrderModel> orders) {
    if (_searchQuery.isEmpty) return orders;
    final lowerQuery = _searchQuery.toLowerCase();
    return orders.where((order) {
      return order.id.toLowerCase().contains(lowerQuery) ||
          order.hostName.toLowerCase().contains(lowerQuery) ||
          order.vendorName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Lighter background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Manage Orders',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => context.read<OrderProvider>().loadAllOrders(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(110.h),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search orders by ID, Customer, or Vendor...',
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.grey[600], size: 20.w),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18.w),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Accepted'),
                  Tab(text: 'In Transit'),
                  Tab(text: 'Delivered'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final orders = _filterBySearch(provider.filteredOrders);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Revenue',
                              value:
                                  'Rs ${provider.totalRevenue.toStringAsFixed(0)}',
                              icon: Icons.attach_money,
                              color: Colors.green,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade500,
                                  Colors.green.shade400
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Pending Action',
                              value: provider.pendingOrders.length.toString(),
                              icon: Icons.pending_actions,
                              color: Colors.orange,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade500,
                                  Colors.orange.shade400
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (orders.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64.w, color: Colors.grey[400]),
                        SizedBox(height: 16.h),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = orders[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: OrderCard(
                            order: order,
                            onTap: () {
                              // Navigate to details
                            },
                          ),
                        );
                      },
                      childCount: orders.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 32.h)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Gradient? gradient;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: gradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: Colors.white, size: 20.w),
          ),
          SizedBox(height: 16.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
