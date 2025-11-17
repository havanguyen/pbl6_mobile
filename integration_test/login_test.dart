import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Hàm hỗ trợ: Khởi động lại app và xóa cache trước mỗi test case
  Future<void> restartApp(WidgetTester tester) async {
    print('--- [SETUP] Cleaning Storage & Restarting App ---');
    await Store.clearStorage(); // Xóa Token
    await Store.clear();        // Xóa SharedPreferences

    await app.main();           // Khởi chạy hàm main()
    await tester.pumpAndSettle(); // Chờ render frame đầu tiên

    // Chờ Splash Screen (Giả sử splash 3s + buffer 2s)
    print('--- [SETUP] Waiting for Splash Screen... ---');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  group('Kiểm thử chức năng Login (Theo Test Report HMS-2025)', () {

    // --- TC004: Để trống email hoặc mật khẩu ---
    testWidgets('TC004: Kiểm tra validation khi để trống trường nhập liệu', (WidgetTester tester) async {
      await restartApp(tester);

      print('--- [TC004] Bắt đầu ---');
      final loginButton = find.byKey(const ValueKey('login_button'));

      // Đảm bảo đang ở màn login
      expect(find.byKey(const ValueKey('login_email_field')), findsOneWidget);

      print('--- [TC004] Click Đăng nhập mà không nhập liệu ---');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      print('--- [TC004] Kiểm tra thông báo lỗi validator ---');
      // Dựa vào code LoginPage: 'Vui lòng nhập email' và 'Vui lòng nhập mật khẩu'
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);

      print('--- [TC004] PASSED ---');
    });

    // --- TC005: Email sai định dạng ---
    testWidgets('TC005: Kiểm tra validation khi email sai định dạng', (WidgetTester tester) async {
      await restartApp(tester);

      print('--- [TC005] Bắt đầu ---');
      final emailField = find.byKey(const ValueKey('login_email_field'));
      final passwordField = find.byKey(const ValueKey('login_password_field'));
      final loginButton = find.byKey(const ValueKey('login_button'));

      print('--- [TC005] Nhập email sai định dạng "nguyen123" ---');
      await tester.enterText(emailField, 'nguyen123');
      await tester.enterText(passwordField, 'Matkhau123'); // Mật khẩu đúng format để không bị lỗi pass
      await tester.pumpAndSettle();

      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      print('--- [TC005] Kiểm tra thông báo lỗi ---');
      // Dựa vào code LoginPage: 'Email không đúng định dạng'
      expect(find.text('Email không đúng định dạng'), findsOneWidget);

      print('--- [TC005] PASSED ---');
    });

    // --- TC002 & TC003: Đăng nhập thất bại (API trả về lỗi) ---
    testWidgets('TC002/TC003: Kiểm tra báo lỗi từ API khi sai tài khoản', (WidgetTester tester) async {
      await restartApp(tester);

      print('--- [TC002/TC003] Bắt đầu ---');
      final emailField = find.byKey(const ValueKey('login_email_field'));
      final passwordField = find.byKey(const ValueKey('login_password_field'));
      final loginButton = find.byKey(const ValueKey('login_button'));

      print('--- [TC002] Nhập email chưa tồn tại/sai pass ---');
      // Sử dụng data từ Test Report
      await tester.enterText(emailField, 'khongconguyen@gmail.com');
      await tester.enterText(passwordField, 'nguyen902993');
      await tester.pumpAndSettle();

      await tester.tap(loginButton);

      // Chờ API phản hồi (Giả sử network delay 2-3s)
      print('--- [TC002] Chờ API phản hồi... ---');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      print('--- [TC002] Kiểm tra Dialog báo lỗi ---');
      // Dựa vào code LoginPage: _showErrorDialog('Đăng nhập thất bại...')
      expect(find.text('Lỗi'), findsOneWidget);
      expect(find.text('Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.'), findsOneWidget);

      // Đóng dialog để kết thúc test sạch sẽ
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      print('--- [TC002/TC003] PASSED ---');
    });

    // --- TC001: Đăng nhập thành công ---
    testWidgets('TC001: Đăng nhập thành công và chuyển trang', (WidgetTester tester) async {
      await restartApp(tester);

      print('--- [TC001] Bắt đầu ---');
      final emailField = find.byKey(const ValueKey('login_email_field'));
      final passwordField = find.byKey(const ValueKey('login_password_field'));
      final loginButton = find.byKey(const ValueKey('login_button'));

      print('--- [TC001] Nhập tài khoản hợp lệ (Từ Test Report) ---');
      // LƯU Ý: Cần đảm bảo tài khoản này TỒN TẠI trong Database thật
      // hoặc bạn phải Mock AuthService nếu server chưa chạy.
      await tester.enterText(emailField, 'superadmin@medicalink.com');
      await tester.enterText(passwordField, 'SuperAdmin123!');
      await tester.pumpAndSettle();

      await tester.tap(loginButton);

      print('--- [TC001] Chờ API và chuyển trang... ---');
      // Thời gian chờ dài hơn cho luồng success (lưu token + navigate)
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      print('--- [TC001] Kiểm tra kết quả ---');
      // Kiểm tra xem Dialog lỗi có xuất hiện không (nếu có là Failed)
      if (find.text('Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.').evaluate().isNotEmpty) {
        print('!!! [TC001] FAILED: Đăng nhập thất bại do sai tài khoản hoặc lỗi Server !!!');
        fail('API trả về lỗi đăng nhập');
      }

      // Kiểm tra xem đã thoát màn hình Login chưa
      expect(find.byKey(const ValueKey('login_button')), findsNothing, reason: "Vẫn còn ở màn hình Login");

      // Kiểm tra màn hình tiếp theo (Ví dụ tìm 1 text hoặc icon ở trang chủ)
      // Bạn có thể uncomment dòng dưới nếu biết chắc chắn UI trang chủ có gì
      // expect(find.text('Trang chủ'), findsOneWidget);

      print('--- [TC001] PASSED ---');
    });
  });
}