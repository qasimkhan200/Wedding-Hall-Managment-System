import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/vendor_model.dart';

class CategoryAnalyticsScreen extends StatefulWidget {
  final CategoryModel? category;

  const CategoryAnalyticsScreen({super.key, this.category});

  @override
  State<CategoryAnalyticsScreen> createState() =>
      _CategoryAnalyticsScreenState();
}

class _CategoryAnalyticsScreenState extends State<CategoryAnalyticsScreen> {
  bool _isLoading = true;
  List<OrderModel> _orders = [];
  List<VendorModel> _vendors = [];
  double _totalRevenue = 0.0;
  int _totalOrders = 0;
  int _activeVendors = 0;
  double _avgRating = 0.0;
  List<Map<String, dynamic>> _topVendors = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      // Load orders and vendors simultaneously
      final ordersStream = OrderService.getAllOrders();
      final vendorsStream = VendorService.getApprovedVendors();

      ordersStream.listen((orders) async {
        List<OrderModel> filteredOrders = orders;

        // Filter by category if specified
        if (widget.category != null) {
          filteredOrders = orders
              .where((order) => order.category == widget.category!.name)
              .toList();
        }

        // Get vendors data
        vendorsStream.listen((vendors) {
          _calculateMetrics(filteredOrders, vendors);

          if (mounted) {
            setState(() {
              _orders = filteredOrders;
              _vendors = vendors;
              _isLoading = false;
            });
          }
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateMetrics(List<OrderModel> orders, List<VendorModel> vendors) {
    // Calculate total revenue
    _totalRevenue = orders.fold(0.0, (sum, order) => sum + order.totalAmount);

    // Total orders
    _totalOrders = orders.length;

    // Active vendors (vendors with at least one order)
    final vendorIds = orders.map((o) => o.vendorId).toSet();
    _activeVendors = vendorIds.length;

    // Calculate average rating from vendors
    if (vendors.isNotEmpty) {
      final totalRating =
          vendors.fold(0.0, (sum, vendor) => sum + vendor.rating);
      _avgRating = totalRating / vendors.length;
    }

    // Calculate top vendors
    _calculateTopVendors(orders, vendors);
  }

  void _calculateTopVendors(
      List<OrderModel> orders, List<VendorModel> vendors) {
    final vendorStats = <String, Map<String, dynamic>>{};

    // Initialize vendor stats
    for (final vendor in vendors) {
      vendorStats[vendor.id] = {
        'name': vendor.businessName,
        'revenue': 0.0,
        'orders': 0,
        'completionRate': 0.0,
      };
    }

    // Calculate stats from orders
    for (final order in orders) {
      if (vendorStats.containsKey(order.vendorId)) {
        vendorStats[order.vendorId]!['revenue'] += order.totalAmount;
        vendorStats[order.vendorId]!['orders'] += 1;
      }
    }

    // Calculate completion rates and sort by revenue
    final vendorList = vendorStats.entries.map((entry) {
      final stats = entry.value;
      final completedOrders = orders
          .where((o) =>
              o.vendorId == entry.key &&
              (o.status == 'delivered' || o.status == 'completed'))
          .length;

      final completionRate =
          stats['orders'] > 0 ? (completedOrders / stats['orders'] * 100) : 0.0;

      return {
        'name': stats['name'],
        'revenue': stats['revenue'],
        'completionRate': completionRate,
      };
    }).toList();

    // Sort by revenue and take top 5
    vendorList.sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    _topVendors = vendorList.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category != null
            ? '${widget.category!.name} Analytics'
            : 'Category Performance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  SizedBox(height: 24.h),
                  _buildRevenueChart(),
                  SizedBox(height: 24.h),
                  _buildTopVendorsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
            'Total Revenue',
            'Rs. ${_totalRevenue.toStringAsFixed(0)}',
            Icons.attach_money,
            Colors.green),
        _buildStatCard(
            'Total Orders', '$_totalOrders', Icons.shopping_bag, Colors.blue),
        _buildStatCard(
            'Active Vendors', '$_activeVendors', Icons.store, Colors.orange),
        _buildStatCard('Avg. Rating', _avgRating.toStringAsFixed(1), Icons.star,
            Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20.w),
                SizedBox(width: 8.w),
                Text(title,
                    style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
              ],
            ),
            SizedBox(height: 8.h),
            Text(value,
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Container(
        height: 200.h,
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue Trend (Last 7 Days)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Center(
                child: Text('Chart Visualization Placeholder',
                    style: TextStyle(color: Colors.grey[400]))),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVendorsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Performing Vendors',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 12.h),
        Card(
          child: Column(
            children: _topVendors.isEmpty
                ? [
                    Padding(
                      padding: EdgeInsets.all(16.0.w),
                      child: const Text('No vendor data available'),
                    )
                  ]
                : _topVendors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final vendor = entry.value;
                    final initial =
                        vendor['name'].toString().substring(0, 1).toUpperCase();

                    return Column(
                      children: [
                        if (index > 0) const Divider(height: 1),
                        ListTile(
                          leading: CircleAvatar(child: Text(initial)),
                          title: Text(vendor['name'].toString()),
                          subtitle: Text(
                              '${vendor['completionRate'].toStringAsFixed(1)}% completion rate'),
                          trailing: Text(
                              'Rs. ${(vendor['revenue'] as double).toStringAsFixed(0)}'),
                        ),
                      ],
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }
}
