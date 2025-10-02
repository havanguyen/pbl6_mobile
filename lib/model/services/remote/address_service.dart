import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressService {
  const AddressService._();
  static const AddressService instance = AddressService._();

  static const String _baseUrl = 'https://esgoo.net/api-tinhthanh';

  static Future<Map<String, dynamic>> getProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/1/0.htm'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': json['error'] == 0,
          'data': json['error'] == 0 ? json['data'] : [],
          'message': json['error'] != 0 ? json['message'] : null,
        };
      } else {
        return {
          'success': false,
          'data': [],
          'message': 'Lỗi kết nối: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'message': 'Lỗi: $e',
      };
    }
  }
  static Future<Map<String, dynamic>> getDistricts(String provinceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/2/$provinceId.htm'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': json['error'] == 0,
          'data': json['error'] == 0 ? json['data'] : [],
          'message': json['error'] != 0 ? json['message'] : null,
        };
      } else {
        return {
          'success': false,
          'data': [],
          'message': 'Lỗi kết nối: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'message': 'Lỗi: $e',
      };
    }
  }
  static Future<Map<String, dynamic>> getWards(String districtId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/3/$districtId.htm'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': json['error'] == 0,
          'data': json['error'] == 0 ? json['data'] : [],
          'message': json['error'] != 0 ? json['message'] : null,
        };
      } else {
        return {
          'success': false,
          'data': [],
          'message': 'Lỗi kết nối: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'message': 'Lỗi: $e',
      };
    }
  }
  static Future<Map<String, dynamic>> getAddressByLevel(int level, String parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$level/$parentId.htm'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'success': json['error'] == 0,
          'data': json['error'] == 0 ? json['data'] : [],
          'message': json['error'] != 0 ? json['message'] : null,
        };
      } else {
        return {
          'success': false,
          'data': [],
          'message': 'Lỗi kết nối: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'message': 'Lỗi: $e',
      };
    }
  }
}