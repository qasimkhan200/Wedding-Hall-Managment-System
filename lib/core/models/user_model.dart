class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String? profileImage;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final DateTime? lastTokenUpdate;
  final String? vehicleType;
  final String? vehicleNumber;
  final double rating;
  final int reviewCount;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImage,
    this.address,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.isApproved = false,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.lastTokenUpdate,
    this.vehicleType,
    this.vehicleNumber,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'host',
      profileImage: map['profileImage'],
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      isActive: map['isActive'] ?? true,
      isApproved: map['isApproved'] ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      fcmToken: map['fcmToken'],
      lastTokenUpdate: map['lastTokenUpdate'] != null
          ? _parseDateTime(map['lastTokenUpdate'])
          : null,
      vehicleType: map['vehicleType'],
      vehicleNumber: map['vehicleNumber'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    // If it's already a DateTime
    if (value is DateTime) return value;

    try {
      // If it's a Firestore Timestamp
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
    } catch (e) {
      // Continue to other checks if Timestamp conversion fails
    }

    try {
      // If it's an integer (milliseconds since epoch)
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      // Continue to other checks if int conversion fails
    }

    try {
      // If it's a string representation of milliseconds
      if (value is String) {
        final intValue = int.tryParse(value);
        if (intValue != null) {
          return DateTime.fromMillisecondsSinceEpoch(intValue);
        }
      }
    } catch (e) {
      // Continue to fallback if string parsing fails
    }

    try {
      // If it's a double (seconds since epoch)
      if (value is double) {
        return DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
      }
    } catch (e) {
      // Continue to fallback if double conversion fails
    }

    // Fallback to current time
    // print('Warning: Could not parse timestamp value: $value, using current time');
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'isApproved': isApproved,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
      'lastTokenUpdate': lastTokenUpdate?.millisecondsSinceEpoch,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? profileImage,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    DateTime? lastTokenUpdate,
    String? vehicleType,
    String? vehicleNumber,
    double? rating,
    int? reviewCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      lastTokenUpdate: lastTokenUpdate ?? this.lastTokenUpdate,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
