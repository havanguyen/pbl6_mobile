import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import '../robots/auth_robot.dart';
import '../utils/test_helper.dart';
import '../utils/test_reporter.dart';

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

  setUpAll(() async {
    await TestHelper().loadData();
    TestReporter().clear();
  });

  tearDownAll(() async {
    await TestReporter().exportToExcel();
  });

  group('Login Feature E2E Tests', () {
    testWidgets('TC001: Login successfully with valid credentials', (tester) async {
      final testData = TestHelper().getTestCase('login_tests', 'TC001');
      try {
        await restartApp(tester);
        final authRobot = AuthRobot(tester);

        // Sử dụng tài khoản Super Admin mẫu
        await authRobot.enterEmail(testData['data']['email']);
        await authRobot.enterPassword(testData['data']['password']);
        await authRobot.tapLoginButton();

        await tester.pump(const Duration(seconds: 5));

        await authRobot.expectLoginSuccess();
        TestReporter().addResult(
          caseId: 'TC001',
          description: testData['description'],
          status: 'PASSED',
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC001',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC002: Login failed with non-existent email', (tester) async {
      final testData = TestHelper().getTestCase('login_tests', 'TC002');
      try {
        await restartApp(tester);
        final authRobot = AuthRobot(tester);

        await authRobot.enterEmail(testData['data']['email']);
        await authRobot.enterPassword(testData['data']['password']);
        await authRobot.tapLoginButton();

        await authRobot.expectErrorDialogVisible();
        await authRobot.dismissErrorDialog();
        
        TestReporter().addResult(
          caseId: 'TC002',
          description: testData['description'],
          status: 'PASSED',
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC002',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC003: Login failed with wrong password', (tester) async {
      final testData = TestHelper().getTestCase('login_tests', 'TC003');
      try {
        await restartApp(tester);
        final authRobot = AuthRobot(tester);

        await authRobot.enterEmail(testData['data']['email']);
        await authRobot.enterPassword(testData['data']['password']);
        await authRobot.tapLoginButton();

        await authRobot.expectErrorDialogVisible();
        await authRobot.dismissErrorDialog();

        TestReporter().addResult(
          caseId: 'TC003',
          description: testData['description'],
          status: 'PASSED',
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC003',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC004: Login failed with empty fields', (tester) async {
      final testData = TestHelper().getTestCase('login_tests', 'TC004');
      try {
        await restartApp(tester);
        final authRobot = AuthRobot(tester);

        // Để trống và bấm Login
        await authRobot.enterEmail(testData['data']['email']);
        await authRobot.enterPassword(testData['data']['password']);
        await authRobot.tapLoginButton();

        // Chờ validator hiển thị
        await tester.pumpAndSettle();

        final messages = List<String>.from(testData['expected']['messages']);
        for (var msg in messages) {
          await authRobot.expectValidationError(msg);
        }

        TestReporter().addResult(
          caseId: 'TC004',
          description: testData['description'],
          status: 'PASSED',
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC004',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
        );
        rethrow;
      }
    });

    testWidgets('TC005: Login failed with invalid email format', (tester) async {
      final testData = TestHelper().getTestCase('login_tests', 'TC005');
      try {
        await restartApp(tester);
        final authRobot = AuthRobot(tester);

        await authRobot.enterEmail(testData['data']['email']);
        await authRobot.enterPassword(testData['data']['password']);
        await authRobot.tapLoginButton();

        await tester.pumpAndSettle();

        final messages = List<String>.from(testData['expected']['messages']);
        await authRobot.expectValidationError(messages.first);

        TestReporter().addResult(
          caseId: 'TC005',
          description: testData['description'],
          status: 'PASSED',
        );
      } catch (e) {
        TestReporter().addResult(
          caseId: 'TC005',
          description: testData['description'],
          status: 'FAILED',
          errorMessage: e.toString(),
        );
        rethrow;
      }
    });
  });
}