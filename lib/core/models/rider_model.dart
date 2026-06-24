class RiderModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehicleNumber;
  final String? profileImage;
  final String? licenseImage;
  final String? cnicImage;
  final double latitude;
  final double longitude;
  final double rating;
  final int totalDeliveries;
  final int completedDeliveries;
  final double totalEarnings;
  final bool isOnline;
  final bool isAvailable;
  final bool isApproved;
  final bool isActive;
  final String? currentOrderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  RiderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehicleNumber,
    this.profileImage,
    this.licenseImage,
    this.cnicImage,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.completedDeliveries = 0,
    this.totalEarnings = 0.0,
    this.isOnline = false,
    this.isAvailable = true,
    this.isApproved = false,
    this.isActive = true,
    this.currentOrderId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RiderModel.fromMap(Map<String, dynamic> map, String id) {
    return RiderModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      vehicleType: map['vehicleType'] ?? 'bike',
      vehicleNumber: map['vehicleNumber'] ?? '',
      profileImage: map['profileImage'],
      licenseImage: map['licenseImage'],
      cnicImage: map['cnicImage'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalDeliveries: map['totalDeliveries'] ?? 0,
      completedDeliveries: map['completedDeliveries'] ?? 0,
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      isOnline: map['isOnline'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      isApproved: map['isApproved'] ?? false,
      isActive: map['isActive'] ?? true,
      currentOrderId: map['currentOrderId'],
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
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'profileImage': profileImage,
      'licenseImage': licenseImage,
      'cnicImage': cnicImage,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'completedDeliveries': completedDeliveries,
      'totalEarnings': totalEarnings,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'isApproved': isApproved,
      'isActive': isActive,
      'currentOrderId': currentOrderId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  RiderModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? vehicleNumber,
    String? profileImage,
    String? licenseImage,
    String? cnicImage,
    double? latitude,
    double? longitude,
    double? rating,
    int? totalDeliveries,
    int? completedDeliveries,
    double? totalEarnings,
    bool? isOnline,
    bool? isAvailable,
    bool? isApproved,
    bool? isActive,
    String? currentOrderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RiderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      profileImage: profileImage ?? this.profileImage,
      licenseImage: licenseImage ?? this.licenseImage,
      cnicImage: cnicImage ?? this.cnicImage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      isOnline: isOnline ?? this.isOnline,
      isAvailable: isAvailable ?? this.isAvailable,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
