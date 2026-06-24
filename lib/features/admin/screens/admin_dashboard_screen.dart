import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import 'admin_approvals_screen.dart';
import 'admin_analytics_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_rates_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(
              color: AppColors.primary,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16.h),
            _buildStatsGrid(),
            SizedBox(height: 24.h),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 16.h),
            _buildQuickActions(),
            SizedBox(height: 24.h),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 16.h),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard(
            'Total Users', _buildUserCount(), Icons.people, AppColors.primary),
        _buildStatCard('Active Orders', _buildOrderCount(), Icons.shopping_cart,
            AppColors.secondary),
        _buildStatCard('Pending Approvals', _buildPendingCount(),
            Icons.pending_actions, AppColors.warning),
        _buildStatCard(
            'Total Revenue',
            Text('Rs 45,230',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            Icons.attach_money,
            AppColors.success),
      ],
    );
  }

  Widget _buildStatCard(
      String title, Widget value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(icon, color: color, size: 16.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                value,
                SizedBox(height: 2.h),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.sp,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCount() {
    if (!FirebaseService.isInitialized) {
      return Text('42',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.users.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('--',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
        }
        return Text(
          '${snapshot.data!.docs.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Widget _buildOrderCount() {
    if (!FirebaseService.isInitialized) {
      return Text('8',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.orders.where('status',
          whereIn: ['pending', 'accepted', 'preparing', 'picked']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('--',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
        }
        return Text(
          '${snapshot.data!.docs.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Widget _buildPendingCount() {
    if (!FirebaseService.isInitialized) {
      return Text('4',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.users
          .where('isApproved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('--',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
        }
        return Text(
          '${snapshot.data!.docs.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: 2,
      children: [
        _buildActionCard('Pending Approvals', Icons.approval, () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminApprovalsScreen()),
          );
        }),
        _buildActionCard('View All Orders', Icons.list_alt, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminOrdersScreen()),
          );
        }),
        _buildActionCard('User Management', Icons.manage_accounts, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
          );
        }),
        _buildActionCard('Reports', Icons.analytics, () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminAnalyticsScreen()),
          );
        }),
        _buildActionCard('Rates Config', Icons.currency_exchange, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminRatesScreen()),
          );
        }),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16.w, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (!FirebaseService.isInitialized) {
      return Column(
        children: [
          _buildActivityItem(
              'New order from John Wedding', 'Rs 2,500', '2 hours ago'),
          _buildActivityItem(
              'New order from Mary Function', 'Rs 1,800', '4 hours ago'),
          _buildActivityItem(
              'New order from Alex Event', 'Rs 3,200', '6 hours ago'),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.orders
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return const Text('No recent activity');
        }

        return Column(
          children: orders.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildActivityItem(
              'New order from ${data['hostName'] ?? 'Unknown'}',
              'Rs ${data['totalAmount'] ?? 0}',
              _getTimeAgo(
                  DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0)),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivityItem(String title, String amount, String time) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child:
                Icon(Icons.shopping_cart, color: AppColors.primary, size: 20.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
