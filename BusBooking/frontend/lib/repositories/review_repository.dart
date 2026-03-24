import '../models/mock_data.dart';
import '../services/api_client.dart';

class ReviewRepository {
  ReviewRepository._();
  static final ReviewRepository instance = ReviewRepository._();

  /// Get reviews for a bus company
  Future<List<Review>> getCompanyReviews(int companyId) async {
    final res = await ApiClient.instance.get('/review/buscompany/$companyId');
    final list = res['data'] ?? res;
    return (list as List)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new review
  Future<Review> createReview({
    required int busCompanyId,
    required int rating,
    required String comment,
  }) async {
    final res = await ApiClient.instance.post('/review', body: {
      'busCompanyId': busCompanyId,
      'rating': rating,
      'comment': comment,
    });
    final data = res['data'] ?? res;
    return Review.fromJson(data as Map<String, dynamic>);
  }

  /// Update an existing review
  Future<Review> updateReview({
    required int reviewId,
    required int busCompanyId,
    required int rating,
    required String comment,
  }) async {
    final res = await ApiClient.instance.put('/review/$reviewId', body: {
      'busCompanyId': busCompanyId,
      'rating': rating,
      'comment': comment,
    });
    final data = res['data'] ?? res['review'] ?? res;
    return Review.fromJson(data as Map<String, dynamic>);
  }

  /// Delete a review
  Future<void> deleteReview(int reviewId) async {
    await ApiClient.instance.delete('/review/$reviewId');
  }
}
