class HostModel {
  final String id;
  final String userId;
  final String propertyName;
  final String propertyAddress;
  final double latitude;
  final double longitude;
  final List<String> propertyImages;
  final String? description;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  HostModel({
    required this.id,
    required this.userId,
    required this.propertyName,
    required this.propertyAddress,
    required this.latitude,
    required this.longitude,
    required this.propertyImages,
    this.description,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HostModel.fromMap(Map<String, dynamic> map, String id) {
    return HostModel(
      id: id,
      userId: map['userId'] ?? '',
      propertyName: map['propertyName'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      propertyImages: List<String>.from(map['propertyImages'] ?? []),
      description: map['description'],
      isVerified: map['isVerified'] ?? false,
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
      'propertyName': propertyName,
      'propertyAddress': propertyAddress,
      'latitude': latitude,
      'longitude': longitude,
      'propertyImages': propertyImages,
      'description': description,
      'isVerified': isVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  HostModel copyWith({
    String? id,
    String? userId,
    String? propertyName,
    String? propertyAddress,
    double? latitude,
    double? longitude,
    List<String>? propertyImages,
    String? description,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      propertyImages: propertyImages ?? this.propertyImages,
      description: description ?? this.description,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
