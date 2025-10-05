

import 'dart:convert';

import 'package:http/http.dart' as http;

class GlobalException {
  const GlobalException._();
  static const GlobalException instance = GlobalException._();
  static Future<Map<String, dynamic>> safeApiCall(Future<http.Response> Function() call) async {
    try {
      final response = await call();
      if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too many requests. Please try again later.',
        };
      }
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

}