import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/review/review_analysis.dart';
import 'package:pbl6mobile/model/services/remote/review_service.dart';

class ReviewAnalysisVm extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCreating = false;
  bool get isCreating => _isCreating;

  List<ReviewAnalysisListItem> _analyses = [];
  List<ReviewAnalysisListItem> get analyses => _analyses;

  ReviewAnalysis? _currentAnalysis;
  ReviewAnalysis? get currentAnalysis => _currentAnalysis;

  String? _error;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setCreating(bool value) {
    _isCreating = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearCurrentAnalysis() {
    _currentAnalysis = null;
    notifyListeners();
  }

  Future<void> fetchAnalyses(
    String doctorId, {
    DateRangeType? dateRange,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _analyses = await ReviewService.listAnalyses(
        doctorId: doctorId,
        dateRange: dateRange,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAnalysisDetail(String id) async {
    _setLoading(true);
    _error = null;
    try {
      _currentAnalysis = await ReviewService.getAnalysisById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createAnalysis(CreateReviewAnalysisRequest request) async {
    _setCreating(true);
    _error = null;
    try {
      final newAnalysis = await ReviewService.createAnalysis(request);
      if (newAnalysis != null) {
        // Refresh the list after creation
        await fetchAnalyses(request.doctorId);
        // Set the newly created analysis as current
        _currentAnalysis = newAnalysis;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setCreating(false);
    }
  }
}
