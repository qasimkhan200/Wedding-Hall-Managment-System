import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

enum OrderStatus {
  pending,
  vendorAccepted,
  riderAssigned,
  inTransit,
  delivered,
  cancelled,
  delayed,
  failed,
}

class OrderModel {
  final String id;
  final String hostId;
  final String hostName;
  final String hostPhone;
  final String vendorId;
  final String vendorName;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String status;

  // Status Helper
  OrderStatus get orderStatus {
    try {
      return OrderStatus.values.firstWhere(
          (e) =>
              e.toString().split('.').last == status ||
              (status == 'vendor_accepted' &&
                  e == OrderStatus.vendorAccepted) ||
              (status == 'rider_assigned' && e == OrderStatus.riderAssigned) ||
              (status == 'in_transit' && e == OrderStatus.inTransit),
          orElse: () => OrderStatus.pending);
    } catch (_) {
      return OrderStatus.pending;
    }
  }

  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final double? riderLatitude;
  final double? riderLongitude;
  final String? specialInstructions;
  final int estimatedDeliveryMinutes;
  final DateTime? estimatedDeliveryTime;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? proofOfDeliveryImage;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String category; // Added category

  // Admin / Emergency Fields
  final bool isEmergency;
  final int? slaMinutes;
  final double commissionAmount;
  final double riderFee;
  final double platformFee;
  final List<Map<String, dynamic>> timelineEvents;
  final String requiredVehicle;
  final double estimatedDistanceKm;
  final bool isHostReviewed;
  final bool isVendorReviewed;

  OrderModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostPhone,
    required this.vendorId,
    required this.vendorName,
    this.riderId,
    this.riderName,
    this.riderPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.status,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.riderLatitude,
    this.riderLongitude,
    this.specialInstructions,
    this.estimatedDeliveryMinutes = 30,
    this.estimatedDeliveryTime,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.proofOfDeliveryImage,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.isEmergency = false,
    this.slaMinutes,
    this.commissionAmount = 0.0,
    this.riderFee = 0.0,
    this.platformFee = 0.0,
    this.timelineEvents = const [],
    this.category = 'General',
    this.requiredVehicle = 'bike',
    this.estimatedDistanceKm = 0.0,
    this.isHostReviewed = false,
    this.isVendorReviewed = false,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      hostPhone: map['hostPhone'] ?? '',
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      riderId: map['riderId'],
      riderName: map['riderName'],
      riderPhone: map['riderPhone'],
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => CartItemModel.fromMap(item))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      deliveryAddress: map['deliveryAddress'] ?? '',
      deliveryLatitude: (map['deliveryLatitude'] ?? 0.0).toDouble(),
      deliveryLongitude: (map['deliveryLongitude'] ?? 0.0).toDouble(),
      riderLatitude: map['riderLatitude']?.toDouble(),
      riderLongitude: map['riderLongitude']?.toDouble(),
      specialInstructions: map['specialInstructions'],
      estimatedDeliveryMinutes: map['estimatedDeliveryMinutes'] ?? 30,
      estimatedDeliveryTime: _parseDateTime(map['estimatedDeliveryTime']),
      acceptedAt: _parseDateTime(map['acceptedAt']),
      pickedUpAt: _parseDateTime(map['pickedUpAt']),
      deliveredAt: _parseDateTime(map['deliveredAt']),
      proofOfDeliveryImage: map['proofOfDeliveryImage'],
      cancellationReason: map['cancellationReason'],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      isEmergency: map['isEmergency'] ?? false,
      slaMinutes: map['slaMinutes'],
      commissionAmount: (map['commissionAmount'] ?? 0.0).toDouble(),
      riderFee: (map['riderFee'] ?? 0.0).toDouble(),
      platformFee: (map['platformFee'] ?? 0.0).toDouble(),
      timelineEvents:
          List<Map<String, dynamic>>.from(map['timelineEvents'] ?? []),
      requiredVehicle: map['requiredVehicle'] ?? 'bike',
      estimatedDistanceKm: (map['estimatedDistanceKm'] ?? 0.0).toDouble(),
      isHostReviewed: map['isHostReviewed'] ?? false,
      isVendorReviewed: map['isVendorReviewed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'hostPhone': hostPhone,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'riderLatitude': riderLatitude,
      'riderLongitude': riderLongitude,
      'specialInstructions': specialInstructions,
      'estimatedDeliveryMinutes': estimatedDeliveryMinutes,
      'estimatedDeliveryTime': estimatedDeliveryTime?.millisecondsSinceEpoch,
      'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
      'pickedUpAt': pickedUpAt?.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'proofOfDeliveryImage': proofOfDeliveryImage,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isEmergency': isEmergency,
      'slaMinutes': slaMinutes,
      'commissionAmount': commissionAmount,
      'riderFee': riderFee,
      'platformFee': platformFee,
      'timelineEvents': timelineEvents,
      'category': category,
      'requiredVehicle': requiredVehicle,
      'estimatedDistanceKm': estimatedDistanceKm,
      'isHostReviewed': isHostReviewed,
      'isVendorReviewed': isVendorReviewed,
    };
  }

  OrderModel copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? hostPhone,
    String? vendorId,
    String? vendorName,
    String? riderId,
    String? riderName,
    String? riderPhone,
    List<CartItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? totalAmount,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? riderLatitude,
    double? riderLongitude,
    String? specialInstructions,
    int? estimatedDeliveryMinutes,
    DateTime? estimatedDeliveryTime,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? proofOfDeliveryImage,
    String? cancellationReason,
    DateTime? createdAt,
    // DateTime? createdAt, // removed duplicate
    DateTime? updatedAt,
    bool? isEmergency,
    int? slaMinutes,
    double? commissionAmount,
    double? riderFee,
    double? platformFee,
    List<Map<String, dynamic>>? timelineEvents,
    String? category,
    String? requiredVehicle,
    double? estimatedDistanceKm,
    bool? isHostReviewed,
    bool? isVendorReviewed,
  }) {
    return OrderModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostPhone: hostPhone ?? this.hostPhone,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      riderLatitude: riderLatitude ?? this.riderLatitude,
      riderLongitude: riderLongitude ?? this.riderLongitude,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      estimatedDeliveryMinutes:
          estimatedDeliveryMinutes ?? this.estimatedDeliveryMinutes,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      proofOfDeliveryImage: proofOfDeliveryImage ?? this.proofOfDeliveryImage,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmergency: isEmergency ?? this.isEmergency,
      slaMinutes: slaMinutes ?? this.slaMinutes,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      riderFee: riderFee ?? this.riderFee,
      platformFee: platformFee ?? this.platformFee,
      timelineEvents: timelineEvents ?? this.timelineEvents,
      category: category ?? this.category,
      requiredVehicle: requiredVehicle ?? this.requiredVehicle,
      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
      isHostReviewed: isHostReviewed ?? this.isHostReviewed,
      isVendorReviewed: isVendorReviewed ?? this.isVendorReviewed,
    );
  }

  // Helper method to parse DateTime from various formats (same as UserModel)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    // If it's already a DateTime
    if (value is DateTime) return value;

    // If it's a Firestore Timestamp
    try {
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
    } catch (e) {
      // Continue to other checks if Timestamp conversion fails
    }

    // If it's an integer (milliseconds since epoch)
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    // If it's a string representation of milliseconds
    if (value is String) {
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return DateTime.fromMillisecondsSinceEpoch(intValue);
      }
    }

    // Return null if parsing fails
    return null;
  }
}
