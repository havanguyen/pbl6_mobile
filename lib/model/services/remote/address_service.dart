import 'dart:convert';

import 'package:dio/dio.dart';

class AddressService {
  const AddressService._();
  static const AddressService instance = AddressService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://esgoo.net/api-tinhthanh',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode == 200) {
      final json = response.data;
      final data = (json is String) ? jsonDecode(json) : json;
      final bool isSuccess = data['error'] == 0;
      return {
        'success': isSuccess,
        'data': isSuccess ? data['data'] : [],
        'message': !isSuccess ? data['message'] : null,
      };
    } else {
      return {
        'success': false,
        'data': [],
        'message': 'Lỗi kết nối: ${response.statusCode}',
      };
    }
  }

  static Map<String, dynamic> _handleError(e) {
    String errorMessage = 'Lỗi không xác định: $e';
    if (e is DioException) {
      errorMessage = 'Lỗi Dio: ${e.message}';
    }
    return {
      'success': false,
      'data': [],
      'message': errorMessage,
    };
  }

  static Future<Map<String, dynamic>> getProvinces() async {
    return getAddressByLevel(1, '0');
  }

  static Future<Map<String, dynamic>> getDistricts(String provinceId) async {
    return getAddressByLevel(2, provinceId);
  }

  static Future<Map<String, dynamic>> getWards(String districtId) async {
    return getAddressByLevel(3, districtId);
  }

  static Future<Map<String, dynamic>> getAddressByLevel(int level, String parentId) async {
    try {
      final response = await _dio.get('/$level/$parentId.htm');
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
}