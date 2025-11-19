import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import 'package:pbl6mobile/view/auth/login_page.dart';
import '../robots/auth_robot.dart';
import '../robots/location_work_robot.dart';
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
      final data = testHelper.getTestCase('location_tests', 'TC010');
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();
      await locationRobot.tapCreateButton();

      final uniqueName = '${data['data']['namePrefix']} ${DateTime.now().millisecondsSinceEpoch}';

      await locationRobot.enterInfo(
        name: uniqueName,
        address: data['data']['address'],
        phone: data['data']['phone'],
      );

      await locationRobot.submitForm();
      await locationRobot.expectCreateSuccess(uniqueName);
    });

    testWidgets('TC011: Validate error when required fields are empty', (tester) async {
      final data = testHelper.getTestCase('location_tests', 'TC011');
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();
      await locationRobot.tapCreateButton();

      await locationRobot.submitForm();

      final messages = List<String>.from(data['expected']['messages']);
      for (var msg in messages) {
        await locationRobot.expectValidationError(msg);
      }
    });

    testWidgets('TC012: Validate invalid Phone Number format', (tester) async {
      final data = testHelper.getTestCase('location_tests', 'TC012');
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();
      await locationRobot.tapCreateButton();

      await locationRobot.enterInfo(
        name: data['data']['name'],
        address: data['data']['address'],
        phone: data['data']['phone'],
      );

      await locationRobot.submitForm();

      final messages = List<String>.from(data['expected']['messages']);
      for (var msg in messages) {
        await locationRobot.expectValidationError(msg);
      }
    });

    testWidgets('TC013: Validate Duplicate Location Name/Info (Backend Check)', (tester) async {
      final data = testHelper.getTestCase('location_tests', 'TC013');
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();

      final duplicateName = '${data['data']['namePrefix']} ${DateTime.now().millisecondsSinceEpoch}';

      await locationRobot.tapCreateButton();
      await locationRobot.enterInfo(
        name: duplicateName,
        address: data['data']['addressA'],
        phone: data['data']['phoneA'],
      );
      await locationRobot.submitForm();
      await locationRobot.expectCreateSuccess(duplicateName);

      await locationRobot.tapCreateButton();
      await locationRobot.enterInfo(
        name: duplicateName,
        address: data['data']['addressB'],
        phone: data['data']['phoneB'],
      );
      await locationRobot.submitForm();

      await locationRobot.expectBackendError();
    });

    testWidgets('TC014: Delete any Location successfully', (tester) async {
      final data = testHelper.getTestCase('location_tests', 'TC014');
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);
      await locationRobot.navigateToLocationList();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await locationRobot.clickFirstDeleteIcon();
      await locationRobot.confirmDeleteDialog(data['data']['confirmPassword']);
    });
  });
}