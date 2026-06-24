import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import 'firebase_service.dart';

class ReviewService {
  static const String collection = 'reviews';

  // Submit a review
  static Future<void> submitReview(ReviewModel review) async {
    final firestore = FirebaseService.firestore;
    final reviewRef = firestore.collection(collection).doc();
    final reviewWithId = ReviewModel(
      id: reviewRef.id,
      orderId: review.orderId,
      reviewerId: review.reviewerId,
      reviewerName: review.reviewerName,
      revieweeId: review.revieweeId,
      revieweeRole: review.revieweeRole,
      rating: review.rating,
      comment: review.comment,
      createdAt: DateTime.now(),
    );

    // Run transaction to ensure atomicity
    await firestore.runTransaction((transaction) async {
      // 1. Save Review
      transaction.set(reviewRef, reviewWithId.toMap());

      // 2. Update Order status (isHostReviewed or isVendorReviewed)
      final orderRef = FirebaseService.orders.doc(review.orderId);
      if (review.revieweeRole == 'vendor') {
        // Host reviewing Vendor
        transaction.update(orderRef, {'isVendorReviewed': true});
      } else {
        // Vendor reviewing Host
        transaction.update(orderRef, {'isHostReviewed': true});
      }

      // 3. Update Reviewee's Aggregate Rating
      DocumentReference userRef;
      if (review.revieweeRole == 'vendor') {
        // Updating Vendor's rating (in users collection)
        userRef = FirebaseService.users.doc(review.revieweeId);
      } else {
        // Updating Host's rating (in users collection)
        userRef = FirebaseService.users.doc(review.revieweeId);
      }

      final userDoc = await transaction.get(userRef);
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final currentRating = (data['rating'] ?? 0.0).toDouble();
        final currentCount = (data['reviewCount'] ?? 0) as int;

        final newCount = currentCount + 1;
        final newRating =
            ((currentRating * currentCount) + review.rating) / newCount;

        transaction.update(userRef, {
          'rating': newRating,
          'reviewCount': newCount,
        });
      }
    });
  }

  // Get reviews for a specific user (Host or Vendor)
  static Stream<List<ReviewModel>> getReviewsForUser(String userId) {
    return FirebaseService.firestore
        .collection(collection)
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
