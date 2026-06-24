import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String orderId;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final String revieweeRole; // 'host' or 'vendor'
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.revieweeRole,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      orderId: map['orderId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      revieweeId: map['revieweeId'] ?? '',
      revieweeRole: map['revieweeRole'] ?? 'vendor',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'revieweeId': revieweeId,
      'revieweeRole': revieweeRole,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
