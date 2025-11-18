import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import 'package:pbl6mobile/view/auth/login_page.dart';
import '../robots/auth_robot.dart';
import '../robots/admin_management_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setupAppAndLogin(WidgetTester tester) async {
    await Store.clearStorage();
    await Store.clear();

    await app.main();
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 2));

    await tester.pumpAndSettle();

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    if (find.byType(LoginPage).evaluate().isEmpty) {
      await tester.pump(const Duration(seconds: 2));
    }

    final authRobot = AuthRobot(tester);
    await authRobot.enterEmail('superadmin@medicalink.com');
    await authRobot.enterPassword('SuperAdmin123!');
    await authRobot.tapLoginButton();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await authRobot.expectLoginSuccess();
  }

  group('Module Update & Delete Admin Profile Tests', () {
    testWidgets('TC006: Update thông tin hợp lệ', (tester) async {
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

    testWidgets('TC009: Validate lỗi Email đã tồn tại', (tester) async {
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickEditAdmin(index: 0);

      await adminRobot.updateInfo(email: 'superadmin@medicalink.com');

      await adminRobot.expectBackendError('Email');
    });

    testWidgets('TC010: Tạo Admin mới thành công', (tester) async {
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickCreateAdmin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newName = 'New Admin $timestamp';
      final newEmail = 'newadmin$timestamp@test.com';

      await adminRobot.fillCreateForm(
        name: newName,
        email: newEmail,
        password: 'Password123!',
      );

      await adminRobot.expectCreateSuccess(newName);
    });

    testWidgets('TC011: Xóa Admin thành công', (tester) async {
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();

      await adminRobot.deleteAdmin(
        index: 0,
        password: 'SuperAdmin123!',
      );

      await adminRobot.expectDeleteSuccess();
    });
  });
}