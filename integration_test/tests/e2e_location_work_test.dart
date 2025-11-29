import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import 'package:pbl6mobile/view/auth/login_page.dart';
import '../robots/auth_robot.dart';
import '../robots/location_work_robot.dart';
import '../utils/test_helper.dart';
import '../utils/test_reporter.dart';

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

  setUpAll(() async {
    await TestHelper().loadData();
    TestReporter().clear();
  });

  tearDownAll(() async {
    await TestReporter().exportToExcel();
  });

  group('Location Work Management E2E Tests', () {
    testWidgets('TC010: Create Location successfully (Happy Case)', (tester) async {
      final testData = TestHelper().getTestCase('location_tests', 'TC010');
      try {
        await setupAppAndLogin(tester);
        final locationRobot = LocationWorkRobot(tester);

        await locationRobot.navigateToLocationList();
        await locationRobot.tapCreateButton();

        final uniqueName = '${testData['data']['namePrefix']} ${DateTime.now().millisecondsSinceEpoch}';

        await locationRobot.enterInfo(
          name: uniqueName,
          address: testData['data']['address'],
          phone: testData['data']['phone'],
        );

        await locationRobot.submitForm();
        await locationRobot.expectCreateSuccess(uniqueName);

        TestReporter().addResult(
          caseId: 'TC010',
          description: testData['description'],
          status: 'PASSED',
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC010',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC011: Validate error when required fields are empty', (tester) async {
      final testData = TestHelper().getTestCase('location_tests', 'TC011');
      try {
        await setupAppAndLogin(tester);
        final locationRobot = LocationWorkRobot(tester);

        await locationRobot.navigateToLocationList();
        await locationRobot.tapCreateButton();

        await locationRobot.submitForm();

        final messages = List<String>.from(testData['expected']['messages']);
        for (var msg in messages) {
          await locationRobot.expectValidationError(msg);
        }

        TestReporter().addResult(
          caseId: 'TC011',
          description: testData['description'],
          status: 'PASSED',
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC011',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC012: Validate invalid Phone Number format', (tester) async {
      final testData = TestHelper().getTestCase('location_tests', 'TC012');
      try {
        await setupAppAndLogin(tester);
        final locationRobot = LocationWorkRobot(tester);

        await locationRobot.navigateToLocationList();
        await locationRobot.tapCreateButton();

        await locationRobot.enterInfo(
          name: testData['data']['name'],
          address: testData['data']['address'],
          phone: testData['data']['phone'],
        );

        await locationRobot.submitForm();

        final messages = List<String>.from(testData['expected']['messages']);
        await locationRobot.expectValidationError(messages.first);

        TestReporter().addResult(
          caseId: 'TC012',
          description: testData['description'],
          status: 'PASSED',
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC012',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC013: Validate Duplicate Location Name/Info (Backend Check)', (tester) async {
      final testData = TestHelper().getTestCase('location_tests', 'TC013');
      try {
        await setupAppAndLogin(tester);
        final locationRobot = LocationWorkRobot(tester);

        await locationRobot.navigateToLocationList();

        final duplicateName = '${testData['data']['namePrefix']} ${DateTime.now().millisecondsSinceEpoch}';

        await locationRobot.tapCreateButton();
        await locationRobot.enterInfo(
          name: duplicateName,
          address: testData['data']['addressA'],
          phone: testData['data']['phoneA'],
        );
        await locationRobot.submitForm();
        await locationRobot.expectCreateSuccess(duplicateName);

        await locationRobot.tapCreateButton();
        await locationRobot.enterInfo(
          name: duplicateName,
          address: testData['data']['addressB'],
          phone: testData['data']['phoneB'],
        );
        await locationRobot.submitForm();

        await locationRobot.expectBackendError();

        TestReporter().addResult(
          caseId: 'TC013',
          description: testData['description'],
          status: 'PASSED',
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC013',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC014: Delete any Location successfully (With Password Confirm)', (tester) async {
      final testData = TestHelper().getTestCase('location_tests', 'TC014');
      try {
        await setupAppAndLogin(tester);
        final locationRobot = LocationWorkRobot(tester);

        await locationRobot.navigateToLocationList();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        await locationRobot.clickFirstDeleteIcon();
        await locationRobot.confirmDeleteDialog(testData['data']['confirmPassword']);

        TestReporter().addResult(
          caseId: 'TC014',
          description: testData['description'],
          status: 'PASSED',
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC014',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
        rethrow;
      }
    });
  });
}