import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/screens/role_selection_screen.dart';
import 'admin_categories_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'admin_rates_screen.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/cart_provider.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Settings',
              style: TextStyle(
                color: AppColors.primary,
              ))),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildSection(context, 'Platform Settings', [
            _buildTile(
              context,
              Icons.list_alt,
              'Orders',
              'Manage all orders',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
              ),
            ),
            _buildTile(
              context,
              Icons.category,
              'Categories',
              'Manage product categories',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminCategoriesScreen()),
              ),
            ),
          ]),
          SizedBox(height: 16.h),
          _buildSection(context, 'Financial', [
            _buildTile(
              context,
              Icons.attach_money,
              'Commission Rates',
              'Vendor and rider fees',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminRatesScreen()),
              ),
            ),
            _buildTile(context, Icons.account_balance, 'Payouts',
                'Payment processing'),
          ]),
          SizedBox(height: 16.h),
          _buildSection(context, 'Support', [
            _buildTile(context, Icons.help, 'Help Center', 'FAQs and support'),
            _buildTile(context, Icons.info, 'About', 'App information'),
          ]),
          SizedBox(height: 24.h),
          Consumer<AuthProvider>(
            builder: (context, auth, child) => OutlinedButton(
              onPressed: () {
                context.read<OrderProvider>().clearData();
                context.read<LocationProvider>().clearData();
                context.read<CartProvider>().clearCart();
                auth.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen()),
                    (route) => false);
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error)),
              child: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, IconData icon, String title, String subtitle,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.info, size: 24.w),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp)),
      trailing:
          Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 24.w),
      onTap: onTap,
    );
  }
}
