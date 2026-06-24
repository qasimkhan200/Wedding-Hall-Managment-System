import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/delivery_calculation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../widgets/vendor_card.dart';

class NearbyVendorsScreen extends StatelessWidget {
  const NearbyVendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Vendors',
            style: TextStyle(color: AppColors.primary)),
      ),
      body: StreamBuilder<List<VendorModel>>(
        stream: VendorService.getApprovedVendors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading vendors'));
          }

          final vendors = snapshot.data ?? [];

          if (vendors.isEmpty) {
            return Center(
              child: Padding(
                padding: ResponsiveUtils.paddingLg,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🏪', style: TextStyle(fontSize: 60.sp)),
                    SizedBox(height: ResponsiveUtils.mdHeight),
                    const Text('No vendors available yet'),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: ResponsiveUtils.paddingMd,
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return Padding(
                padding: EdgeInsets.only(bottom: ResponsiveUtils.mdHeight),
                child: Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    // Calculate dynamic distance and delivery time
                    String distance = 'Unknown';
                    String deliveryTime = '30-40 min';

                    if (locationProvider.hasLocation &&
                        vendor.latitude != 0 &&
                        vendor.longitude != 0) {
                      final distanceKm =
                          DeliveryCalculationService.calculateDistance(
                        lat1: locationProvider.latitude!,
                        lon1: locationProvider.longitude!,
                        lat2: vendor.latitude,
                        lon2: vendor.longitude,
                      );

                      distance =
                          DeliveryCalculationService.formatDistance(distanceKm);

                      final estimatedMinutes =
                          DeliveryCalculationService.calculateDeliveryTime(
                        distanceKm: distanceKm,
                        vehicleType: 'bike',
                      );

                      deliveryTime =
                          DeliveryCalculationService.getDeliveryTimeRange(
                              estimatedMinutes);
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
          );
        },
      ),
    );
  }
}
