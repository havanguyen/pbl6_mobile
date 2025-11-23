import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import 'package:pbl6mobile/view/auth/login_page.dart';
import '../robots/auth_robot.dart';
import '../robots/location_work_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setupAppAndLogin(WidgetTester tester) async {
    await Store.clearStorage();
    await Store.clear();

    await app.main();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    if (find.byType(LoginPage).evaluate().isEmpty) {
      await tester.pump(const Duration(seconds: 2));
    }

    final authRobot = AuthRobot(tester);
    await authRobot.enterEmail('superadmin@medicalink.com');
    await authRobot.enterPassword('SuperAdmin123!');
    await authRobot.tapLoginButton();

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await authRobot.expectLoginSuccess();
  }

  group('Location Work Management E2E Tests', () {
    testWidgets('TC010: Create Location successfully (Happy Case)', (tester) async {
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();
      await locationRobot.tapCreateButton();

      final uniqueName = 'BV Đa Khoa E2E ${DateTime.now().millisecondsSinceEpoch}';

      await locationRobot.enterInfo(
        name: uniqueName,
        address: 'Address A, Xã Khánh An, Huyện An Phú, Tỉnh An Giang',
        phone: '0905123456',
      );

      await locationRobot.submitForm();
      await locationRobot.expectCreateSuccess(uniqueName);
    });

    testWidgets('TC011: Validate error when required fields are empty', (tester) async {
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();
      await locationRobot.tapCreateButton();

      await locationRobot.submitForm();

      await locationRobot.expectValidationError('Vui lòng nhập tên địa điểm');
      await locationRobot.expectValidationError('Vui lòng nhập địa chỉ');
      await locationRobot.expectValidationError('Vui lòng nhập số điện thoại');
    });

    testWidgets('TC012: Validate invalid Phone Number format', (tester) async {
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();
      await locationRobot.tapCreateButton();

      await locationRobot.enterInfo(
        name: 'Test Phone Format',
        address: 'Address A, Xã Khánh An, Huyện An Phú, Tỉnh An Giang',
        phone: '090511',
      );

      await locationRobot.submitForm();

      await locationRobot.expectValidationError('Số điện thoại không hợp lệ');
    });

    testWidgets('TC013: Validate Duplicate Location Name/Info (Backend Check)', (tester) async {
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();

      final duplicateName = 'Duplicate Loc ${DateTime.now().millisecondsSinceEpoch}';

      await locationRobot.tapCreateButton();
      await locationRobot.enterInfo(
        name: duplicateName,
        address: 'Address A, Xã Khánh An, Huyện An Phú, Tỉnh An Giang',
        phone: '0905111222',
      );
      await locationRobot.submitForm();
      await locationRobot.expectCreateSuccess(duplicateName);

      await locationRobot.tapCreateButton();
      await locationRobot.enterInfo(
        name: duplicateName,
        address: 'Address B, Xã Khánh An, Huyện An Phú, Tỉnh An Giang',
        phone: '0905333444',
      );
      await locationRobot.submitForm();

      await locationRobot.expectBackendError();
    });

    testWidgets('TC014: Delete any Location successfully (With Password Confirm)', (tester) async {
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);
      await locationRobot.navigateToLocationList();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await locationRobot.clickFirstDeleteIcon();
      await locationRobot.confirmDeleteDialog('SuperAdmin123!');
    });
  });
}