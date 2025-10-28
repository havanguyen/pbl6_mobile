import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/entities/answer.dart';
import 'package:pbl6mobile/model/entities/question.dart';
// Sử dụng AuthService để lấy Dio instance đã được xác thực
import 'package:pbl6mobile/model/services/remote/auth_service.dart';

class QuestionService {
  // Lấy instance Dio đã cấu hình sẵn từ AuthService
  static final Dio _secureDio = AuthService.getSecureDioInstance();

  static Future<Map<String, dynamic>> getQuestions({
    int page = 1,
    int limit = 10,
    String? searchQuery,
    String? specialtyId,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final response = await _secureDio.get(
        '/questions',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (searchQuery != null && searchQuery.isNotEmpty)
            'search': searchQuery,
          if (specialtyId != null && specialtyId.isNotEmpty)
            'specialtyId': specialtyId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
          if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
        },
      );
      // Kiểm tra response trước khi parse
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<Question> questions = (response.data['data'] as List)
            .map((json) => Question.fromJson(json))
            .toList();
        final meta = response.data['meta'];
        return {'questions': questions, 'meta': meta};
      } else {
        // Ném lỗi nếu API trả về không thành công hoặc status code không phải 200
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['message'] ?? 'Lỗi không xác định từ API',
        );
      }
    } catch (e) {
      // Ném lại lỗi để ViewModel xử lý
      rethrow;
    }
  }

  static Future<Question> getQuestionDetail(String id) async {
    try {
      final response = await _secureDio.get('/questions/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Question.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['message'] ?? 'Không thể tải chi tiết câu hỏi',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> deleteQuestion(String id) async {
    try {
      // AuthService.verifyPassword đã được gọi trong ViewModel
      final response = await _secureDio.delete('/questions/$id');
      // API trả về 200 khi thành công
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      // Không cần ném lại lỗi, ViewModel sẽ lấy lỗi từ AuthService.verifyPassword nếu có
      return false;
    }
  }

  static Future<List<Answer>> getAnswers(String questionId,
      {int page = 1, int limit = 10}) async {
    try {
      final response = await _secureDio.get(
        '/questions/$questionId/answers',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((json) => Answer.fromJson(json))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['message'] ?? 'Không thể tải câu trả lời',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> deleteAnswer(String answerId) async {
    try {
      final response = await _secureDio.delete('/questions/answers/$answerId');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false; // Trả về false nếu có lỗi
    }
  }

  static Future<bool> acceptAnswer(String answerId) async {
    try {
      final response = await _secureDio.patch('/questions/answers/$answerId/accept');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false; // Trả về false nếu có lỗi
    }
  }
}