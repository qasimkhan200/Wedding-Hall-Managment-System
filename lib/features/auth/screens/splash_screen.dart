import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_widgets.dart';
import 'role_selection_screen.dart';
import '../../host/screens/host_main_screen.dart';
import '../../vendor/screens/vendor_main_screen.dart';
import '../../rider/screens/rider_main_screen.dart';
import '../../admin/screens/admin_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Check if user is already logged in
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is logged in via SharedPreferences
    if (PreferencesService.isLoggedIn) {
      final role = PreferencesService.userRole;

      // Load user data from Firebase
      final authProvider = context.read<AuthProvider>();
      await authProvider.loadUserData();

      if (mounted && authProvider.isAuthenticated) {
        // Navigate to appropriate dashboard based on role
        _navigateToHome(role ?? AppConstants.roleHost);
        return;
      }
    }

    // Not logged in, go to role selection
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  void _navigateToHome(String role) {
    Widget screen;
    switch (role) {
      case AppConstants.roleHost:
        screen = const HostMainScreen();
        break;
      case AppConstants.roleVendor:
        screen = const VendorMainScreen();
        break;
      case AppConstants.roleRider:
        screen = const RiderMainScreen();
        break;
      case AppConstants.roleAdmin:
        screen = const AdminMainScreen();
        break;
      default:
        screen = const RoleSelectionScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ResponsiveContainer(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(ResponsiveUtils.radiusXl),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20.r,
                                offset: Offset(0, 10.h),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '🎊',
                              style: TextStyle(fontSize: 60.sp),
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.xlHeight),
                        ResponsiveText(
                          "Let's Organize It",
                          style: TextStyle(
                            fontSize: ResponsiveUtils.headline2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.smHeight),
                        ResponsiveText(
                          'Emergency Wedding Supplies',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.body1,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.xsHeight),
                        ResponsiveText(
                          'Delivered Fast!',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.body2,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.xxlHeight),
                        SizedBox(
                          width: ResponsiveUtils.iconXl,
                          height: ResponsiveUtils.iconXl,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                            strokeWidth: 3.w,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
