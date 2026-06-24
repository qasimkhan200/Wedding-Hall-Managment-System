import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/delivery_calculation_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_widgets.dart';
import '../widgets/category_card.dart';
import '../widgets/vendor_card.dart';
import 'category_products_screen.dart';
import 'nearby_vendors_screen.dart';
import 'location_picker_screen.dart';
import '../../../core/services/geocoding_service.dart';

class HostHomeScreen extends StatefulWidget {
  const HostHomeScreen({super.key});

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().getCurrentLocation();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final categories = CategoryModel.getCategories(); // Removed mock data

    return Scaffold(
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          final categories =
              categoryProvider.categories.where((c) => c.isActive).toList();

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: ResponsiveUtils.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ResponsiveText(
                                    'Emergency Supplies',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall // Smaller title
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                  SizedBox(height: 4.h), // Tighter spacing
                                  Consumer<LocationProvider>(
                                    builder:
                                        (context, locationProvider, child) {
                                      String displayAddress =
                                          locationProvider.address ??
                                              'Set your location';

                                      return InkWell(
                                        onTap: () async {
                                          final dynamic result =
                                              await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const LocationPickerScreen(),
                                            ),
                                          );

                                          if (result is GeocodingResult &&
                                              context.mounted) {
                                            locationProvider.setLocation(
                                                latitude:
                                                    result.location.latitude,
                                                longitude:
                                                    result.location.longitude,
                                                address: result.displayName);
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16.sp, // Smaller icon
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 4.w),
                                            Expanded(
                                              child: ResponsiveText(
                                                displayAddress,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium // Smaller than titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                maxLines: 1,
                                              ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              color: AppColors.textSecondary,
                                              size: 16.sp,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Notification Button - slightly smaller
                            ResponsiveContainer(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: Text('🔔',
                                    style: TextStyle(fontSize: 20.sp)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: ResponsiveUtils
                                .mdHeight), // Reduced from lgHeight

                        // Search Bar - Professional & Visible
                        Container(
                          // Use Container instead of ResponsiveContainer for direct control
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                                fontSize: 14.sp, color: AppColors.textPrimary),
                            onSubmitted: (value) {
                              // ... existing logic ...
                              if (value.isNotEmpty) {
                                final allCategory = CategoryModel(
                                  id: 'all',
                                  name: 'All Products',
                                  icon: '🛍️',
                                  color: AppColors.primary,
                                  description: 'All available products',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  isActive: true,
                                  emergencyDeliveryMinutes: 0,
                                  pricing: PricingConfig(commissionPercent: 0),
                                  delivery: DeliveryConfig(),
                                  inventory: InventoryConfig(),
                                );

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoryProductsScreen(
                                      category: allCategory,
                                      initialSearchQuery: value,
                                    ),
                                  ),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Search for supplies...',
                              hintStyle: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.primary,
                                size: 22.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical:
                                    16.h, // Increased padding/touch target
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: ResponsiveUtils
                                .mdHeight), // Reduced from xlHeight

                        // Emergency Banner - Compact Redesign
                        ResponsiveContainer(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w), // Reduced padding
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ResponsiveText(
                                      'Emergency?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.sp, // Salesy font size
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Consumer<LocationProvider>(
                                      builder:
                                          (context, locationProvider, child) {
                                        String deliveryText =
                                            'Get supplies fast!';
                                        if (locationProvider.hasLocation) {
                                          deliveryText =
                                              'Delivered in ${DeliveryCalculationService.getDeliveryTimeRange(25)}!';
                                        }
                                        return ResponsiveText(
                                          deliveryText,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 12.sp, // Compact
                                          ),
                                          maxLines: 1,
                                        );
                                      },
                                    ),
                                    SizedBox(height: 12.h),
                                    InkWell(
                                      onTap: () {
                                        // ... existing category logic ...
                                        if (categories.isEmpty) return;
                                        final targetCategory =
                                            categories.firstWhere(
                                          (c) => c.name
                                              .toLowerCase()
                                              .contains('emergency'),
                                          orElse: () => categories.first,
                                        );
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CategoryProductsScreen(
                                                    category: targetCategory),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                        ),
                                        child: Text(
                                          'Order Now',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Text('🎊',
                                      style: TextStyle(
                                          fontSize:
                                              48.sp)), // Reduced emoji size
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.lgHeight),

                        // Category Header
                        ResponsiveText(
                          'Categories',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ), // Smaller header
                        ),
                      ],
                    ),
                  ),
                ),

                // Categories Grid
                if (categoryProvider.isLoading && categories.isEmpty)
                  const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()))
                else if (categories.isEmpty)
                  const SliverToBoxAdapter(
                      child: Center(child: Text('No categories')))
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            3, // FIX: Reduced to 3 columns to prevent overflow
                        mainAxisSpacing: 12.h,
                        crossAxisSpacing: 12.w,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = categories[index];
                          return CategoryCard(
                            category: category,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CategoryProductsScreen(
                                      category: category),
                                ),
                              );
                            },
                          );
                        },
                        childCount: categories.length,
                      ),
                    ),
                  ),

                // Vendors Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        16.w, 24.h, 16.w, 12.h), // Adjusted padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ResponsiveText(
                          'Nearby Vendors',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NearbyVendorsScreen(),
                              ),
                            );
                          },
                          // style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), // Optional compacting
                          child: Text(
                            'See All',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Vendor List
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  sliver: StreamBuilder<List<VendorModel>>(
                    stream: VendorService.getApprovedVendors(),
                    builder: (context, snapshot) {
                      // ... existing loading/error/empty logic ...
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                            child: Center(child: CircularProgressIndicator()));
                      }
                      if (snapshot.hasError) {
                        return const SliverToBoxAdapter(
                            child: Center(child: Text('Error')));
                      }
                      final vendors = snapshot.data ?? [];
                      if (vendors.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Column(
                              children: [
                                Text('🏪', style: TextStyle(fontSize: 40.sp)),
                                const Text('No vendors found'),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final vendor = vendors[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: 6
                                      .h), // FIX: Reduced spacing between cards
                              child: Consumer<LocationProvider>(
                                builder: (context, locationProvider, child) {
                                  // ... distance logic ...
                                  String distance = 'Unknown';
                                  String deliveryTime = '30-40 min';
                                  if (locationProvider.hasLocation &&
                                      vendor.latitude != 0 &&
                                      vendor.longitude != 0) {
                                    final distKm = DeliveryCalculationService
                                        .calculateDistance(
                                            lat1: locationProvider.latitude!,
                                            lon1: locationProvider.longitude!,
                                            lat2: vendor.latitude,
                                            lon2: vendor.longitude);
                                    distance = DeliveryCalculationService
                                        .formatDistance(distKm);
                                    // ... time calc ...
                                  }

                                  return VendorCard(
                                    name: vendor.businessName,
                                    category: vendor.categories.isNotEmpty
                                        ? vendor.categories.first
                                        : 'General',
                                    rating: vendor.rating,
                                    distance: distance,
                                    deliveryTime: deliveryTime,
                                    imageUrl: vendor.logoImage ?? '',
                                    onTap: () {},
                                  );
                                },
                              ),
                            );
                          },
                          childCount: vendors.length > 2 ? 2 : vendors.length,
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                    child: SizedBox(height: 24.h)), // Bottom Safe Area
              ],
            ),
          );
        },
      ),
    );
  }
}
