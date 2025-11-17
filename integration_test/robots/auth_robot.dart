import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class AuthRobot {
  final WidgetTester tester;

  AuthRobot(this.tester);

  // Các Key phải khớp chính xác với LoginPage
  final _emailFieldFinder = find.byKey(const ValueKey('login_email_field'));
  final _passwordFieldFinder = find.byKey(const ValueKey('login_password_field'));
  final _loginButtonFinder = find.byKey(const ValueKey('login_button'));

  Future<void> enterEmail(String email) async {
    // Đảm bảo Widget đã xuất hiện trước khi tương tác
    await tester.ensureVisible(_emailFieldFinder);
    await tester.enterText(_emailFieldFinder, email);
    await tester.pump();
  }

  Future<void> enterPassword(String password) async {
    await tester.ensureVisible(_passwordFieldFinder);
    await tester.enterText(_passwordFieldFinder, password);
    await tester.pump();
  }

  Future<void> tapLoginButton() async {
    await tester.ensureVisible(_loginButtonFinder);
    await tester.tap(_loginButtonFinder);
    // Pump để kích hoạt animation và logic
    await tester.pumpAndSettle();
  }

  Future<void> expectErrorDialogVisible() async {
    // Chờ một chút để Dialog hiển thị hoàn toàn
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Lỗi'), findsOneWidget);
    expect(find.text('Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.'), findsOneWidget);
  }

  Future<void> dismissErrorDialog() async {
    final okButton = find.text('OK');
    await tester.tap(okButton);
    await tester.pumpAndSettle(); // Chờ dialog đóng hẳn
  }

  Future<void> expectValidationError(String message) async {
    // Tìm text lỗi trong validator
    expect(find.text(message), findsOneWidget);
  }

  Future<void> expectLoginSuccess() async {
    // Chờ chuyển trang hoàn tất
    await tester.pumpAndSettle();
    // Kiểm tra nút Login không còn tồn tại (nghĩa là đã chuyển trang)
    expect(_loginButtonFinder, findsNothing, reason: "Lỗi: Vẫn còn ở màn hình Login");
  }
}