import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/rider_assignment_model.dart';
import '../../../core/services/rider_assignment_service.dart';
import '../../../core/services/delivery_calculation_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/location_provider.dart';

class RiderAssignmentScreen extends StatefulWidget {
  final OrderModel order;

  const RiderAssignmentScreen({super.key, required this.order});

  @override
  State<RiderAssignmentScreen> createState() => _RiderAssignmentScreenState();
}

class _RiderAssignmentScreenState extends State<RiderAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  RiderAssignmentModel? _currentAssignment;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkExistingAssignment();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingAssignment() async {
    try {
      final assignment =
          await RiderAssignmentService.getAssignmentByOrderId(widget.order.id);
      if (mounted) {
        setState(() {
          _currentAssignment = assignment;
        });
      }
    } catch (e) {
      // Assignment doesn't exist yet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Rider - Order #${widget.order.id.substring(0, 8)}'),
        bottom: _currentAssignment == null
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Available Riders'),
                  Tab(text: 'Auto Assign'),
                ],
              )
            : null,
      ),
      body: _currentAssignment != null
          ? _buildAssignmentDetails()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableRiders(),
                _buildAutoAssign(),
              ],
            ),
    );
  }

  Widget _buildAssignmentDetails() {
    final assignment = _currentAssignment!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppColors.success, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rider Assigned Successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Assigned to ${assignment.riderName}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildOrderSummary(),
          const SizedBox(height: 24),
          _buildRiderDetails(assignment),
          const SizedBox(height: 24),
          _buildAssignmentStatus(assignment),
          const SizedBox(height: 24),
          if (assignment.status == 'assigned')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(assignment.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Cancel Assignment'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableRiders() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.inputBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text('Order #${widget.order.id.substring(0, 8)}'),
              Text('Items: ${widget.order.items.length}'),
              Text('Total: Rs. ${widget.order.totalAmount.toStringAsFixed(0)}'),
              Text('Delivery: ${widget.order.deliveryAddress}'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: RiderAssignmentService.getAvailableRiders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Error loading riders: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final riders = snapshot.data ?? [];

              if (riders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🛵', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 16),
                      Text(
                        'No Available Riders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All riders are currently busy or offline',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: riders.length,
                itemBuilder: (context, index) {
                  return _buildRiderCard(riders[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutoAssign() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummary(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, size: 48, color: AppColors.info),
                const SizedBox(height: 16),
                const Text(
                  'Smart Auto Assignment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Our system will automatically find the best available rider based on:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.info, size: 20),
                    SizedBox(width: 8),
                    Text('Proximity to pickup location'),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.star, color: AppColors.info, size: 20),
                    SizedBox(width: 8),
                    Text('Rider rating and performance'),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.info, size: 20),
                    SizedBox(width: 8),
                    Text('Current availability status'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _autoAssignRider,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Auto Assign Rider'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Order ID', '#${widget.order.id.substring(0, 8)}'),
          _buildDetailRow('Customer', widget.order.hostName),
          _buildDetailRow('Phone', widget.order.hostPhone),
          _buildDetailRow('Items', '${widget.order.items.length} items'),
          _buildDetailRow('Total Amount',
              'Rs. ${widget.order.totalAmount.toStringAsFixed(0)}'),
          _buildDetailRow('Delivery Fee',
              'Rs. ${widget.order.deliveryFee.toStringAsFixed(0)}'),
          const Divider(height: 20),
          const Text(
            'Delivery Address:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            widget.order.deliveryAddress,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (widget.order.specialInstructions != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Special Instructions:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.order.specialInstructions!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(UserModel rider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: rider.profileImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      rider.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('🛵', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  )
                : const Center(
                    child: Text('🛵', style: TextStyle(fontSize: 28)),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  rider.phone,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Consumer<LocationProvider>(
                        builder: (context, locationProvider, child) {
                          String distanceText = 'Distance unknown';

                          // Calculate distance from rider to pickup location
                          if (rider.latitude != null &&
                              rider.longitude != null &&
                              locationProvider.hasLocation) {
                            final distanceKm =
                                DeliveryCalculationService.calculateDistance(
                              lat1: rider.latitude!,
                              lon1: rider.longitude!,
                              lat2: locationProvider.latitude!,
                              lon2: locationProvider.longitude!,
                            );

                            distanceText =
                                '${DeliveryCalculationService.formatDistance(distanceKm)} away';
                          }

                          return Text(
                            distanceText,
                            style: const TextStyle(
                              color: AppColors.info,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _assignRider(rider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderDetails(RiderAssignmentModel assignment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned Rider',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text('🛵', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.riderName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment.riderPhone,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 16, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          'ETA: ${assignment.estimatedMinutes} mins',
                          style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _callRider(assignment.riderPhone),
                icon: const Icon(Icons.phone, color: AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentStatus(RiderAssignmentModel assignment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assignment Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildStatusStep('Assigned', assignment.assignedAt,
              assignment.status == 'assigned', true),
          _buildStatusStep(
              'Accepted',
              assignment.acceptedAt,
              assignment.status == 'accepted',
              ['accepted', 'picked_up', 'delivered']
                  .contains(assignment.status)),
          _buildStatusStep(
              'Picked Up',
              assignment.pickedUpAt,
              assignment.status == 'picked_up',
              ['picked_up', 'delivered'].contains(assignment.status)),
          _buildStatusStep(
              'Delivered',
              assignment.deliveredAt,
              assignment.status == 'delivered',
              assignment.status == 'delivered'),
        ],
      ),
    );
  }

  Widget _buildStatusStep(
      String title, DateTime? timestamp, bool isActive, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isActive
                      ? AppColors.warning
                      : AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isActive
                        ? Colors.black
                        : AppColors.textSecondary,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    _formatDateTime(timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _assignRider(UserModel rider) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = context.read<AuthProvider>();
      final vendorId = authProvider.user?.id ?? '';

      final assignment = await RiderAssignmentService.assignRider(
        orderId: widget.order.id,
        vendorId: vendorId,
        riderId: rider.id,
        riderName: rider.name,
        riderPhone: rider.phone,
        deliveryFee: widget.order.deliveryFee,
        specialInstructions: widget.order.specialInstructions,
      );

      if (mounted) {
        setState(() {
          _currentAssignment = assignment;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rider ${rider.name} assigned successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _autoAssignRider() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = context.read<AuthProvider>();
      final vendorId = authProvider.user?.id ?? '';

      final assignment = await RiderAssignmentService.autoAssignRider(
        orderId: widget.order.id,
        vendorId: vendorId,
        deliveryFee: widget.order.deliveryFee,
        pickupLatitude: widget.order.deliveryLatitude,
        pickupLongitude: widget.order.deliveryLongitude,
      );

      if (mounted && assignment != null) {
        setState(() {
          _currentAssignment = assignment;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Rider ${assignment.riderName} auto-assigned successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCancelDialog(String assignmentId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Assignment'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Reason for cancellation',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancelled by vendor'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await RiderAssignmentService.cancelAssignment(
          assignmentId: assignmentId,
          reason: reason,
        );

        if (mounted) {
          setState(() {
            _currentAssignment = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment cancelled successfully'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _callRider(String phoneNumber) {
    // In a real app, you would use url_launcher to make a phone call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
