import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/entities/answer.dart';
import 'package:pbl6mobile/model/entities/question.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/services/local/question_database_helper.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/model/services/remote/specialty_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../model/services/remote/question_service.dart.dart';

class QuestionVm extends ChangeNotifier {
  final QuestionDatabaseHelper _dbHelper = QuestionDatabaseHelper.instance;

  List<Question> questions = [];
  List<Specialty> specialties = [];
  Question? currentQuestion;
  List<Answer> currentAnswers = [];

  bool isLoading = false;
  bool isLoadingMore = false;
  bool isOffline = false;
  String? error;
  bool isLoadingSpecialties = false;
  String? specialtyError;

  bool hasNextPage = true;
  int _currentPage = 1;
  static const int _limit = 10;

  String? searchQuery;
  String? selectedStatus;
  String? selectedSpecialtyId;
  String sortBy = 'createdAt';
  String sortOrder = 'DESC';

  QuestionVm() {
    _checkConnectivity();
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      await _checkConnectivity();
      if (!isOffline && (questions.isEmpty || (error ?? '').contains('Lỗi kết nối'))) {
        fetchQuestions(forceRefresh: true);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final wasOffline = isOffline;
    isOffline = connectivityResult == ConnectivityResult.none;
    if (wasOffline && !isOffline && (error ?? '').contains('offline')) {
      error = null;
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void resetFilters() {
    searchQuery = null;
    selectedStatus = null;
    selectedSpecialtyId = null;
    sortBy = 'createdAt';
    sortOrder = 'DESC';
    fetchQuestions(forceRefresh: true);
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    fetchQuestions(forceRefresh: true);
  }

  void updateStatusFilter(String? status) {
    selectedStatus = status;
    fetchQuestions(forceRefresh: true);
  }

  void updateSpecialtyFilter(String? specialtyId) {
    selectedSpecialtyId = specialtyId;
    fetchQuestions(forceRefresh: true);
  }

  void updateSortFilter({String? sortBy, String? sortOrder}) {
    if (sortBy != null) this.sortBy = sortBy;
    if (sortOrder != null) this.sortOrder = sortOrder;
    fetchQuestions(forceRefresh: true);
  }

  String _handleDioError(DioException e, String contextMessage) {
    isOffline = e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown ||
        (e.message ?? '').contains('Failed host lookup');

    if (isOffline) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại.';
    } else if (e.response != null) {
      final apiMessage = e.response!.data is Map
          ? e.response!.data['message'] ?? e.message
          : e.message;
      return '$contextMessage: $apiMessage (Code: ${e.response?.statusCode})';
    } else {
      return '$contextMessage: ${e.message}';
    }
  }

  Future<void> fetchSpecialties({bool forceRefresh = false}) async {
    if (specialties.isNotEmpty && !forceRefresh) return;
    if (isLoadingSpecialties) return;

    isLoadingSpecialties = true;
    specialtyError = null;

    try {
      await _checkConnectivity();
      if (isOffline) {
        throw Exception('Bạn đang offline, không thể tải chuyên khoa.');
      }

      final response =
      await SpecialtyService.getAllSpecialties(limit: 100);
      if (response.success) {
        specialties = response.data;
        specialtyError = null;
      } else {
        throw Exception(response.message);
      }
    } on DioException catch (e) {
      specialtyError = _handleDioError(e, "Lỗi tải chuyên khoa");
    } catch (e) {
      specialtyError = 'Lỗi không mong muốn khi tải chuyên khoa: $e';
    } finally {
      isLoadingSpecialties = false;
      notifyListeners();
    }
  }

  Future<void> fetchQuestions({bool forceRefresh = false}) async {
    if ((isLoading || isLoadingMore) && !forceRefresh) return;
    if (!forceRefresh && !hasNextPage) return;

    await _checkConnectivity();

    if (forceRefresh) {
      _currentPage = 1;
      hasNextPage = true;
      isLoading = true;
      if (!isOffline || (error ?? '').contains('Lỗi kết nối') || (error ?? '').contains('offline')) {
        error = null;
      }
    } else {
      isLoadingMore = true;
    }
    notifyListeners();

    List<Question> cachedQuestions = [];
    if (isOffline) {
      try {
        cachedQuestions = await _dbHelper.getCachedQuestions();
        if (forceRefresh) {
          questions = cachedQuestions;
        }
        hasNextPage = false;
      } catch (e) {
        error = "Lỗi đọc dữ liệu offline: $e";
      }

      error = cachedQuestions.isEmpty
          ? 'Bạn đang offline và không có dữ liệu.'
          : 'Bạn đang offline. Đang hiển thị dữ liệu cũ.';

      isLoading = false;
      isLoadingMore = false;
      notifyListeners();
      return;
    }

    try {
      final response = await QuestionService.getQuestions(
        page: _currentPage,
        limit: _limit,
        searchQuery: searchQuery,
        specialtyId: selectedSpecialtyId,
        status: selectedStatus,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      final newQuestions = response['questions'] as List<Question>;
      final meta = response['meta'];
      hasNextPage = meta['hasNext'] ?? false;

      if (forceRefresh) {
        questions = newQuestions;
        await _dbHelper.clearQuestions();
        await _dbHelper.batchInsertQuestions(newQuestions);
      } else {
        questions.addAll(newQuestions);
      }

      if (newQuestions.isNotEmpty || meta['total'] == 0) {
        _currentPage++;
      }
      error = null;

    } on DioException catch (e) {
      error = _handleDioError(e, "Lỗi tải danh sách câu hỏi");
      hasNextPage = false;
      if (isOffline && forceRefresh) {
        try {
          cachedQuestions = await _dbHelper.getCachedQuestions();
          questions = cachedQuestions;
          error = cachedQuestions.isEmpty
              ? 'Lỗi kết nối mạng và không có dữ liệu cache.'
              : 'Lỗi kết nối mạng. Đang hiển thị dữ liệu cũ.';
        } catch (dbError) {
          error = "Lỗi kết nối mạng và lỗi đọc cache: $dbError";
        }
      }

    } catch (e) {
      error = 'Lỗi không mong muốn khi tải câu hỏi: $e';
      hasNextPage = false;
    } finally {
      isLoading = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!isLoading && !isLoadingMore && !isOffline && hasNextPage) {
      await fetchQuestions();
    }
  }

  Future<bool> deleteQuestion(String id, String password) async {
    await _checkConnectivity();
    if (isOffline) {
      error = 'Không thể xóa khi offline';
      notifyListeners();
      return false;
    }

    bool verifySuccess = false;
    try {
      verifySuccess = await AuthService.verifyPassword(password: password);
      if (!verifySuccess) {
        error = 'Mật khẩu không chính xác.';
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      error = _handleDioError(e, "Lỗi xác thực mật khẩu");
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Lỗi không mong muốn khi xác thực: $e';
      notifyListeners();
      return false;
    }

    try {
      final deleteSuccess = await QuestionService.deleteQuestion(id);
      if (deleteSuccess) {
        questions.removeWhere((q) => q.id == id);
        error = null;
        notifyListeners();
        await _dbHelper.clearQuestions();
        await _dbHelper.batchInsertQuestions(questions);
        return true;
      } else {
        error = 'Xóa câu hỏi thất bại từ phía server.';
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      error = _handleDioError(e, "Lỗi xóa câu hỏi");
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Lỗi không mong muốn khi xóa: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchQuestionDetail(String id) async {
    isLoading = true;
    currentQuestion = null;
    error = null;
    notifyListeners();

    try {
      await _checkConnectivity();
      if (isOffline) {
        throw Exception('Bạn đang offline, không thể tải chi tiết.');
      } else {
        currentQuestion = await QuestionService.getQuestionDetail(id);
      }
      error = null;
    } on DioException catch (e) {
      error = _handleDioError(e, "Lỗi tải chi tiết câu hỏi");
    } catch (e) {
      error = 'Lỗi không mong muốn khi tải chi tiết: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnswers(String questionId) async {
    if (currentQuestion == null) return;

    isLoading = true;
    currentAnswers.clear();
    notifyListeners();

    try {
      await _checkConnectivity();
      if (isOffline) {
        throw Exception('Bạn đang offline, không thể tải câu trả lời.');
      } else {
        currentAnswers = await QuestionService.getAnswers(questionId, limit: 100);
        if (error == null || error!.contains('câu trả lời') || error!.contains('offline')) {
          error = null;
        }
      }
    } on DioException catch (e) {
      if (error == null) {
        error = _handleDioError(e, "Lỗi tải câu trả lời");
      }
    } catch (e) {
      if (error == null) {
        error = 'Lỗi không mong muốn khi tải câu trả lời: $e';
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> deleteAnswer(String answerId) async {
    await _checkConnectivity();
    if (isOffline) {
      error = 'Không thể xóa khi offline';
      notifyListeners();
      return false;
    }
    try {
      final success = await QuestionService.deleteAnswer(answerId);
      if (success && currentQuestion != null) {
        await fetchAnswers(currentQuestion!.id);
      } else if (!success) {
        error = 'Xóa câu trả lời thất bại từ phía server.';
        notifyListeners();
      }
      return success;
    } on DioException catch (e) {
      error = _handleDioError(e, "Lỗi xóa câu trả lời");
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Lỗi không mong muốn khi xóa câu trả lời: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptAnswer(String answerId) async {
    await _checkConnectivity();
    if (isOffline) {
      error = 'Không thể duyệt khi offline';
      notifyListeners();
      return false;
    }
    try {
      final success = await QuestionService.acceptAnswer(answerId);
      if (success && currentQuestion != null) {
        await fetchAnswers(currentQuestion!.id);
      } else if (!success) {
        error = 'Duyệt câu trả lời thất bại từ phía server.';
        notifyListeners();
      }
      return success;
    } on DioException catch (e) {
      error = _handleDioError(e, "Lỗi duyệt câu trả lời");
      notifyListeners();
      return false;
    } catch (e) {
      error = 'Lỗi không mong muốn khi duyệt câu trả lời: $e';
      notifyListeners();
      return false;
    }
  }
}