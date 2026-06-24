import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/order_model.dart';

class ResponsiveCancelDialog extends StatefulWidget {
  final OrderModel delivery;
  final Function(String reason) onConfirm;

  const ResponsiveCancelDialog({
    super.key,
    required this.delivery,
    required this.onConfirm,
  });

  @override
  State<ResponsiveCancelDialog> createState() => _ResponsiveCancelDialogState();
}

class _ResponsiveCancelDialogState extends State<ResponsiveCancelDialog> {
  final List<String> cancelReasons = [
    'Vehicle breakdown',
    'Emergency situation',
    'Unable to reach vendor',
    'Traffic/road conditions',
    'Personal emergency',
    'Other',
  ];

  late String selectedReason;
  final TextEditingController customReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedReason = cancelReasons.first;
  }

  @override
  void dispose() {
    customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500.w,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Cancel Delivery',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 24.sp),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Order ID
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Order #${widget.delivery.id.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Reason label
                Text(
                  'Reason for cancellation:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),

                // Dropdown
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                  icon: Icon(Icons.arrow_drop_down, size: 24.sp),
                  items: cancelReasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(
                        reason,
                        style: TextStyle(fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value!;
                    });
                  },
                ),

                // Custom reason input
                if (selectedReason == 'Other') ...[
                  SizedBox(height: 12.h),
                  TextField(
                    controller: customReasonController,
                    decoration: InputDecoration(
                      labelText: 'Please specify',
                      labelStyle: TextStyle(fontSize: 14.sp),
                      hintText: 'Enter your reason...',
                      hintStyle: TextStyle(fontSize: 13.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    style: TextStyle(fontSize: 14.sp),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                ],

                SizedBox(height: 20.h),

                // Warning container
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      width: 1.5.w,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 22.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Cancellation Policy',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        widget.delivery.status == AppConstants.statusPickedUp ||
                                widget.delivery.status ==
                                    AppConstants.statusInTransit
                            ? '• You have already picked up the items\n'
                                '• Items must be returned to vendor\n'
                                '• Customer will be notified immediately\n'
                                '• This may significantly impact your rating\n'
                                '• Order will be reassigned to another rider'
                            : '• Frequent cancellations may affect your rating\n'
                                '• The order will be reassigned to another rider\n'
                                '• Customer will be notified of the cancellation',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          side: BorderSide(
                            color: AppColors.textSecondary,
                            width: 1.5.w,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Keep Delivery',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final reason = selectedReason == 'Other'
                              ? customReasonController.text.trim()
                              : selectedReason;

                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please provide a reason for cancellation',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);
                          widget.onConfirm(reason);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Cancel Delivery',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
