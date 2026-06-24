class ItemModel {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String category;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.category,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map, String id) {
    return ItemModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      imageUrl: map['imageUrl'],
      category: map['category'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    // Handle Firestore Timestamp
    if (value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate();
    }

    // Handle int (milliseconds)
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    // Handle String (parse as int)
    if (value is String) {
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return DateTime.fromMillisecondsSinceEpoch(intValue);
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  ItemModel copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
