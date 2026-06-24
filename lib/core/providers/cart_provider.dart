import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../constants/app_constants.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];
  String? _selectedVendorId;
  String? _selectedVendorName;

  List<CartItemModel> get items => _items;
  String? get selectedVendorId => _selectedVendorId;
  String? get selectedVendorName => _selectedVendorName;

  int get itemCount => _items.length;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee {
    return 0; // Calculated dynamically at checkout based on vehicle/distance
  }

  double get totalAmount => subtotal + deliveryFee;

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  bool get meetsMinimumOrder => subtotal >= AppConstants.minimumOrderAmount;

  void addItem(ProductModel product, String vendorName) {
    if (_selectedVendorId != null && _selectedVendorId != product.vendorId) {
      throw 'Cannot add items from different vendors';
    }

    final existingIndex =
        _items.indexWhere((item) => item.productId == product.id);

    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity >= product.quantity) {
        throw 'Maximum stock available is ${product.quantity}';
      }
      _items[existingIndex].quantity++;
    } else {
      if (product.quantity < 1) {
        throw 'Out of stock';
      }
      _items.add(CartItemModel(
        productId: product.id,
        productName: product.name,
        productImage: product.images.isNotEmpty ? product.images.first : '',
        vendorId: product.vendorId,
        vendorName: vendorName,
        price: product.effectivePrice,
        unit: product.unit,
        quantity: 1,
        maxQuantity: product.quantity,
      ));

      _selectedVendorId = product.vendorId;
      _selectedVendorName = vendorName;
    }

    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);

    if (_items.isEmpty) {
      _selectedVendorId = null;
      _selectedVendorName = null;
    }

    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (quantity > _items[index].maxQuantity) {
        // Optionally throw or just cap it
        // throw 'Maximum available quantity is ${_items[index].maxQuantity}';
        _items[index].quantity = _items[index].maxQuantity;
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (_items[index].quantity < _items[index].maxQuantity) {
        _items[index].quantity++;
        notifyListeners();
      } else {
        // Could notify caller via return or callback, but provider just updates state.
      }
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        notifyListeners();
      } else {
        removeItem(productId);
      }
    }
  }

  int getItemQuantity(String productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  bool canAddFromVendor(String vendorId) {
    return _selectedVendorId == null || _selectedVendorId == vendorId;
  }

  void clearCart() {
    _items.clear();
    _selectedVendorId = null;
    _selectedVendorName = null;
    notifyListeners();
  }
}
