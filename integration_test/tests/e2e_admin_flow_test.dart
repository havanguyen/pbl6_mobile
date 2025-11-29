import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import 'package:pbl6mobile/view/auth/login_page.dart';
import '../robots/auth_robot.dart';
import '../robots/admin_management_robot.dart';
import '../utils/test_helper.dart';
import '../utils/test_reporter.dart';

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

  setUpAll(() async {
    await TestHelper().loadData();
    TestReporter().clear();
  });

  tearDownAll(() async {
    await TestReporter().exportToExcel();
  });

  group('Module Update & Delete Admin Profile Tests', () {
    testWidgets('TC006: Update thông tin hợp lệ', (tester) async {
      final testData = TestHelper().getTestCase('admin_flow_tests', 'TC006');
      try {
        await setupAppAndLogin(tester);
        final adminRobot = AdminManagementRobot(tester);

        await adminRobot.navigateToAdminList();
        await adminRobot.clickEditAdmin(index: 0);

        final newName = '${testData['data']['namePrefix']} ${DateTime.now().millisecondsSinceEpoch}';
        await adminRobot.updateInfo(name: newName);

        await adminRobot.expectUpdateSuccess(newName);
        
        TestReporter().addResult(
          caseId: 'TC006',
          description: testData['description'],
          status: 'PASSED',
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC006',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC007: Validate lỗi khi để trống Tên', (tester) async {
      final testData = TestHelper().getTestCase('admin_flow_tests', 'TC007');
      try {
        await setupAppAndLogin(tester);
        final adminRobot = AdminManagementRobot(tester);

        await adminRobot.navigateToAdminList();
        await adminRobot.clickEditAdmin(index: 0);

        await adminRobot.updateInfo(name: testData['data']['name']);

        await adminRobot.expectValidationError(testData['expected']['message']);

        TestReporter().addResult(
          caseId: 'TC007',
          description: testData['description'],
          status: 'PASSED',
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC007',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC008: Validate lỗi Email sai định dạng', (tester) async {
      final testData = TestHelper().getTestCase('admin_flow_tests', 'TC008');
      try {
        await setupAppAndLogin(tester);
        final adminRobot = AdminManagementRobot(tester);

        await adminRobot.navigateToAdminList();
        await adminRobot.clickEditAdmin(index: 0);

        await adminRobot.updateInfo(email: testData['data']['email']);

        await adminRobot.expectValidationError(testData['expected']['message']);

        TestReporter().addResult(
          caseId: 'TC008',
          description: testData['description'],
          status: 'PASSED',
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC008',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC009: Validate lỗi Email đã tồn tại', (tester) async {
      final testData = TestHelper().getTestCase('admin_flow_tests', 'TC009');
      try {
        await setupAppAndLogin(tester);
        final adminRobot = AdminManagementRobot(tester);

        await adminRobot.navigateToAdminList();
        await adminRobot.clickEditAdmin(index: 0);

        await adminRobot.updateInfo(email: testData['data']['email']);

        await adminRobot.expectBackendError(testData['expected']['keyword']);

        TestReporter().addResult(
          caseId: 'TC009',
          description: testData['description'],
          status: 'PASSED',
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC009',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
          inputData: testData['data'].toString(),
          expectedResult: testData['expected'].toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC010: Tạo Admin mới thành công', (tester) async {
      final testData = TestHelper().getTestCase('admin_flow_tests', 'TC010');
      try {
        await setupAppAndLogin(tester);
        final adminRobot = AdminManagementRobot(tester);

        await adminRobot.navigateToAdminList();
        await adminRobot.clickCreateAdmin();

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newName = '${testData['data']['namePrefix']} $timestamp';
        final newEmail = '${testData['data']['emailPrefix']}$timestamp${testData['data']['emailDomain']}';

        await adminRobot.fillCreateForm(
          name: newName,
          email: newEmail,
          password: testData['data']['password'],
        );

        await adminRobot.expectCreateSuccess(newName);

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

    testWidgets('TC011: Xóa Admin thành công', (tester) async {
      final testData = TestHelper().getTestCase('admin_flow_tests', 'TC011');
      try {
        await setupAppAndLogin(tester);
        final adminRobot = AdminManagementRobot(tester);

        await adminRobot.navigateToAdminList();

        await adminRobot.deleteAdmin(
          index: 0,
          password: testData['data']['confirmPassword'],
        );

        await adminRobot.expectDeleteSuccess();

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
  });
}