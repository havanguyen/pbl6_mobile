import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import '../robots/auth_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Hàm setup: Reset app và chờ Splash Screen đi qua
  Future<void> restartApp(WidgetTester tester) async {
    // 1. Xóa dữ liệu cũ để tránh tự động login
    await Store.clearStorage();
    await Store.clear();

    // 2. Khởi động app
    await app.main();
    await tester.pumpAndSettle();

    // 3. QUAN TRỌNG: Chờ Splash Screen (Splash delay 1s + Animation)
    // Ta chờ dư ra 4s để chắc chắn đã vào Login Page
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  group('Login Feature E2E Tests', () {
    testWidgets('TC001: Login successfully with valid credentials', (tester) async {
      await restartApp(tester);
      final authRobot = AuthRobot(tester);

      // Sử dụng tài khoản Super Admin mẫu
      await authRobot.enterEmail('superadmin@medicalink.com');
      await authRobot.enterPassword('SuperAdmin123!');
      await authRobot.tapLoginButton();

      await tester.pump(const Duration(seconds: 5));

      await authRobot.expectLoginSuccess();
    });

    testWidgets('TC002: Login failed with non-existent email', (tester) async {
      await restartApp(tester);
      final authRobot = AuthRobot(tester);

      await authRobot.enterEmail('khongconguyen@gmail.com');
      await authRobot.enterPassword('nguyen902993');
      await authRobot.tapLoginButton();

      await authRobot.expectErrorDialogVisible();
      await authRobot.dismissErrorDialog();
    });

    testWidgets('TC003: Login failed with wrong password', (tester) async {
      await restartApp(tester);
      final authRobot = AuthRobot(tester);

      await authRobot.enterEmail('superadmin@medicalink.com');
      await authRobot.enterPassword('Matkhausai@9');
      await authRobot.tapLoginButton();

      await authRobot.expectErrorDialogVisible();
      await authRobot.dismissErrorDialog();
    });

    testWidgets('TC004: Login failed with empty fields', (tester) async {
      await restartApp(tester);
      final authRobot = AuthRobot(tester);

      // Để trống và bấm Login
      await authRobot.enterEmail('');
      await authRobot.enterPassword('');
      await authRobot.tapLoginButton();

      // Chờ validator hiển thị
      await tester.pumpAndSettle();

      await authRobot.expectValidationError('Vui lòng nhập email');
      await authRobot.expectValidationError('Vui lòng nhập mật khẩu');
    });

    testWidgets('TC005: Login failed with invalid email format', (tester) async {
      await restartApp(tester);
      final authRobot = AuthRobot(tester);

      await authRobot.enterEmail('emailkhongdunghople');
      await authRobot.enterPassword('SuperAdmin123!');
      await authRobot.tapLoginButton();

      await tester.pumpAndSettle();

      await authRobot.expectValidationError('Email không đúng định dạng');
    });
  });
}