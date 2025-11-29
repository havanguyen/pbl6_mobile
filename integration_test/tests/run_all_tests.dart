import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_login_test.dart' as login_test;
import 'e2e_admin_flow_test.dart' as admin_test;
import 'e2e_location_work_test.dart' as location_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test Suite', () {
    login_test.main();
    admin_test.main();
    location_test.main();
  });
}