import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pbl6mobile/main.dart' as app;
import 'package:pbl6mobile/shared/services/store.dart';
import '../robots/auth_robot.dart';
import '../utils/test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final testHelper = TestHelper();

  setUpAll(() async {
    await testHelper.loadData();
  });

  Future<void> restartApp(WidgetTester tester) async {
    await Store.clearStorage();
    await Store.clear();
    await app.main();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('Data Driven Login Tests', (tester) async {
    final loginTests = testHelper.getLoginTests();
    final authRobot = AuthRobot(tester);

    for (var testCase in loginTests) {
      await restartApp(tester);

      final data = testCase['data'];
      final expected = testCase['expected'];
      final String email = data['email'] ?? '';
      final String password = data['password'] ?? '';
      final String type = expected['type'];

      await authRobot.enterEmail(email);
      await authRobot.enterPassword(password);
      await authRobot.tapLoginButton();

      if (type == 'success') {
        await tester.pump(const Duration(seconds: 5));
        await authRobot.expectLoginSuccess();
      } else if (type == 'error_dialog') {
        await authRobot.expectErrorDialogVisible();
        await authRobot.dismissErrorDialog();
      } else if (type == 'validation') {
        await tester.pumpAndSettle();
        final messages = List<String>.from(expected['messages']);
        for (var msg in messages) {
          await authRobot.expectValidationError(msg);
        }
      }
    }
  });
}