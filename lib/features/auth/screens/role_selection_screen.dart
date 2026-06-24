import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_widgets.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Removed top spacer for tighter layout
              Center(
                child: ResponsiveText(
                  '🎊',
                  style: TextStyle(fontSize: 48.sp), // Reduced size slightly
                ),
              ),
              SizedBox(height: ResponsiveUtils.smHeight), // Reduced from md
              ResponsiveText(
                "Let's Organize It",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      // Reduced from Large
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              ResponsiveText(
                'Select your role to continue',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              SizedBox(height: ResponsiveUtils.mdHeight), // Reduced from lg
              _RoleCard(
                icon: '👰',
                title: 'Host',
                subtitle: 'Order emergency supplies for your wedding',
                color: AppColors.primary,
                onTap: () => _navigateToLogin(context, AppConstants.roleHost),
              ),
              SizedBox(height: ResponsiveUtils.smHeight), // Reduced from md
              _RoleCard(
                icon: '🏪',
                title: 'Vendor',
                subtitle: 'Manage inventory and fulfill orders',
                color: AppColors.secondary,
                onTap: () => _navigateToLogin(context, AppConstants.roleVendor),
              ),
              SizedBox(height: ResponsiveUtils.smHeight), // Reduced from md
              _RoleCard(
                icon: '🛵',
                title: 'Rider',
                subtitle: 'Deliver orders and earn money',
                color: AppColors.accent,
                onTap: () => _navigateToLogin(context, AppConstants.roleRider),
              ),
              SizedBox(height: ResponsiveUtils.smHeight), // Reduced from md
              // Admin role - temporarily visible for testing
              _RoleCard(
                icon: '👨‍💼',
                title: 'Admin',
                subtitle: 'Manage platform and approvals',
                color: AppColors.info,
                onTap: () => _navigateToLogin(context, AppConstants.roleAdmin),
              ),
              SizedBox(height: ResponsiveUtils.lgHeight),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleBasedLoginScreen(role: role),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      margin: EdgeInsets.zero, // Remove default margin for tighter control
      color: Colors.white,
      child: Row(
        children: [
          ResponsiveContainer(
            width: ResponsiveUtils.iconXl + ResponsiveUtils.lg,
            height: ResponsiveUtils.iconXl + ResponsiveUtils.lg,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMd),
            ),
            child: Center(
              child: ResponsiveText(
                icon,
                style: TextStyle(fontSize: ResponsiveUtils.headline4),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
                SizedBox(height: ResponsiveUtils.xsHeight),
                ResponsiveText(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: ResponsiveUtils.iconSm,
            color: color,
          ),
        ],
      ),
    );
  }
}
