import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import 'package:pbl6mobile/view/auth/login_page.dart'; // Import Login Page để check type
import '../robots/auth_robot.dart';
import '../robots/admin_management_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setupAppAndLogin(WidgetTester tester) async {
    // 1. Reset dữ liệu
    await Store.clearStorage();
    await Store.clear();

    // 2. Khởi động App
    await app.main();
    await tester.pumpAndSettle(); // Frame đầu tiên (Splash Screen hiện ra)

    // 3. Xử lý Splash Screen (SplashPage delay 1 giây)
    // Ta chờ 2 giây để chắc chắn vượt qua delay
    await tester.pump(const Duration(seconds: 2));

    // 4. Xử lý Navigation Animation (Chuyển từ Splash -> Login)
    await tester.pumpAndSettle();

    // 5. Xử lý Entry Animation của LoginPage (LoginPage có animation duration 1000ms)
    // Ta chờ thêm 1.5 giây để Animation hoàn tất, các field hiển thị rõ
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Debug: Kiểm tra xem đã thực sự vào Login Page chưa
    if (find.byType(LoginPage).evaluate().isEmpty) {
      print("⚠️ CẢNH BÁO: Chưa thấy LoginPage, thử pump thêm...");
      await tester.pump(const Duration(seconds: 2));
    }

    // 6. Thực hiện Login
    final authRobot = AuthRobot(tester);
    // Robot đã được nâng cấp hàm verifyOnLoginPage() để tự check
    await authRobot.enterEmail('superadmin@medicalink.com');
    await authRobot.enterPassword('SuperAdmin123!');
    await authRobot.tapLoginButton();

    // 7. Chờ chuyển trang sau khi login thành công
    // (Code Login có await Future.delayed(Duration(seconds: 1)) trước khi push)
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await authRobot.expectLoginSuccess();
  }

  group('Module Update Admin Profile Tests (TC006 - TC009)', () {

    testWidgets('TC006: Update thông tin hợp lệ (Happy Case)', (tester) async {
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickEditAdmin(index: 0);

      final newName = 'Admin E2E ${DateTime.now().millisecondsSinceEpoch}';
      await adminRobot.updateInfo(name: newName);

      await adminRobot.expectUpdateSuccess(newName);
    });

    testWidgets('TC007: Validate lỗi khi để trống Tên', (tester) async {
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickEditAdmin(index: 0);

      await adminRobot.updateInfo(name: '');

      await adminRobot.expectValidationError('Vui lòng nhập họ và tên');
    });

    testWidgets('TC008: Validate lỗi Email sai định dạng', (tester) async {
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickEditAdmin(index: 0);

      await adminRobot.updateInfo(email: 'email_sai_format');

      await adminRobot.expectValidationError('Email không đúng định dạng');
    });

    testWidgets('TC009: Validate lỗi Email đã tồn tại (Backend)', (tester) async {
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickEditAdmin(index: 0);

      // Sử dụng email chính chủ để test trùng lặp
      await adminRobot.updateInfo(email: 'superadmin@medicalink.com');

      await adminRobot.expectBackendError('Email');
    });
  });
}