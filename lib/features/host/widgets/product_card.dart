import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/responsive_widgets.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final String vendorName;

  const ProductCard({
    super.key,
    required this.product,
    required this.vendorName,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      padding: EdgeInsets.zero,
      elevation: 4, // Slightly higher elevation for a premium feel
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section - Fixed height based on screen size for consistency
          SizedBox(
            height:
                ResponsiveUtils.screenHeight * 0.14, // ~18% of screen height
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12.0),
                    ),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  child: product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12.0),
                          ),
                          child: Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: ResponsiveUtils.xs,
                    left: ResponsiveUtils.xs,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.xs,
                        vertical: ResponsiveUtils.xs / 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.caption * 0.9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content Section
          // Content Section
          // Content Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ResponsiveText(
                              product.name,
                              maxLines:
                                  2, // Reverted to 2 lines as we have more space
                              minFontSize: 12,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.body2,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.xs),
                          Text(
                            '/ ${product.unit}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: ResponsiveUtils.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Row
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            if (product.hasDiscount)
                              Text(
                                'Rs.${product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textSecondary,
                                  fontSize: ResponsiveUtils.caption,
                                ),
                              ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Rs.${product.effectivePrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: ResponsiveUtils.body1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.xs),
                      // Action Button
                      SizedBox(
                        height: 36, // Restored height for better touch target
                        child: _buildActionButtons(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        _getCategoryEmoji(product.category),
        style: TextStyle(
          fontSize: ResponsiveUtils.headline4,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final quantity = cart.getItemQuantity(product.id);

        if (quantity > 0) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max, // Let it fill the container width
              children: [
                _buildQuantityBtn(
                  icon: Icons.remove,
                  onTap: () => cart.decrementQuantity(product.id),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: ResponsiveUtils.body2,
                      ),
                    ),
                  ),
                ),
                _buildQuantityBtn(
                  icon: Icons.add,
                  onTap: () => cart.incrementQuantity(product.id),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: cart.canAddFromVendor(product.vendorId)
                ? () => cart.addItem(product, vendorName)
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You can only order from one vendor at a time',
                        ),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Add',
                style: TextStyle(
                  fontSize: ResponsiveUtils.body2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantityBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'chairs_tables':
        return '🪑';
      case 'crockery_utensils':
        return '🍽️';
      case 'ice_beverages':
        return '🧊';
      case 'fuel_gas':
        return '🔥';
      case 'decor_items':
        return '🎀';
      case 'manpower':
        return '👷';
      default:
        return '📦';
    }
  }
}
