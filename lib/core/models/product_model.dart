class ProductModel {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final String category;
  final double price;
  final double? discountPrice;
  final String unit;
  final int quantity;
  final int minOrderQuantity;
  final List<String> images;
  final bool isAvailable;
  final bool isEmergencyAvailable;
  final int preparationTime;
  final double rating;
  final int totalOrders;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.discountPrice,
    required this.unit,
    required this.quantity,
    this.minOrderQuantity = 1,
    required this.images,
    this.isAvailable = true,
    this.isEmergencyAvailable = true,
    this.preparationTime = 10,
    this.rating = 0.0,
    this.totalOrders = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get effectivePrice => discountPrice ?? price;
  
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  
  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((price - discountPrice!) / price * 100);
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      discountPrice: map['discountPrice']?.toDouble(),
      unit: map['unit'] ?? 'piece',
      quantity: map['quantity'] ?? 0,
      minOrderQuantity: map['minOrderQuantity'] ?? 1,
      images: List<String>.from(map['images'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      isEmergencyAvailable: map['isEmergencyAvailable'] ?? true,
      preparationTime: map['preparationTime'] ?? 10,
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalOrders: map['totalOrders'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'discountPrice': discountPrice,
      'unit': unit,
      'quantity': quantity,
      'minOrderQuantity': minOrderQuantity,
      'images': images,
      'isAvailable': isAvailable,
      'isEmergencyAvailable': isEmergencyAvailable,
      'preparationTime': preparationTime,
      'rating': rating,
      'totalOrders': totalOrders,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  ProductModel copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    String? category,
    double? price,
    double? discountPrice,
    String? unit,
    int? quantity,
    int? minOrderQuantity,
    List<String>? images,
    bool? isAvailable,
    bool? isEmergencyAvailable,
    int? preparationTime,
    double? rating,
    int? totalOrders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      isEmergencyAvailable: isEmergencyAvailable ?? this.isEmergencyAvailable,
      preparationTime: preparationTime ?? this.preparationTime,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
