import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/entities/answer.dart';
import 'package:pbl6mobile/model/entities/question.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';

class QuestionService {
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
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<Question> questions = (response.data['data'] as List)
            .map((json) => Question.fromJson(json))
            .toList();
        final meta = response.data['meta'];
        return {'questions': questions, 'meta': meta};
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['message'] ?? 'Lỗi không xác định từ API',
        );
      }
    } catch (e) {
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
      final response = await _secureDio.delete('/questions/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
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
      return false;
    }
  }

  static Future<bool> acceptAnswer(String answerId) async {
    try {
      final response = await _secureDio.patch('/questions/answers/$answerId/accept');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<Question> updateQuestion(String questionId, Map<String, dynamic> data) async {
    try {
      final response = await _secureDio.patch(
        '/questions/$questionId',
        data: data,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Question.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['message'] ?? 'Cập nhật câu hỏi thất bại',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Answer> postAnswer(String questionId, String body) async {
    try {
      final response = await _secureDio.post(
        '/questions/$questionId/answers',
        data: {'body': body},
      );
      return Answer.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Answer> updateAnswer(String answerId, String body) async {
    try {
      final response = await _secureDio.patch(
        '/questions/answers/$answerId',
        data: {'body': body},
      );
      return Answer.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}