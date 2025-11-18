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

  // Hàm setup môi trường và login (Tái sử dụng logic ổn định từ admin flow)
  Future<void> setupAppAndLogin(WidgetTester tester) async {
    // 1. Reset dữ liệu
    await Store.clearStorage();
    await Store.clear();

    // 2. Khởi động App
    await app.main();
    await tester.pumpAndSettle();

    // 3. Chờ Splash Screen
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // 4. Đảm bảo đang ở Login Page
    if (find.byType(LoginPage).evaluate().isEmpty) {
      await tester.pump(const Duration(seconds: 2));
    }

    // 5. Login Admin
    final authRobot = AuthRobot(tester);
    await authRobot.enterEmail('superadmin@medicalink.com');
    await authRobot.enterPassword('SuperAdmin123!');
    await authRobot.tapLoginButton();

    await tester.pump(const Duration(seconds: 2));
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

      // Nhập liệu đầy đủ các trường
      await locationRobot.enterInfo(
        name: uniqueName,
        province: 'Tỉnh An Giang',
        district: 'Huyện An Phú',
        ward: 'Xã Khánh An',
        detailAddress: 'Address A',
        phone: '0905123456',
        timezone: 'Asia/Ho_Chi_Minh',
      );

      await locationRobot.submitForm();
      await locationRobot.expectCreateSuccess(uniqueName);
    });

    testWidgets('TC011: Validate error when required fields are empty', (tester) async {
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();
      await locationRobot.tapCreateButton();

      // Không nhập gì, bấm Lưu ngay
      await locationRobot.submitForm();

      // Kiểm tra hiển thị lỗi validator
      await locationRobot.expectValidationError('Vui lòng nhập tên địa điểm');
      await locationRobot.expectValidationError('Vui lòng chọn tỉnh/thành phố');
      await locationRobot.expectValidationError('Vui lòng nhập địa chỉ chi tiết');
      await locationRobot.expectValidationError('Vui lòng nhập số điện thoại');
    });

    testWidgets('TC012: Validate invalid Phone Number format', (tester) async {
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();
      await locationRobot.tapCreateButton();

      await locationRobot.enterInfo(
        name: 'Test Phone Format',
        province: 'Tỉnh An Giang',
        district: 'Huyện An Phú',
        ward: 'Xã Khánh An',
        detailAddress: 'Address A',
        phone: '090511',
        timezone: 'Asia/Bangkok',
      );

      await locationRobot.submitForm();

      await locationRobot.expectValidationError('Số điện thoại không hợp lệ');
    });

    testWidgets('TC013: Validate Duplicate Location Name/Info (Backend Check)', (tester) async {
      await setupAppAndLogin(tester);
      final locationRobot = LocationWorkRobot(tester);

      await locationRobot.navigateToLocationList();

      // Tạo địa điểm lần 1
      final duplicateName = 'Duplicate Loc ${DateTime.now().millisecondsSinceEpoch}';

      await locationRobot.tapCreateButton();
      await locationRobot.enterInfo(
        name: duplicateName,
        province: 'Tỉnh An Giang',
        district: 'Huyện An Phú',
        ward: 'Xã Khánh An',
        detailAddress: 'Address A',
        phone: '0905111222',
        timezone: 'Asia/Bangkok',
      );
      await locationRobot.submitForm();
      await locationRobot.expectCreateSuccess(duplicateName);

      // Tạo địa điểm lần 2 với CÙNG TÊN (giả sử backend chặn trùng tên)
      await locationRobot.tapCreateButton();
      await locationRobot.enterInfo(
        name: duplicateName,
        province: 'Tỉnh An Giang',
        district: 'Huyện An Phú',
        ward: 'Xã Khánh An',
        detailAddress: 'Address B',
        phone: '0905333444',
        timezone: 'Asia/Bangkok',
      );
      await locationRobot.submitForm();

      // Mong đợi lỗi từ Backend trả về Dialog
      await locationRobot.expectBackendError();
    });
  });
}