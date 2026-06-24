import 'package:cloud_firestore/cloud_firestore.dart';

class RiderAssignmentModel {
  final String id;
  final String orderId;
  final String vendorId;
  final String riderId;
  final String riderName;
  final String riderPhone;
  final String
      status; // 'assigned', 'accepted', 'picked_up', 'delivered', 'cancelled'
  final double deliveryFee;
  final String? specialInstructions;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? cancellationReason;
  final double? riderLatitude;
  final double? riderLongitude;
  final int estimatedMinutes;

  RiderAssignmentModel({
    required this.id,
    required this.orderId,
    required this.vendorId,
    required this.riderId,
    required this.riderName,
    required this.riderPhone,
    required this.status,
    required this.deliveryFee,
    this.specialInstructions,
    required this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancellationReason,
    this.riderLatitude,
    this.riderLongitude,
    this.estimatedMinutes = 30,
  });

  factory RiderAssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    return RiderAssignmentModel(
      id: id,
      orderId: map['orderId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      riderId: map['riderId'] ?? '',
      riderName: map['riderName'] ?? '',
      riderPhone: map['riderPhone'] ?? '',
      status: map['status'] ?? 'assigned',
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      specialInstructions: map['specialInstructions'],
      assignedAt: _parseDateTime(map['assignedAt']) ?? DateTime.now(),
      acceptedAt: _parseDateTime(map['acceptedAt']),
      pickedUpAt: _parseDateTime(map['pickedUpAt']),
      deliveredAt: _parseDateTime(map['deliveredAt']),
      cancellationReason: map['cancellationReason'],
      riderLatitude: map['riderLatitude']?.toDouble(),
      riderLongitude: map['riderLongitude']?.toDouble(),
      estimatedMinutes: map['estimatedMinutes'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'vendorId': vendorId,
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'status': status,
      'deliveryFee': deliveryFee,
      'specialInstructions': specialInstructions,
      'assignedAt': assignedAt.millisecondsSinceEpoch,
      'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
      'pickedUpAt': pickedUpAt?.millisecondsSinceEpoch,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'cancellationReason': cancellationReason,
      'riderLatitude': riderLatitude,
      'riderLongitude': riderLongitude,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    try {
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
    } catch (e) {
      // Continue to other checks
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return null;
  }

  RiderAssignmentModel copyWith({
    String? id,
    String? orderId,
    String? vendorId,
    String? riderId,
    String? riderName,
    String? riderPhone,
    String? status,
    double? deliveryFee,
    String? specialInstructions,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? cancellationReason,
    double? riderLatitude,
    double? riderLongitude,
    int? estimatedMinutes,
  }) {
    return RiderAssignmentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      vendorId: vendorId ?? this.vendorId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      status: status ?? this.status,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      riderLatitude: riderLatitude ?? this.riderLatitude,
      riderLongitude: riderLongitude ?? this.riderLongitude,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }
}
