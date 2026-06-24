import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../../core/models/order_model.dart';
import '../../../../../core/theme/app_colors.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: Text('Order #${widget.order.id}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Items'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildItemsTab(),
          _buildTimelineTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final order = widget.order;
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Status'),
          _buildStatusCard(order),
          SizedBox(height: 24.h),

          _buildSectionHeader('Entities'),
          _buildEntityTile(
              Icons.person, 'Host', order.hostName, order.hostPhone),
          _buildEntityTile(Icons.store, 'Vendor', order.vendorName,
              ''), // Add phone if available
          if (order.riderName != null)
            _buildEntityTile(
                Icons.directions_bike, 'Rider', order.riderName!, ''),

          SizedBox(height: 24.h),
          _buildSectionHeader('Financials'),
          _buildFinancialRow('Subtotal', order.subtotal),
          _buildFinancialRow('Delivery Fee', order.deliveryFee),
          if (order.isEmergency)
            _buildFinancialRow('Emergency Fee',
                500.0), // Mock logic for display if fee separated
          const Divider(),
          _buildFinancialRow('Total', order.totalAmount, isBold: true),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: widget.order.items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = widget.order.items[index];
        return ListTile(
          title: Text(item.productName), // CartItemModel uses productName
          subtitle: Text('Qty: ${item.quantity}'),
          trailing:
              Text('Rs ${(item.price * item.quantity).toStringAsFixed(0)}'),
        );
      },
    );
  }

  Widget _buildTimelineTab() {
    // Basic timeline using existing timestamp fields
    final events = <Map<String, dynamic>>[];

    events.add({'title': 'Created', 'time': widget.order.createdAt});
    if (widget.order.acceptedAt != null) {
      events.add(
          {'title': 'Accepted by Vendor', 'time': widget.order.acceptedAt});
    }
    if (widget.order.pickedUpAt != null) {
      events.add({'title': 'Picked Up', 'time': widget.order.pickedUpAt});
    }
    if (widget.order.deliveredAt != null) {
      events.add({'title': 'Delivered', 'time': widget.order.deliveredAt});
    }

    // Sort logic here if needed, but usually strictly ordered by nature

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          leading: Icon(Icons.circle, size: 12.w, color: AppColors.primary),
          title: Text(event['title']),
          subtitle: Text(DateFormat('hh:mm a, dd MMM').format(event['time'])),
          // visual timeline connector line logic omitted for brevity
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildStatusCard(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Text(
            order.status.toUpperCase(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          if (order.isEmergency)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, color: Colors.red, size: 16.w),
                  Text(
                    ' EMERGENCY ORDER',
                    style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntityTile(
      IconData icon, String label, String name, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Icon(icon, color: Colors.grey.shade700, size: 20.w),
      ),
      title: Text(name),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : Text(label),
    );
  }

  Widget _buildFinancialRow(String label, double amount,
      {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('Rs ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
