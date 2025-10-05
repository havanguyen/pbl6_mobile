import 'package:flutter/material.dart';

class SnackbarService extends ChangeNotifier {
  String? _message;
  bool _isError = true;

  String? get message => _message;
  bool get isError => _isError;

  void showSuccess(String message) {
    _message = message;
    _isError = false;
    notifyListeners();
  }

  void showError(String message) {
    _message = message;
    _isError = true;
    notifyListeners();
  }

  void clear() {
    _message = null;
    notifyListeners();
  }
}