import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';

class VendorCard extends StatelessWidget {
  final String name;
  final String category;
  final double rating;
  final String distance;
  final String deliveryTime;
  final String imageUrl;
  final VoidCallback onTap;

  const VendorCard({
    super.key,
    required this.name,
    required this.category,
    required this.rating,
    required this.distance,
    required this.deliveryTime,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Use Container directly for styling
      margin: EdgeInsets.symmetric(
          horizontal: 4.w), // Slight horizontal margin for shadow visibility
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r), // Consistent radius
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center vertically
              children: [
                Container(
                  width: 56.w, // Slightly larger image
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text('🏪', style: TextStyle(fontSize: 28.sp)),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp, // Larger title
                                    color: AppColors.textPrimary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            // Rating Pill
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star,
                                    color: Colors.amber[700], size: 12.sp),
                                SizedBox(width: 2.w),
                                Text(
                                  rating.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.sp,
                                    color: Colors.amber[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13.sp,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .location_on_outlined, // Outlined icon for cleaner look
                            color: AppColors.textSecondary,
                            size: 14.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            distance,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.sp,
                                    ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.access_time, // Outlined icon
                            color: AppColors.textSecondary,
                            size: 14.sp,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              deliveryTime,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.sp,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Removed Chevron for cleaner look, card itself is clickable
              ],
            ),
          ),
        ),
      ),
    );
  }
}
