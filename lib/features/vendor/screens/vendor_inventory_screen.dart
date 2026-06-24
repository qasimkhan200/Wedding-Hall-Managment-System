import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/item_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/storage_service.dart';

class VendorInventoryScreen extends StatefulWidget {
  const VendorInventoryScreen({super.key});

  @override
  State<VendorInventoryScreen> createState() => _VendorInventoryScreenState();
}

class _VendorInventoryScreenState extends State<VendorInventoryScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy =
      'none'; // none, price_asc, price_desc, stock_asc, stock_desc, name_asc
  String _availabilityFilter = 'all'; // all, available, unavailable
  bool _lowStockOnly = false;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'All',
    'Chairs & Tables',
    'Crockery & Utensils',
    'Ice & Beverages',
    'Decor Items',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    final gridColumns = isLargeScreen ? 3 : (isTablet ? 2 : 1);
    final maxContentWidth = isLargeScreen ? 1200.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Inventory',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isTablet ? 24.sp : 22.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: isTablet,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              color: _showSearch ? AppColors.primary : AppColors.textPrimary,
              size: isTablet ? 26.sp : 24.sp,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                // Inline Search Bar
                if (_showSearch)
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'Search by product name...',
                        hintStyle: TextStyle(
                            fontSize: 13.sp, color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppColors.primary, size: 20.sp),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded,
                                    size: 18.sp,
                                    color: AppColors.textSecondary),
                                onPressed: () => setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    ),
                  ),
                _buildCategoryFilter(isTablet: isTablet),
                Expanded(
                  child: vendorId.isEmpty
                      ? _buildEmptyState('Please log in', isTablet: isTablet)
                      : StreamBuilder<List<ItemModel>>(
                          stream: VendorService.getItemsByVendor(vendorId,
                              includeInactive: true),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ));
                            }

                            if (snapshot.hasError) {
                              return _buildErrorState(snapshot.error.toString(),
                                  isTablet: isTablet);
                            }

                            final items = snapshot.data ?? [];

                            if (items.isEmpty) {
                              return _buildEmptyInventory(
                                vendorId: vendorId,
                                isTablet: isTablet,
                              );
                            }

                            final filteredItems = _filterItems(items);

                            if (filteredItems.isEmpty) {
                              return _buildNoResults(isTablet: isTablet);
                            }

                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildInventoryGrid(
                                items: filteredItems,
                                gridColumns: gridColumns,
                                isTablet: isTablet,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(vendorId, isTablet: isTablet),
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Product',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter({required bool isTablet}) {
    final hasActiveFilters =
        _sortBy != 'none' || _availabilityFilter != 'all' || _lowStockOnly;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          // Category Selector (tappable dropdown-style)
          Expanded(
            child: GestureDetector(
              onTap: () => _showCategoryPickerSheet(isTablet: isTablet),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
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
                    Icon(
                      _getCategoryIcon(_selectedCategory),
                      size: 20.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _selectedCategory,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20.sp,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Filter Button
          GestureDetector(
            onTap: () => _showFilterSheet(isTablet: isTablet),
            child: Container(
              padding: EdgeInsets.all(13.w),
              decoration: BoxDecoration(
                color: hasActiveFilters ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: hasActiveFilters
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 22.sp,
                    color:
                        hasActiveFilters ? Colors.white : AppColors.textPrimary,
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: -5.h,
                      right: -5.w,
                      child: Container(
                        width: 15.w,
                        height: 15.w,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5.w),
                        ),
                        child: Center(
                          child: Text(
                            '${(_sortBy != 'none' ? 1 : 0) + (_availabilityFilter != 'all' ? 1 : 0) + (_lowStockOnly ? 1 : 0)}',
                            style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPickerSheet({required bool isTablet}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            // Header
            Row(
              children: [
                Icon(Icons.category_rounded,
                    color: AppColors.primary, size: 22.sp),
                SizedBox(width: 10.w),
                Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // Category Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 1.1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 2.w,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 26.sp,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          category,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet({required bool isTablet}) {
    String tempSort = _sortBy;
    String tempAvailability = _availabilityFilter;
    bool tempLowStock = _lowStockOnly;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 8.w, 0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.tune_rounded,
                          color: AppColors.primary, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Filter & Sort',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setModalState(() {
                        tempSort = 'none';
                        tempAvailability = 'all';
                        tempLowStock = false;
                      }),
                      icon: Icon(Icons.refresh_rounded,
                          size: 16.sp, color: AppColors.error),
                      label: Text(
                        'Reset',
                        style:
                            TextStyle(color: AppColors.error, fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 20.h, color: Colors.grey.shade100),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── SORT BY ──────────────────────────────
                      _sectionHeader(
                          icon: Icons.sort_rounded,
                          label: 'Sort By',
                          color: AppColors.primary),
                      SizedBox(height: 12.h),
                      // Sort options as 2-column grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        children: [
                          _sortTile(
                            label: 'Default',
                            icon: Icons.sort_rounded,
                            selected: tempSort == 'none',
                            onTap: () => setModalState(() => tempSort = 'none'),
                          ),
                          _sortTile(
                            label: 'Name A–Z',
                            icon: Icons.sort_by_alpha_rounded,
                            selected: tempSort == 'name_asc',
                            onTap: () =>
                                setModalState(() => tempSort = 'name_asc'),
                          ),
                          _sortTile(
                            label: 'Price: Low–High',
                            icon: Icons.arrow_upward_rounded,
                            selected: tempSort == 'price_asc',
                            onTap: () =>
                                setModalState(() => tempSort = 'price_asc'),
                          ),
                          _sortTile(
                            label: 'Price: High–Low',
                            icon: Icons.arrow_downward_rounded,
                            selected: tempSort == 'price_desc',
                            onTap: () =>
                                setModalState(() => tempSort = 'price_desc'),
                          ),
                          _sortTile(
                            label: 'Stock: Low–High',
                            icon: Icons.inventory_2_rounded,
                            selected: tempSort == 'stock_asc',
                            onTap: () =>
                                setModalState(() => tempSort = 'stock_asc'),
                          ),
                          _sortTile(
                            label: 'Stock: High–Low',
                            icon: Icons.inventory_2_rounded,
                            selected: tempSort == 'stock_desc',
                            onTap: () =>
                                setModalState(() => tempSort = 'stock_desc'),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),
                      Divider(color: Colors.grey.shade100),
                      SizedBox(height: 16.h),

                      // ── AVAILABILITY ─────────────────────────
                      _sectionHeader(
                          icon: Icons.visibility_rounded,
                          label: 'Availability',
                          color: AppColors.success),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _availabilityTile(
                              label: 'All',
                              icon: Icons.apps_rounded,
                              selected: tempAvailability == 'all',
                              color: AppColors.primary,
                              onTap: () =>
                                  setModalState(() => tempAvailability = 'all'),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _availabilityTile(
                              label: 'Active',
                              icon: Icons.check_circle_rounded,
                              selected: tempAvailability == 'available',
                              color: AppColors.success,
                              onTap: () => setModalState(
                                  () => tempAvailability = 'available'),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _availabilityTile(
                              label: 'Inactive',
                              icon: Icons.cancel_rounded,
                              selected: tempAvailability == 'unavailable',
                              color: Colors.grey.shade600,
                              onTap: () => setModalState(
                                  () => tempAvailability = 'unavailable'),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),
                      Divider(color: Colors.grey.shade100),
                      SizedBox(height: 16.h),

                      // ── STOCK ────────────────────────────────
                      _sectionHeader(
                          icon: Icons.inventory_2_rounded,
                          label: 'Stock',
                          color: AppColors.warning),
                      SizedBox(height: 12.h),
                      GestureDetector(
                        onTap: () =>
                            setModalState(() => tempLowStock = !tempLowStock),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: tempLowStock
                                ? AppColors.warning.withValues(alpha: 0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: tempLowStock
                                  ? AppColors.warning
                                  : Colors.grey.shade200,
                              width: 1.5.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: tempLowStock
                                      ? AppColors.warning
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.warning_rounded,
                                  size: 18.sp,
                                  color: tempLowStock
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Low Stock Only',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: tempLowStock
                                            ? AppColors.warning
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Show items with less than 10 units',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: tempLowStock,
                                onChanged: (v) =>
                                    setModalState(() => tempLowStock = v),
                                activeColor: AppColors.warning,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // ── APPLY BUTTON ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _sortBy = tempSort;
                              _availabilityFilter = tempAvailability;
                              _lowStockOnly = tempLowStock;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 10.w),
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _sortTile({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: 1.5.w,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14.sp,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 14.sp, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _availabilityTile({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: 1.5.w,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 22.sp, color: selected ? color : AppColors.textSecondary),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryGrid({
    required List<ItemModel> items,
    required int gridColumns,
    required bool isTablet,
  }) {
    // image (120h) + padding (10w*2) + name + category + price row + buttons + gaps = ~280h
    final double cardHeight = isTablet ? 300.h : 280.h;

    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 12.h,
        mainAxisExtent: cardHeight,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildProductCard(items[index], isTablet: isTablet);
      },
    );
  }

  Widget _buildProductCard(ItemModel item, {required bool isTablet}) {
    final isLowStock = item.quantity < 10;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Section with Gradient Overlay
          Stack(
            children: [
              Container(
                height: isTablet ? 140.h : 130.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.inputBackground,
                      AppColors.inputBackground.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                        ),
                        child: Image.network(
                          item.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.inventory_2_rounded,
                                size: isTablet ? 50.w : 45.w,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4)),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.inventory_2_rounded,
                            size: isTablet ? 50.w : 45.w,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.4)),
                      ),
              ),
              // Gradient overlay for better badge visibility
              Container(
                height: isTablet ? 140.h : 130.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
              ),
              // Availability Badge
              Positioned(
                top: 10.h,
                right: 10.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: item.isAvailable
                        ? AppColors.success
                        : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.w,
                        height: 5.w,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        item.isAvailable ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Low Stock Badge
              if (isLowStock)
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_rounded,
                            size: 12.sp, color: Colors.white),
                        SizedBox(width: 3.w),
                        Text(
                          'Low',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Content Section
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Name
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: isTablet ? 15.sp : 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                // Category with Icon
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(item.category),
                      size: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Price and Stock Row
                Row(
                  children: [
                    // Price
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primary.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rs.',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Flexible(
                              child: Text(
                                item.price.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    // Stock
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? AppColors.warning.withValues(alpha: 0.12)
                            : AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            size: 12.sp,
                            color: isLowStock
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            '${item.quantity}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isLowStock
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _showEditProductDialog(item, isTablet: isTablet),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1.w,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 14.sp, color: AppColors.primary),
                                SizedBox(width: 4.w),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Material(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      child: InkWell(
                        onTap: () => _deleteItem(item.id),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          child: Icon(Icons.delete_rounded,
                              size: 16.sp, color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInventory({
    required String vendorId,
    required bool isTablet,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 40.w : 32.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: isTablet ? 80.w : 64.w,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Products Yet',
              style: TextStyle(
                fontSize: isTablet ? 24.sp : 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Start building your inventory by\nadding your first product',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 16.sp : 14.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () =>
                  _showAddProductDialog(vendorId, isTablet: isTablet),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Your First Product',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16.sp : 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32.w : 24.w,
                  vertical: isTablet ? 16.h : 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults({required bool isTablet}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: isTablet ? 80.w : 64.w,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Products Found',
              style: TextStyle(
                fontSize: isTablet ? 20.sp : 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, {required bool isTablet}) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: isTablet ? 18.sp : 16.sp,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, {required bool isTablet}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: isTablet ? 64.w : 48.w, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'Error Loading Inventory',
              style: TextStyle(
                fontSize: isTablet ? 18.sp : 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ItemModel> _filterItems(List<ItemModel> items) {
    var filtered = items;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by availability
    if (_availabilityFilter == 'available') {
      filtered = filtered.where((item) => item.isAvailable).toList();
    } else if (_availabilityFilter == 'unavailable') {
      filtered = filtered.where((item) => !item.isAvailable).toList();
    }

    // Filter low stock only
    if (_lowStockOnly) {
      filtered = filtered.where((item) => item.quantity < 10).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'price_asc':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'stock_asc':
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'stock_desc':
        filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'name_asc':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return filtered;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.grid_view_rounded;
      case 'Chairs & Tables':
        return Icons.chair_outlined;
      case 'Crockery & Utensils':
        return Icons.restaurant_outlined;
      case 'Ice & Beverages':
        return Icons.local_drink_outlined;
      case 'Decor Items':
        return Icons.auto_awesome_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 28.sp),
            SizedBox(width: 12.w),
            const Text('Delete Product'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this product? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await VendorService.deleteItem(itemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12.w),
                  const Expanded(child: Text('Product deleted successfully')),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      }
    }
  }

  void _showAddProductDialog(String vendorId, {required bool isTablet}) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    String selectedCategory = _categories[1];
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 28.w : 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.add_shopping_cart,
                          color: AppColors.primary, size: 24.sp),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'Add New Product',
                        style: TextStyle(
                          fontSize: isTablet ? 22.sp : 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Image Picker
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final ImageSource? source = await showDialog<ImageSource>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          title: const Text('Select Image Source'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library,
                                    color: AppColors.primary),
                                title: const Text('Gallery'),
                                onTap: () =>
                                    Navigator.pop(context, ImageSource.gallery),
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt,
                                    color: AppColors.primary),
                                title: const Text('Camera'),
                                onTap: () =>
                                    Navigator.pop(context, ImageSource.camera),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (source != null) {
                        final XFile? image =
                            await picker.pickImage(source: source);
                        if (image != null) {
                          setState(() {
                            selectedImage = File(image.path);
                          });
                        }
                      }
                    },
                    child: Container(
                      width: isTablet ? 160.w : 140.w,
                      height: isTablet ? 160.w : 140.w,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2.w,
                        ),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: isTablet ? 48.w : 40.w,
                                  color: AppColors.primary,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Tap to upload',
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

                // Form Fields
                _buildTextField(
                  controller: nameController,
                  label: 'Product Name',
                  hint: 'Enter product name',
                  icon: Icons.inventory_2_outlined,
                  isTablet: isTablet,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: descController,
                  label: 'Description',
                  hint: 'Enter product description',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  isTablet: isTablet,
                ),
                SizedBox(height: 16.h),
                _buildDropdown(
                  value: selectedCategory,
                  label: 'Category',
                  icon: Icons.category_outlined,
                  items: _categories.skip(1).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                  isTablet: isTablet,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: priceController,
                        label: 'Price',
                        hint: '0',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        isTablet: isTablet,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildTextField(
                        controller: quantityController,
                        label: 'Stock',
                        hint: '0',
                        icon: Icons.inventory_outlined,
                        keyboardType: TextInputType.number,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty ||
                          priceController.text.isEmpty ||
                          quantityController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Please fill all required fields'),
                            backgroundColor: AppColors.warning,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );

                        String? imageUrl;
                        if (selectedImage != null) {
                          imageUrl =
                              await StorageService.uploadProductImageOnly(
                            file: selectedImage!,
                            vendorId: vendorId,
                          );
                        }

                        await VendorService.addItem(
                          vendorId: vendorId,
                          name: nameController.text,
                          description: descController.text,
                          category: selectedCategory,
                          price: double.parse(priceController.text),
                          quantity: int.parse(quantityController.text),
                          imageUrl: imageUrl,
                        );

                        if (context.mounted) {
                          Navigator.pop(context); // Close loading
                          Navigator.pop(context); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  SizedBox(width: 12.w),
                                  const Expanded(
                                      child:
                                          Text('Product added successfully')),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Product',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 16.sp : 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProductDialog(ItemModel item, {required bool isTablet}) {
    final nameController = TextEditingController(text: item.name);
    final descController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toString());
    final quantityController =
        TextEditingController(text: item.quantity.toString());
    File? newImage;
    String? currentImageUrl = item.imageUrl;
    bool isAvailable = item.isAvailable;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 28.w : 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.edit,
                          color: AppColors.secondary, size: 24.sp),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'Edit Product',
                        style: TextStyle(
                          fontSize: isTablet ? 22.sp : 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Image Picker
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final ImageSource? source = await showDialog<ImageSource>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          title: const Text('Select Image Source'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library,
                                    color: AppColors.primary),
                                title: const Text('Gallery'),
                                onTap: () =>
                                    Navigator.pop(context, ImageSource.gallery),
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt,
                                    color: AppColors.primary),
                                title: const Text('Camera'),
                                onTap: () =>
                                    Navigator.pop(context, ImageSource.camera),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (source != null) {
                        final XFile? image =
                            await picker.pickImage(source: source);
                        if (image != null) {
                          setState(() {
                            newImage = File(image.path);
                          });
                        }
                      }
                    },
                    child: Container(
                      width: isTablet ? 160.w : 140.w,
                      height: isTablet ? 160.w : 140.w,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2.w,
                        ),
                      ),
                      child: newImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: Image.file(
                                newImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : currentImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14.r),
                                  child: Image.network(
                                    currentImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            size: isTablet ? 48.w : 40.w,
                                            color: AppColors.primary),
                                        SizedBox(height: 12.h),
                                        Text('Change Photo',
                                            style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: isTablet ? 48.w : 40.w,
                                        color: AppColors.primary),
                                    SizedBox(height: 12.h),
                                    Text('Add Photo',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Availability Toggle
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isAvailable
                          ? AppColors.success.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                      width: 1.5.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAvailable ? Icons.check_circle : Icons.cancel,
                        color: isAvailable ? AppColors.success : Colors.grey,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product Availability',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              isAvailable
                                  ? 'Available for orders'
                                  : 'Not available',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isAvailable,
                        onChanged: (value) {
                          setState(() {
                            isAvailable = value;
                          });
                        },
                        activeColor: AppColors.success,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Form Fields
                _buildTextField(
                  controller: nameController,
                  label: 'Product Name',
                  hint: 'Enter product name',
                  icon: Icons.inventory_2_outlined,
                  isTablet: isTablet,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: descController,
                  label: 'Description',
                  hint: 'Enter product description',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  isTablet: isTablet,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: priceController,
                        label: 'Price',
                        hint: '0',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        isTablet: isTablet,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildTextField(
                        controller: quantityController,
                        label: 'Stock',
                        hint: '0',
                        icon: Icons.inventory_outlined,
                        keyboardType: TextInputType.number,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );

                        String? updatedImageUrl = currentImageUrl;
                        if (newImage != null) {
                          updatedImageUrl =
                              await StorageService.uploadProductImageOnly(
                            file: newImage!,
                            vendorId: item.vendorId,
                          );
                        }

                        await VendorService.updateItem(
                          itemId: item.id,
                          name: nameController.text,
                          description: descController.text,
                          price: double.parse(priceController.text),
                          quantity: int.parse(quantityController.text),
                          imageUrl: updatedImageUrl,
                          isAvailable: isAvailable,
                        );

                        if (context.mounted) {
                          Navigator.pop(context); // Close loading
                          Navigator.pop(context); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  SizedBox(width: 12.w),
                                  const Expanded(
                                      child:
                                          Text('Product updated successfully')),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Update Product',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 16.sp : 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required bool isTablet,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: isTablet ? 15.sp : 14.sp),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primary, width: 2.w),
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isTablet,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primary, width: 2.w),
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child:
              Text(item, style: TextStyle(fontSize: isTablet ? 15.sp : 14.sp)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
