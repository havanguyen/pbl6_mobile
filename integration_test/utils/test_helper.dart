import 'dart:convert';
import 'package:flutter/services.dart';

class TestHelper {
  static final TestHelper _instance = TestHelper._internal();
  Map<String, dynamic>? _data;

  factory TestHelper() {
    return _instance;
  }

  TestHelper._internal();

  Future<void> loadData() async {
    if (_data != null) return;
    final String response = await rootBundle.loadString('assets/data/test_data.json');
    _data = json.decode(response);
  }

  List<dynamic> getLoginTests() {
    return _data?['login_tests'] ?? [];
  }

  Map<String, dynamic> getTestCase(String section, String caseId) {
    final List<dynamic> tests = _data?[section] ?? [];
    return tests.firstWhere(
          (element) => element['caseId'] == caseId,
      orElse: () => {},
    );
  }
}