import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/utils/responsive_utils.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedVehicleFilter = 'all';
  String _selectedStatusFilter = 'all';
  String _searchQuery = ''; // Only updated when search button is clicked
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Manage Users',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            )),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontSize: ResponsiveUtils.body2,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: ResponsiveUtils.body2,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Hosts'),
                Tab(text: 'Vendors'),
                Tab(text: 'Riders'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList('host'),
          _buildUserList('vendor'),
          _buildUserList('rider'),
        ],
      ),
    );
  }

  Widget _buildUserList(String type) {
    return StreamBuilder<List<UserModel>>(
      key: ValueKey(
          '$type-$_searchQuery-$_selectedStatusFilter-$_selectedVehicleFilter'),
      stream: AdminService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allUsers = snapshot.data ?? [];

        // Filter users by type
        var filteredUsers =
            allUsers.where((user) => user.role == type).toList();

        // Apply Status Filter for Hosts and Vendors (only if explicitly set)
        if ((type == 'host' || type == 'vendor') &&
            _selectedStatusFilter != 'all') {
          final isActive = _selectedStatusFilter == 'active';
          filteredUsers =
              filteredUsers.where((user) => user.isActive == isActive).toList();
        }

        // Apply Search Filter for Hosts and Vendors (only if search was performed)
        if ((type == 'host' || type == 'vendor') && _searchQuery.isNotEmpty) {
          filteredUsers = filteredUsers
              .where((user) =>
                  user.name.toLowerCase().contains(_searchQuery) ||
                  user.email.toLowerCase().contains(_searchQuery) ||
                  user.phone.toLowerCase().contains(_searchQuery))
              .toList();
        }

        // Apply Vehicle Filter for Riders
        if (type == 'rider' && _selectedVehicleFilter != 'all') {
          filteredUsers = filteredUsers
              .where((user) => user.vehicleType == _selectedVehicleFilter)
              .toList();
        }

        if (filteredUsers.isEmpty && type != 'rider') {
          return _buildEmptyState(type, allUsers.length);
        } else if (filteredUsers.isEmpty &&
            type == 'rider' &&
            _selectedVehicleFilter == 'all') {
          return _buildEmptyState(type, allUsers.length);
        }

        // Return List or Column(Filter + List)
        Widget listContent = ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) =>
              _buildUserCard(context, filteredUsers[index]),
        );

        if (type == 'rider') {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildRiderFilterSection(),
                SizedBox(height: 8.h),
                if (filteredUsers.isEmpty)
                  _buildEmptyState(type, allUsers.length)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.w),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) =>
                        _buildUserCard(context, filteredUsers[index]),
                  ),
              ],
            ),
          );
        }

        // For Hosts and Vendors - show search and status filter
        if (type == 'host' || type == 'vendor') {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildSearchAndFilterSection(),
                SizedBox(height: 8.h),
                if (filteredUsers.isEmpty)
                  _buildEmptyState(type, allUsers.length)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16.w),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) =>
                        _buildUserCard(context, filteredUsers[index]),
                  ),
              ],
            ),
          );
        }

        return listContent;
      },
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar with Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or phone...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.primary, size: 20.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 14.h,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              SizedBox(width: 8.w),
              // Search Button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _performSearch,
                  tooltip: 'Search',
                ),
              ),
              SizedBox(width: 8.w),
              // Clear Button
              if (_searchQuery.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: _clearSearch,
                    tooltip: 'Clear',
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          // Status Filter Header
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: AppColors.primary,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildStatusFilterChip('All', 'all', Icons.apps),
              _buildStatusFilterChip('Active', 'active', Icons.check_circle),
              _buildStatusFilterChip('Inactive', 'inactive', Icons.cancel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiderFilterSection() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: AppColors.primary,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Filter by Vehicle Type',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildProfessionalFilterChip('All Vehicles', 'all', Icons.apps),
              _buildProfessionalFilterChip('Bike', 'bike', Icons.two_wheeler),
              _buildProfessionalFilterChip('Car', 'car', Icons.directions_car),
              _buildProfessionalFilterChip('Van', 'van', Icons.local_shipping),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalFilterChip(
      String label, String value, IconData icon) {
    final isSelected = _selectedVehicleFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedVehicleFilter = value),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.w,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedStatusFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = value),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.w,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type, int totalUsers) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Center(
              child: Icon(
                _getIconForType(type),
                size: 40.w,
                color: AppColors.info,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No ${type}s found',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Total users in database: $totalUsers',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'host':
        return Icons.person;
      case 'vendor':
        return Icons.store;
      case 'rider':
        return Icons.delivery_dining;
      default:
        return Icons.person;
    }
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28.r),
                ),
                child: Center(
                  child: Text(
                    _getEmojiForRole(user.role),
                    style: TextStyle(fontSize: 28.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user.phone,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleUserAction(value, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'view', child: Text('View Details')),
                  if (user.role == 'vendor')
                    const PopupMenuItem(
                        value: 'subscription',
                        child: Text('Manage Subscription')),
                  PopupMenuItem(
                    value: user.isActive ? 'deactivate' : 'activate',
                    child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Status Badges
          Row(
            children: [
              // Vehicle Type Badge (for riders)
              if (user.role == 'rider' && user.vehicleType != null)
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Vehicle: ${user.vehicleType}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ),
              // Active/Inactive Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isActive ? Icons.check_circle : Icons.cancel,
                      size: 12.w,
                      color:
                          user.isActive ? AppColors.success : AppColors.error,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color:
                            user.isActive ? AppColors.success : AppColors.error,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Approval Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: user.isApproved
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isApproved ? Icons.verified : Icons.pending,
                      size: 12.w,
                      color: user.isApproved
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      user.isApproved ? 'Approved' : 'Pending',
                      style: TextStyle(
                        color: user.isApproved
                            ? AppColors.success
                            : AppColors.warning,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getEmojiForRole(String role) {
    switch (role) {
      case 'host':
        return '🏠';
      case 'vendor':
        return '🏪';
      case 'rider':
        return '🛵';
      case 'admin':
        return '👨‍💼';
      default:
        return '👤';
    }
  }

  Future<void> _handleUserAction(String action, UserModel user) async {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'activate':
        await AdminService.activateUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User activated'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        break;
      case 'deactivate':
        await AdminService.deactivateUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deactivated'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        break;
      case 'subscription':
        _showSubscriptionManager(user);
        break;
    }
  }

  void _showSubscriptionManager(UserModel user) {
    String selectedTier = 'free';
    bool isLoading = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            FirebaseFirestore.instance
                .collection('vendors')
                .doc(user.id)
                .get()
                .then((doc) {
              if (doc.exists && context.mounted) {
                setState(() {
                  selectedTier = doc.data()?['subscriptionTier'] ?? 'free';
                  isLoading = false;
                });
              } else if (context.mounted) {
                setState(() => isLoading = false);
              }
            });
          }

          return AlertDialog(
            title: const Text('Manage Subscription'),
            content: isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vendor: ${user.name}'),
                      SizedBox(height: 16.h),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTier,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Subscription Tier'),
                        items: const [
                          DropdownMenuItem(
                            value: 'free',
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Free (10% Commission)'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'pro',
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Pro (5% Commission)'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'enterprise',
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Enterprise (2% Commission)'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedTier = value);
                          }
                        },
                      ),
                    ],
                  ),
            actions: [
              if (!isLoading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              if (!isLoading)
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('vendors')
                        .doc(user.id)
                        .set({'subscriptionTier': selectedTier},
                            SetOptions(merge: true));

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subscription updated')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phone),
              _buildDetailRow('Address', user.address ?? 'N/A'),
              _buildDetailRow('Role', user.role),
              if (user.role == 'rider')
                _buildDetailRow('Vehicle', user.vehicleType ?? 'N/A'),
              _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow(
                  'Approval', user.isApproved ? 'Approved' : 'Pending'),
              _buildDetailRow('User ID', user.id),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
