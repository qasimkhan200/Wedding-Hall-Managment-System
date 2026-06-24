import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/order_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../widgets/cart_item_widget.dart';
import 'location_picker_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/commercial_rates_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/models/category_model.dart';
import 'category_products_screen.dart';
import '../../../core/services/geocoding_service.dart';

class HostCartScreen extends StatelessWidget {
  const HostCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(color: AppColors.primary),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.isEmpty) return const SizedBox();
              return TextButton(
                onPressed: () {
                  _showClearCartDialog(context, cart);
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.error),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🛒', style: TextStyle(fontSize: 60.sp)),
                  SizedBox(height: 16.h),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Add items to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () {
                      // Create a dummy 'All' category to browse all products
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

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryProductsScreen(
                            category: allCategory,
                          ),
                        ),
                      );
                    },
                    child: const Text('Browse Categories'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (cart.selectedVendorName != null)
                Container(
                  padding: EdgeInsets.all(12.w),
                  color: AppColors.primaryLight.withOpacity(0.3),
                  child: Row(
                    children: [
                      Icon(Icons.store, color: AppColors.primary, size: 20.w),
                      SizedBox(width: 8.w),
                      Text(
                        'Ordering from: ${cart.selectedVendorName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    return CartItemWidget(item: cart.items[index]);
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Rs. ${cart.subtotal.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Fee',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Calculated at checkout',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          'Rs. ${cart.totalAmount.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleCheckout(context),
                        child: const Text('Proceed to Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            child:
                const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const CheckoutBottomSheet(),
      ),
    );
  }
}

class CheckoutBottomSheet extends StatefulWidget {
  const CheckoutBottomSheet({super.key});

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  final CommercialRatesService _ratesService = CommercialRatesService();

  bool _isLoading = true;
  String _vehicleType = 'bike';
  String _vendorTier = 'free';
  double _distance = 0.0;
  bool _isPlacingOrder = false;
  FeeBreakdown? _breakdown;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final cart = context.read<CartProvider>();
    final location = context.read<LocationProvider>();

    // Default vehicle based on categories
    _vehicleType = 'bike';

    if (cart.selectedVendorId != null) {
      try {
        // Vendor profiles are stored in 'users' collection with role='vendor'
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cart.selectedVendorId)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            _vendorTier = data['subscriptionTier'] ?? 'free';
            final categories = List<String>.from(data['categories'] ?? []);
            // Initial guess, but allow user to change
            _vehicleType = OrderService.determineRequiredVehicle(categories);

            // Access latitude/longitude as double/number or from a nested field if needed
            // VendorService maps them from top-level fields
            var vLat = (data['latitude'] ?? 0.0).toDouble();
            var vLng = (data['longitude'] ?? 0.0).toDouble();

            // FALLBACK: If vendor has no location (0,0), use a default location (e.g. Peshawar)
            // This ensures distance calculation works for testing even with incomplete vendor profiles.
            if (vLat == 0 && vLng == 0) {
              vLat = 34.0151; // Peshawar
              vLng = 71.5249;
            }

            final userLat = location.latitude ?? 0.0;
            final userLng = location.longitude ?? 0.0;

            _distance =
                OrderService.calculateDistance(vLat, vLng, userLat, userLng);
          }
        }
      } catch (e) {
        print('Error fetching vendor for quote: $e');
      }
    }

    await _ratesService.getRates(forceRefresh: true);
    _calculateFees();
  }

  void _calculateFees() {
    if (!mounted) return;
    final cart = context.read<CartProvider>();

    setState(() {
      _breakdown = _ratesService.calculateOrderFees(
        subtotal: cart.subtotal,
        baseDeliveryFee: cart.deliveryFee,
        isEmergency: false,
        vendorTier: _vendorTier,
        vehicleType: _vehicleType,
        distanceKm: _distance,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300.h,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    final cart = context.watch<CartProvider>();
    final location = context.watch<LocationProvider>();
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confirm Order',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.sp,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          SizedBox(height: 16.h),

          // Vehicle Selector
          Text('Select Vehicle',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildVehicleOption('bike', Icons.two_wheeler, 'Bike'),
              SizedBox(width: 12.w),
              _buildVehicleOption('car', Icons.directions_car, 'Car'),
              SizedBox(width: 12.w),
              _buildVehicleOption('van', Icons.local_shipping, 'Van'),
            ],
          ),
          SizedBox(height: 16.h),

          // Distance Info
          Row(
            children: [
              const Icon(Icons.route, size: 16, color: Colors.grey),
              SizedBox(width: 8.w),
              Text(
                'Est. Distance: ${_distance.toStringAsFixed(1)} km',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Price Breakdown
          if (_breakdown != null && _breakdown!.appliedMultipliers.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price Adjustments:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                          fontSize: 12.sp)),
                  ..._breakdown!.appliedMultipliers.map(
                      (m) => Text('• $m', style: TextStyle(fontSize: 12.sp))),
                ],
              ),
            ),

          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      location.address ?? 'Set your address',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  final dynamic result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LocationPickerScreen(),
                    ),
                  );

                  if (result is GeocodingResult && mounted) {
                    location.setLocation(
                      latitude: result.location.latitude,
                      longitude: result.location.longitude,
                      address: result.displayName,
                    );
                    // Rerun calculation as distance might change
                    _initializeData();
                  }
                },
                child: const Text('Change'),
              ),
            ],
          ),
          const Divider(height: 32),

          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Added Delivery Fee Display
                    Text(
                      'Delivery Fee: Rs. ${(_breakdown?.deliveryFee ?? 0).toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 12.sp, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    if (_breakdown != null &&
                        _breakdown!.totalAmount != cart.totalAmount)
                      Text(
                        '(incl. vehicle/distance)',
                        style: TextStyle(
                            fontSize: 10.sp, color: AppColors.textSecondary),
                      )
                  ],
                ),
                Text(
                  'Rs. ${(_breakdown?.totalAmount ?? cart.totalAmount).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_breakdown == null || _isPlacingOrder)
                  ? null
                  : () async {
                      print('DEBUG: Place Order button pressed');
                      setState(() {
                        _isPlacingOrder = true;
                      });

                      try {
                        print('DEBUG: Calling OrderProvider.createOrder');
                        final order = await orderProvider.createOrder(
                          hostId: auth.user?.id ?? '',
                          hostName: auth.user?.name ?? 'Guest',
                          hostPhone: auth.user?.phone ?? '',
                          vendorId: cart.selectedVendorId ?? '',
                          vendorName: cart.selectedVendorName ?? '',
                          items: cart.items,
                          subtotal: cart.subtotal,
                          deliveryFee: cart.deliveryFee,
                          deliveryAddress: location.address ?? '',
                          deliveryLatitude: location.latitude ?? 0,
                          deliveryLongitude: location.longitude ?? 0,
                          requiredVehicle: _vehicleType, // PASSING VEHICLE TYPE
                          estimatedDistanceKm: _distance,
                        );
                        print('DEBUG: OrderProvider returned: $order');

                        if (mounted) {
                          setState(() {
                            _isPlacingOrder = false;
                          });

                          if (order != null) {
                            print(
                                'DEBUG: Order success. Clearing cart and closing.');
                            cart.clearCart();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order placed successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            print(
                                'DEBUG: Order returned null. Error: ${orderProvider.error}');
                            // Show error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(orderProvider.error ??
                                    'Failed to place order'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      } catch (e, stack) {
                        print('DEBUG: Exception in Place Order button: $e');
                        print('DEBUG: Stack trace: $stack');
                        if (mounted) {
                          setState(() {
                            _isPlacingOrder = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: _isPlacingOrder
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Place Order'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOption(String type, IconData icon, String label) {
    bool isSelected = _vehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _vehicleType = type;
          });
          _calculateFees();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? AppColors.primary : Colors.grey,
                  size: 24.w),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
