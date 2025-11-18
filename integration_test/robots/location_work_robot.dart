import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class LocationWorkRobot {
  final WidgetTester tester;

  LocationWorkRobot(this.tester);

  // --- Finders ---
  final _settingsButton = find.byKey(const ValueKey('main_page_settings_button'));
  final _locationMenuInSettings = find.byKey(const ValueKey('settings_page_location_button'));
  final _addLocationButton = find.byKey(const ValueKey('add_location_button'));

  final _nameField = find.byKey(const ValueKey('location_form_name_field'));
  final _addressField = find.byKey(const ValueKey('location_form_address_field'));
  final _phoneField = find.byKey(const ValueKey('location_form_phone_field'));
  final _timezoneDropdown = find.byKey(const ValueKey('location_form_timezone_dropdown'));
  final _saveButton = find.byKey(const ValueKey('location_form_save_button'));

  // --- Actions ---

  Future<void> navigateToLocationList() async {
    await tester.ensureVisible(_settingsButton);
    await tester.tap(_settingsButton);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(_locationMenuInSettings, 500);
    await tester.tap(_locationMenuInSettings);
    await tester.pumpAndSettle();

    expect(find.text('Quản lý địa điểm làm việc'), findsOneWidget);
  }

  Future<void> tapCreateButton() async {
    await tester.ensureVisible(_addLocationButton);
    await tester.tap(_addLocationButton);
    await tester.pumpAndSettle();
    expect(find.text('Tạo địa điểm làm việc'), findsOneWidget);
  }

  Future<void> _selectDropdownItem(Finder dropdownFinder, String? itemText) async {
    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final dropdownScrollable = find.byType(Scrollable).last;

    if (itemText != null) {
      final itemFinder = find.text(itemText);
      await tester.scrollUntilVisible(
        itemFinder,
        500,
        scrollable: dropdownScrollable,
      );
      await tester.tap(itemFinder.last);
    } else {
      final anyItemText = find.descendant(
        of: dropdownScrollable,
        matching: find.byType(Text),
      ).first;
      await tester.tap(anyItemText);
    }
    await tester.pumpAndSettle();
  }

  Future<void> enterInfo({
    String? name,
    String? address,
    String? phone,
    String? timezone,
  }) async {
    if (name != null) {
      await tester.ensureVisible(_nameField);
      await tester.enterText(_nameField, name);
      await tester.pump();
    }
    if (address != null) {
      await tester.ensureVisible(_addressField);
      await tester.enterText(_addressField, address);
      await tester.pump();
    }
    if (phone != null) {
      await tester.ensureVisible(_phoneField);
      await tester.enterText(_phoneField, phone);
      await tester.pump();
    }
    await _selectDropdownItem(_timezoneDropdown, timezone);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  Future<void> submitForm() async {
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> expectCreateSuccess(String name) async {
    expect(find.text('Tạo địa điểm làm việc'), findsNothing,
        reason: 'Form tạo mới phải đóng lại sau khi tạo thành công');
    expect(find.text('Quản lý địa điểm làm việc'), findsOneWidget,
        reason: 'Phải quay về màn hình danh sách');
  }

  Future<void> expectValidationError(String message) async {
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
  }

  Future<void> expectBackendError() async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Lỗi'), findsOneWidget);
    final closeBtn = find.text('OK');
    if (closeBtn.evaluate().isNotEmpty) {
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();
    }
  }

  // --- NEW: Logic Xóa Location Bất Kỳ ---

  Future<void> clickFirstDeleteIcon() async {
    // Chờ UI ổn định
    await tester.pumpAndSettle();

    // Tìm tất cả icon xóa đang hiển thị trên màn hình
    final deleteIcons = find.byIcon(Icons.delete_outline);

    // Kiểm tra xem có item nào để xóa không
    expect(deleteIcons, findsAtLeastNWidgets(1),
        reason: 'Danh sách cần có ít nhất 1 địa điểm để thực hiện test xóa');

    // Tap vào icon xóa đầu tiên tìm thấy
    await tester.tap(deleteIcons.first);
    await tester.pumpAndSettle();
  }

  Future<void> confirmDeleteDialog(String password) async {
    expect(find.text('Xác nhận xóa'), findsOneWidget);
    final passwordField = find.widgetWithText(TextField, 'Nhập mật khẩu Admin/Super Admin');
    await tester.enterText(passwordField, password);
    await tester.pump();

    final deleteBtn = find.widgetWithText(TextButton, 'Xóa');
    await tester.tap(deleteBtn);

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Xác nhận xóa'), findsNothing, reason: 'Dialog xóa phải đóng sau khi thành công');
  }
}