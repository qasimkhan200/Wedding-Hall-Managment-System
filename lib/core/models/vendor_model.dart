class VendorModel {
  final String id;
  final String userId;
  final String businessName;
  final String description;
  final String phone;
  final String email;
  final String address;
  final double latitude;
  final double longitude;
  final String? cnicImage;
  final String? logoImage;
  final String? coverImage;
  final List<String> categories;
  final double rating;
  final int totalOrders;
  final int completedOrders;
  final bool isOnline;
  final bool isApproved;
  final bool isActive;
  final Map<String, dynamic>? operatingHours;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String subscriptionTier; // 'free', 'pro', 'enterprise'

  VendorModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    required this.phone,
    required this.email,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.logoImage,
    this.coverImage,
    this.cnicImage,
    required this.categories,
    this.rating = 0.0,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.isOnline = false,
    this.isApproved = false,
    this.isActive = true,
    this.operatingHours,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionTier = 'free',
  });

  factory VendorModel.fromMap(Map<String, dynamic> map, String id) {
    return VendorModel(
      id: id,
      userId: map['userId'] ?? '',
      businessName: map['businessName'] ?? '',
      description: map['description'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      logoImage: map['logoImage'],
      coverImage: map['coverImage'],
      cnicImage: map['cnicImage'],
      categories: List<String>.from(map['categories'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalOrders: map['totalOrders'] ?? 0,
      completedOrders: map['completedOrders'] ?? 0,
      isOnline: map['isOnline'] ?? false,
      isApproved: map['isApproved'] ?? false,
      isActive: map['isActive'] ?? true,
      operatingHours: map['operatingHours'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
      subscriptionTier: map['subscriptionTier'] ?? 'free',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'description': description,
      'phone': phone,
      'email': email,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'logoImage': logoImage,
      'coverImage': coverImage,
      'cnicImage': cnicImage,
      'categories': categories,
      'rating': rating,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'isOnline': isOnline,
      'isApproved': isApproved,
      'isActive': isActive,
      'operatingHours': operatingHours,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'subscriptionTier': subscriptionTier,
    };
  }

  VendorModel copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? description,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    String? logoImage,
    String? coverImage,
    String? cnicImage,
    List<String>? categories,
    double? rating,
    int? totalOrders,
    int? completedOrders,
    bool? isOnline,
    bool? isApproved,
    bool? isActive,
    Map<String, dynamic>? operatingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? subscriptionTier,
  }) {
    return VendorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      logoImage: logoImage ?? this.logoImage,
      coverImage: coverImage ?? this.coverImage,
      cnicImage: cnicImage ?? this.cnicImage,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      isOnline: isOnline ?? this.isOnline,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      operatingHours: operatingHours ?? this.operatingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    );
  }
}
