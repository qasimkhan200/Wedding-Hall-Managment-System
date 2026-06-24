import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/category_model.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/services/storage_service.dart';

class AdminAddEditCategoryScreen extends StatefulWidget {
  final CategoryModel? category;

  const AdminAddEditCategoryScreen({super.key, this.category});

  @override
  State<AdminAddEditCategoryScreen> createState() =>
      _AdminAddEditCategoryScreenState();
}

class _AdminAddEditCategoryScreenState extends State<AdminAddEditCategoryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Basic Info
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _iconController;
  CategoryType _selectedType = CategoryType.product;
  CategoryTier _selectedTier = CategoryTier.standard;
  Color _selectedColor = AppColors.primary;

  // Pricing
  late TextEditingController _commissionController;
  late TextEditingController _surchargeController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  // Rules (Delivery & Inventory)
  bool _requiresRefrigeration = false;
  bool _requiresHeavyLifting = false;
  late TextEditingController _maxDistanceController;
  late TextEditingController _emergencySlaController;
  bool _lowStockAlert = true;
  late TextEditingController _stockThresholdController;

  File? _selectedImage;
  String? _currentImageUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Init Basic Info
    _nameController = TextEditingController(text: widget.category?.name);
    _descriptionController =
        TextEditingController(text: widget.category?.description);
    _iconController =
        TextEditingController(text: widget.category?.icon ?? '📦');

    // Init Pricing
    _commissionController = TextEditingController(
        text: widget.category?.pricing.commissionPercent.toString() ?? '10.0');
    _surchargeController = TextEditingController(
        text: widget.category?.pricing.emergencySurchargePercent.toString() ??
            '0.0');
    _minPriceController = TextEditingController(
        text: widget.category?.pricing.minPrice?.toString() ?? '');
    _maxPriceController = TextEditingController(
        text: widget.category?.pricing.maxPrice?.toString() ?? '');

    // Init Rules
    if (widget.category != null) {
      _selectedType = widget.category!.type;
      _selectedTier = widget.category!.tier;
      _selectedColor = widget.category!.color;
      _requiresRefrigeration = widget.category!.delivery.requiresRefrigeration;
      _requiresHeavyLifting = widget.category!.delivery.requiresHeavyLifting;
      _lowStockAlert = widget.category!.inventory.lowStockAlertEnabled;
    }

    _maxDistanceController = TextEditingController(
        text:
            widget.category?.delivery.maxDeliveryDistanceKm?.toString() ?? '');
    _emergencySlaController = TextEditingController(
        text: widget.category?.emergencyDeliveryMinutes.toString() ?? '30');
    _stockThresholdController = TextEditingController(
        text: widget.category?.inventory.lowStockThreshold.toString() ?? '5');

    // Image URL
    _currentImageUrl = widget.category?.imageUrl;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _commissionController.dispose();
    _surchargeController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _maxDistanceController.dispose();
    _emergencySlaController.dispose();
    _stockThresholdController.dispose();
    for (var controller in _seasonalControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload image if selected
      String? imageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        imageUrl = await StorageService.uploadProductImageOnly(
          file: _selectedImage!,
          vendorId: 'categories', // Use 'categories' as folder name
        );
      }

      final seasonalMultipliers = <String, double>{};
      _seasonalControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          seasonalMultipliers[key] = double.tryParse(controller.text) ?? 1.0;
        }
      });

      final pricing = PricingConfig(
        commissionPercent: double.tryParse(_commissionController.text) ?? 10.0,
        emergencySurchargePercent:
            double.tryParse(_surchargeController.text) ?? 0.0,
        minPrice: double.tryParse(_minPriceController.text),
        maxPrice: double.tryParse(_maxPriceController.text),
        seasonalMultipliers: seasonalMultipliers,
      );

      final delivery = DeliveryConfig(
        requiresRefrigeration: _requiresRefrigeration,
        requiresHeavyLifting: _requiresHeavyLifting,
        maxDeliveryDistanceKm: double.tryParse(_maxDistanceController.text),
      );

      final inventory = InventoryConfig(
        lowStockAlertEnabled: _lowStockAlert,
        lowStockThreshold: int.tryParse(_stockThresholdController.text) ?? 5,
      );

      final category = CategoryModel(
        id: widget.category?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        icon: _iconController.text.trim(),
        imageUrl: imageUrl,
        color: _selectedColor,
        type: _selectedType,
        tier: _selectedTier,
        pricing: pricing,
        delivery: delivery,
        inventory: inventory,
        emergencyDeliveryMinutes:
            int.tryParse(_emergencySlaController.text) ?? 30,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<CategoryProvider>();
      bool success;

      if (widget.category != null) {
        success = await provider.updateCategory(category);
      } else {
        success = await provider.createCategory(category);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.category != null
                ? 'Category updated'
                : 'Category created'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category != null ? 'Edit Category' : 'Add Category',
            style: TextStyle(color: AppColors.primary)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic'),
            Tab(text: 'Pricing'),
            Tab(text: 'Rules'),
            Tab(text: 'Seasonal'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveCategory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildPricingTab(),
                  _buildRulesTab(),
                  _buildSeasonalTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoTab() {
    return StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Category Name', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            SizedBox(height: 24.h),

            // Image Picker Section
            Text('Category Image',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            SizedBox(height: 12.h),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final ImageSource? source = await showDialog<ImageSource>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Select Image Source'),
                      actions: [
                        TextButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          onPressed: () =>
                              Navigator.pop(context, ImageSource.gallery),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                          onPressed: () =>
                              Navigator.pop(context, ImageSource.camera),
                        ),
                      ],
                    ),
                  );

                  if (source != null) {
                    final XFile? image = await picker.pickImage(source: source);
                    if (image != null) {
                      setState(() {
                        _selectedImage = File(image.path);
                      });
                    }
                  }
                },
                child: Container(
                  width: 150.w,
                  height: 150.w,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.border,
                      width: 2.w,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _currentImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.network(
                                _currentImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(Icons.category, size: 50.w),
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 50.w,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Add Category Image',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            SizedBox(height: 24.h),

            SizedBox(height: 24.h),
            const Text('Category Type',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.w,
              children: CategoryType.values.map((type) {
                return FilterChip(
                  label: Text(type.displayName),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 24.h),
            const Text('Category Tier',
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<CategoryTier>(
              value: _selectedTier,
              items: CategoryTier.values.map((tier) {
                return DropdownMenuItem(
                  value: tier,
                  child: Row(
                    children: [
                      Icon(tier.icon, color: tier.color, size: 20.w),
                      SizedBox(width: 8.w),
                      Text(tier.displayName)
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedTier = val!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionHeader('Revenue Configuration'),
          TextFormField(
            controller: _commissionController,
            decoration: const InputDecoration(
                labelText: 'Commission %',
                border: OutlineInputBorder(),
                suffixText: '%'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _surchargeController,
            decoration: const InputDecoration(
                labelText: 'Emergency Surcharge %',
                border: OutlineInputBorder(),
                suffixText: '%',
                helperText: 'Extra fee for emergency orders in this category'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 24.h),
          _buildSectionHeader('Price Limits'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minPriceController,
                  decoration: const InputDecoration(
                      labelText: 'Min Price',
                      border: OutlineInputBorder(),
                      prefixText: '\$'),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextFormField(
                  controller: _maxPriceController,
                  decoration: const InputDecoration(
                      labelText: 'Max Price',
                      border: OutlineInputBorder(),
                      prefixText: '\$'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionHeader('Delivery Constraints'),
          SwitchListTile(
            title: const Text('Requires Refrigeration'),
            subtitle: const Text('Items need cold storage during transit'),
            value: _requiresRefrigeration,
            onChanged: (v) => setState(() => _requiresRefrigeration = v),
          ),
          SwitchListTile(
            title: const Text('Requires Heavy Lifting'),
            subtitle: const Text('Needs vehicle with lift or multiple staff'),
            value: _requiresHeavyLifting,
            onChanged: (v) => setState(() => _requiresHeavyLifting = v),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _maxDistanceController,
            decoration: const InputDecoration(
                labelText: 'Max Delivery Radius (km)',
                border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 24.h),
          _buildSectionHeader('Emergency SLA'),
          TextFormField(
            controller: _emergencySlaController,
            decoration: const InputDecoration(
                labelText: 'Guaranteed Delivery Time (mins)',
                border: OutlineInputBorder(),
                helperText: 'Default SLA for emergency orders'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 24.h),
          _buildSectionHeader('Inventory Rules'),
          SwitchListTile(
            title: const Text('Low Stock Alerts'),
            value: _lowStockAlert,
            onChanged: (v) => setState(() => _lowStockAlert = v),
          ),
          TextFormField(
            controller: _stockThresholdController,
            decoration: const InputDecoration(
                labelText: 'Low Stock Threshold', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            enabled: _lowStockAlert,
          ),
        ],
      ),
    );
  }

  // Seasonal Tab
  final Map<String, TextEditingController> _seasonalControllers = {};

  Widget _buildSeasonalTab() {
    // Initialize controllers if empty
    if (_seasonalControllers.isEmpty) {
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      final existing = widget.category?.pricing.seasonalMultipliers ?? {};
      for (var month in months) {
        _seasonalControllers[month] =
            TextEditingController(text: existing[month]?.toString() ?? '1.0');
      }
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildSectionHeader('Seasonal Demand Multipliers'),
        Text('Adjust base prices for peak wedding seasons.',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        SizedBox(height: 16.h),
        ..._seasonalControllers.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: entry.value,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'x',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
      ),
    );
  }
}
