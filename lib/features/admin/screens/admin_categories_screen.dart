import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/category_service.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/models/category_model.dart';
import 'admin_add_edit_category_screen.dart';
import 'category_analytics_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Load categories on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Category Management',
            style: TextStyle(color: AppColors.primary)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          PopupMenuButton(
            onSelected: (value) async {
              if (value == 'export') {
                // Trigger Export
                final csv = await CategoryService.generateCategoryCsv();
                if (context.mounted) {
                  showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                            title: const Text('Export Content'),
                            content: SingleChildScrollView(child: Text(csv)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text('Close'))
                            ],
                          ));
                }
              } else if (value == 'bulk') {
                // Trigger Bulk Edit
                // For now, toggle status of all restricted categories (mock)
                // In real app, we would select them first
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Bulk Actions available in Phase 3.5')));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'export', child: Text('Export to CSV')),
              const PopupMenuItem(value: 'bulk', child: Text('Bulk Edit')),
              const PopupMenuItem(value: 'sync', child: Text('Sync Vendors')),
              const PopupMenuItem(
                  value: 'reports', child: Text('View Reports')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All Categories'),
            Tab(text: 'Featured'),
            Tab(text: 'Pending Approval'),
            Tab(text: 'Restricted'),
            Tab(text: 'Performance'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllCategoriesTab(provider.categories),
              _buildFeaturedCategoriesTab(provider.featuredCategories),
              _buildPendingApprovalTab(), // Placeholder for Phase 2
              _buildRestrictedCategoriesTab(provider.restrictedCategories),
              _buildPerformanceTab(), // Placeholder for Phase 3
              _buildSettingsTab(), // Placeholder
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminAddEditCategoryScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAllCategoriesTab(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.1),
          child: Text(category.icon),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${category.type.name.toUpperCase()} • ${category.tier.name.toUpperCase()}',
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textSecondary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdminAddEditCategoryScreen(category: category),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedCategoriesTab(List<CategoryModel> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  // Placeholders for future phases
  Widget _buildPendingApprovalTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<CategoryProvider>().pendingApplicationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final applications = snapshot.data ?? [];

        if (applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64.w, color: Colors.grey),
                SizedBox(height: 16.h),
                const Text('No pending approvals'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final app = applications[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(app['vendorName'] ?? 'Unknown Vendor'),
                subtitle: Text(
                    'Applying for: ${app['categoryName'] ?? 'Unknown Category'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        // Reject logic placeholder
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        // Approve logic placeholder
                        if (app['vendorId'] != null &&
                            app['categoryId'] != null) {
                          // context.read<CategoryProvider>().approveVendor(app['vendorId'], app['categoryId']);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRestrictedCategoriesTab(List<CategoryModel> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildPerformanceTab() {
    return const CategoryAnalyticsScreen();
  }

  Widget _buildSettingsTab() =>
      const Center(child: Text('Global Settings coming in Phase 3'));
}
