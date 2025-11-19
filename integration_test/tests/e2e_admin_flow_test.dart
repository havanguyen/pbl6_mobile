import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import 'package:pbl6mobile/view/auth/login_page.dart';
import '../robots/auth_robot.dart';
import '../robots/admin_management_robot.dart';
import '../utils/test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final testHelper = TestHelper();

  setUpAll(() async {
    await testHelper.loadData();
  });

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
      final data = testHelper.getTestCase('admin_flow_tests', 'TC006');
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickEditAdmin(index: 0);

      final newName = '${data['data']['namePrefix']} ${DateTime.now().millisecondsSinceEpoch}';
      await adminRobot.updateInfo(name: newName);

      await adminRobot.expectUpdateSuccess(newName);
    });

    testWidgets('TC007: Validate lỗi khi để trống Tên', (tester) async {
      final data = testHelper.getTestCase('admin_flow_tests', 'TC007');
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickEditAdmin(index: 0);

      await adminRobot.updateInfo(name: data['data']['name']);

      await adminRobot.expectValidationError(data['expected']['message']);
    });

    testWidgets('TC008: Validate lỗi Email sai định dạng', (tester) async {
      final data = testHelper.getTestCase('admin_flow_tests', 'TC008');
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickEditAdmin(index: 0);

      await adminRobot.updateInfo(email: data['data']['email']);

      await adminRobot.expectValidationError(data['expected']['message']);
    });

    testWidgets('TC009: Validate lỗi Email đã tồn tại', (tester) async {
      final data = testHelper.getTestCase('admin_flow_tests', 'TC009');
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickEditAdmin(index: 0);

      await adminRobot.updateInfo(email: data['data']['email']);

      await adminRobot.expectBackendError(data['expected']['keyword']);
    });

    testWidgets('TC010: Tạo Admin mới thành công', (tester) async {
      final data = testHelper.getTestCase('admin_flow_tests', 'TC010');
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();
      await adminRobot.clickCreateAdmin();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newName = '${data['data']['namePrefix']} $timestamp';
      final newEmail = '${data['data']['emailPrefix']}$timestamp${data['data']['emailDomain']}';

      await adminRobot.fillCreateForm(
        name: newName,
        email: newEmail,
        password: data['data']['password'],
      );

      await adminRobot.expectCreateSuccess(newName);
    });

    testWidgets('TC011: Xóa Admin thành công', (tester) async {
      final data = testHelper.getTestCase('admin_flow_tests', 'TC011');
      await setupAppAndLogin(tester);
      final adminRobot = AdminManagementRobot(tester);

      await adminRobot.navigateToAdminList();

      await adminRobot.deleteAdmin(
        index: 0,
        password: data['data']['confirmPassword'],
      );

      await adminRobot.expectDeleteSuccess();
    });
  });
}