class CartItemModel {
  final String productId;
  final String productName;
  final String productImage;
  final String vendorId;
  final String vendorName;
  final double price;
  final String unit;
  int quantity;
  final int maxQuantity;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.vendorId,
    required this.vendorName,
    required this.price,
    required this.unit,
    this.quantity = 1,
    this.maxQuantity = 100, // Default for backward compatibility
  });

  double get totalPrice => price * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'piece',
      quantity: map['quantity'] ?? 1,
      maxQuantity: map['maxQuantity'] ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'maxQuantity': maxQuantity,
    };
  }

  CartItemModel copyWith({
    String? productId,
    String? productName,
    String? productImage,
    String? vendorId,
    String? vendorName,
    double? price,
    String? unit,
    int? quantity,
    int? maxQuantity,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
    );
  }
}
