import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:pbl6mobile/model/entities/review.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/services/store.dart';

class ReviewService {
  const ReviewService._();

  static final String? _baseUrl = dotenv.env['API_BASE_URL'];
  static final Dio _secureDio = _initializeSecureDio();

  static Dio _initializeSecureDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl!,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        logPrint: print,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
        ],
        retryableExtraStatuses: {status429TooManyRequests},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await Store.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            try {
              final refreshSuccess = await AuthService.refreshToken();
              if (refreshSuccess) {
                final newAccessToken = await Store.getAccessToken();
                e.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';
                final options = Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                );
                final response = await dio.request(
                  e.requestOptions.path,
                  options: options,
                  data: e.requestOptions.data,
                  queryParameters: e.requestOptions.queryParameters,
                );
                return handler.resolve(response);
              } else {
                await AuthService.logout();
              }
            } catch (err) {
              await AuthService.logout();
              return handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  error: err,
                  response: e.response,
                ),
              );
            }
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  static Future<GetReviewsResponse> getReviewsForDoctor({
    required String doctorId,
    int page = 1,
    int limit = 5,
  }) async {
    print('--- [DEBUG] Fetching Reviews ---');
    print('DoctorID: $doctorId');
    try {
      final params = {'page': page, 'limit': limit};
      // Use singular 'doctor' endpoint as confirmed by user success response
      final endpoint = '/reviews/doctor/$doctorId';
      print('Endpoint: $endpoint');

      final response = await _secureDio.get(endpoint, queryParameters: params);
      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final reviewList = (response.data['data'] as List)
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();
        print('Reviews found: ${reviewList.length}');
        return GetReviewsResponse(
          success: true,
          data: reviewList,
          meta: response.data['meta'] ?? {},
        );
      }
      print('Response Message: ${response.data['message']}');
      return GetReviewsResponse(
        success: false,
        message: response.data['message'] ?? 'API call failed',
      );
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      if (e.response != null) {
        print('DioException Data: ${e.response?.data}');
        print('DioException Status: ${e.response?.statusCode}');
      }
      return GetReviewsResponse(
        success: false,
        message: 'Lỗi kết nối: ${e.message}',
      );
    } catch (e) {
      print('Unknown Error: $e');
      return GetReviewsResponse(
        success: false,
        message: 'Đã xảy ra lỗi không mong muốn.',
      );
    }
  }

  static Future<bool> deleteReview(String reviewId) async {
    try {
      final response = await _secureDio.delete('/reviews/$reviewId');
      return response.statusCode == 200;
    } catch (e) {
      print('Delete Review Error: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
      }
      return false;
    }
  }
}
