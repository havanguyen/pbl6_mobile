import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/review.dart';
import 'package:pbl6mobile/model/services/remote/review_service.dart';

class ReviewVm extends ChangeNotifier {
  final String doctorId;

  List<Review> _reviews = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  final int _limit = 10;
  Map<String, dynamic> _meta = {};

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasNext => _meta['hasNext'] ?? false;

  ReviewVm({required this.doctorId}) {
    fetchReviews(forceRefresh: true);
  }

  Future<void> fetchReviews({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _currentPage = 1;
      _meta = {};
      _reviews = [];
      _isLoading = true;
    } else {
      if (_isLoading || _isLoadingMore || !hasNext) return;
      _isLoadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final result = await ReviewService.getReviewsForDoctor(
        doctorId: doctorId,
        page: _currentPage,
        limit: _limit,
      );

      if (result.success) {
        if (forceRefresh) {
          _reviews = result.data;
        } else {
          _reviews.addAll(result.data);
        }
        _meta = result.meta;
        _currentPage++;
      } else {
        _error = result.message;
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreReviews() async {
    if (hasNext && !_isLoading && !_isLoadingMore) {
      await fetchReviews();
    }
  }

  Future<bool> deleteReview(String reviewId) async {
    _error = null;
    notifyListeners();
    bool success = false;
    try {
      success = await ReviewService.deleteReview(reviewId);
      if (success) {
        _reviews.removeWhere((review) => review.id == reviewId);
      } else {
        _error = "Xóa đánh giá thất bại.";
      }
    } catch (e) {
      _error = "Lỗi khi xóa đánh giá: $e";
      success = false;
    }
    notifyListeners();
    return success;
  }
}