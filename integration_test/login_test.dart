import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart'; // Import Store để xóa token

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kiem thu luong dang nhap tu dong', (WidgetTester tester) async {
    // 1. Xóa dữ liệu cũ để đảm bảo app luôn bắt đầu ở trạng thái chưa đăng nhập
    // (Cần khởi tạo binding trước khi gọi Store nếu Store dùng MethodChannel)
    await Store.clearStorage();

    // 2. Khởi chạy App
    await app.main();

    // 3. QUAN TRỌNG: Chờ 3 giây để Splash Screen chạy xong và chuyển trang
    // pumpAndSettle mặc định có thể bị timeout hoặc return sớm, nên dùng pump với duration cụ thể
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(); // Chờ nốt các hiệu ứng chuyển trang (Navigation transition)

    // 4. Tìm các Widget
    final emailField = find.byKey(const ValueKey('login_email_field'));
    final passwordField = find.byKey(const ValueKey('login_password_field'));
    final loginButton = find.byKey(const ValueKey('login_button'));

    // Kiểm tra xem đã thực sự ở màn hình Login chưa trước khi thao tác
    expect(emailField, findsOneWidget, reason: "Khong tim thay o nhap Email, co the van dang o Splash hoac da vao thang Main");

    // 5. Thực hiện nhập liệu
    await tester.enterText(emailField, 'test@gmail.com');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.enterText(passwordField, '123456');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(loginButton);

    // 6. Chờ kết quả đăng nhập (API call)
    // Tăng thời gian chờ lên 5-10s tùy vào tốc độ mạng/server của bạn
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Kiểm tra không còn lỗi hiển thị (hoặc kiểm tra đã chuyển sang màn hình Dashboard)
    expect(find.text('Đăng nhập thất bại. Vui lòng kiểm tra email và mật khẩu.'), findsNothing);
  });
}