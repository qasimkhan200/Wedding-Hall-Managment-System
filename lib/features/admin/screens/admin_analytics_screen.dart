import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/firebase_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _selectedPeriod = 'All Time';
  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'All Time'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics & Reports',
            style: TextStyle(color: AppColors.primary)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            SizedBox(height: 24.h),
            _buildAnalyticsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                }
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    // Determine query based on period
    Query query = FirebaseService.orders.where('status', whereIn: [
      'completed',
      'delivered',
      'accepted',
      'picked'
    ]); // Include active orders? Usually revenue is realized on completion. Let's include all non-cancelled.

    // Ideally filter by createdAt range here, but for MVP client-side filtering might be easier if detailed.

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        final filteredDocs = _filterDocsByPeriod(allDocs);

        if (filteredDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.0.w),
              child: const Text('No data for this period'),
            ),
          );
        }

        return _calculateAndShowStats(filteredDocs);
      },
    );
  }

  List<DocumentSnapshot> _filterDocsByPeriod(List<DocumentSnapshot> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt =
          DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0);

      switch (_selectedPeriod) {
        case 'Today':
          return createdAt.isAfter(today);
        case 'This Week':
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          return createdAt.isAfter(weekStart);
        case 'This Month':
          final monthStart = DateTime(now.year, now.month, 1);
          return createdAt.isAfter(monthStart);
        case 'All Time':
        default:
          return true;
      }
    }).toList();
  }

  Widget _calculateAndShowStats(List<DocumentSnapshot> docs) {
    double totalRevenue = 0;
    double platformEarnings = 0; // Commission + PlatformFee
    double riderPayouts = 0;
    double vendorEarnings = 0;
    int orderCount = docs.length;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final total = (data['totalAmount'] as num?)?.toDouble() ?? 0;
      final commission = (data['commissionAmount'] as num?)?.toDouble() ?? 0;
      final pFee = (data['platformFee'] as num?)?.toDouble() ?? 0;
      final rFee = (data['riderFee'] as num?)?.toDouble() ?? 0;
      final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0;

      totalRevenue += total;
      platformEarnings += (commission + pFee);
      riderPayouts += rFee;
      // Vendor Net is roughly Subtotal - Commission.
      // Note: totalAmount usually includes deliveryFee. subtotal is items only.
      // Simplification: Vendor Net = Subtotal - Commission.
      vendorEarnings += (subtotal - commission);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildSummaryCard('Total Orders', '$orderCount',
                    Icons.shopping_bag, AppColors.secondary)),
            SizedBox(width: 16.w),
            Expanded(
                child: _buildSummaryCard(
                    'Gross Volume',
                    'Rs. ${totalRevenue.toStringAsFixed(0)}',
                    Icons.payments,
                    AppColors.primary)),
          ],
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Financial Breakdown',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildBreakdownRow(
                  'Platform Earnings', platformEarnings, AppColors.success,
                  isTotal: true),
              Divider(height: 32.h),
              _buildBreakdownRow(
                  'Vendor Payouts', vendorEarnings, AppColors.textPrimary),
              SizedBox(height: 12.h),
              _buildBreakdownRow(
                  'Rider Payouts', riderPayouts, AppColors.textPrimary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          SizedBox(height: 12.h),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.black : AppColors.textSecondary,
              fontSize: (isTotal ? 16 : 14).sp,
            )),
        Text('Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: (isTotal ? 18 : 14).sp,
            )),
      ],
    );
  }
}
