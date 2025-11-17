import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class LocationWorkRobot {
  final WidgetTester tester;

  LocationWorkRobot(this.tester);

  // --- Finders ---
  // Navigation Keys
  final _settingsButton = find.byKey(const ValueKey('main_page_settings_button'));
  final _locationMenuInSettings = find.byKey(const ValueKey('settings_page_location_button'));

  // Form Keys
  final _nameField = find.byKey(const ValueKey('location_form_name_field'));
  final _provinceDropdown = find.byKey(const ValueKey('location_form_province_dropdown'));
  final _districtDropdown = find.byKey(const ValueKey('location_form_district_dropdown'));
  final _wardDropdown = find.byKey(const ValueKey('location_form_ward_dropdown'));
  final _addressDetailField = find.byKey(const ValueKey('location_form_address_field'));
  final _phoneField = find.byKey(const ValueKey('location_form_phone_field'));
  final _timezoneDropdown = find.byKey(const ValueKey('location_form_timezone_dropdown'));
  final _saveButton = find.byKey(const ValueKey('location_form_save_button'));

  // List Page Keys (Thêm mới finder cho nút add)
  final _addLocationButton = find.byKey(const ValueKey('add_location_button'));

  // --- Actions ---

  Future<void> navigateToLocationList() async {
    // 1. Từ Dashboard -> Vào trang Settings
    await tester.ensureVisible(_settingsButton);
    await tester.tap(_settingsButton);
    await tester.pumpAndSettle();

    // 2. Trong Settings -> Tìm và chọn "Quản lý địa điểm khám"
    await tester.scrollUntilVisible(_locationMenuInSettings, 500);
    await tester.tap(_locationMenuInSettings);
    await tester.pumpAndSettle();

    // Verify đã vào màn hình List
    // Lưu ý: Text này phải khớp chính xác với AppBar title trong file UI
    expect(find.text('Quản lý địa điểm làm việc'), findsOneWidget);
  }

  Future<void> tapCreateButton() async {
    // SỬA LỖI TẠI ĐÂY: Thay vì tìm byIcon, ta tìm byKey
    await tester.ensureVisible(_addLocationButton);
    await tester.tap(_addLocationButton);
    await tester.pumpAndSettle();

    // Verify đã vào màn hình tạo mới
    expect(find.text('Tạo địa điểm làm việc'), findsOneWidget);
  }

  // ... (Giữ nguyên các hàm bên dưới không thay đổi) ...

  // Helper để chọn item trong Dropdown
  Future<void> _selectDropdownItem(Finder dropdownFinder, String itemText) async {
    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final itemFinder = find.text(itemText).last;
    await tester.scrollUntilVisible(itemFinder, 500);
    await tester.tap(itemFinder);
    await tester.pumpAndSettle();
  }

  Future<void> enterInfo({
    String? name,
    String? province,
    String? district,
    String? ward,
    String? detailAddress,
    String? phone,
    String? timezone,
  }) async {
    if (name != null) {
      await tester.ensureVisible(_nameField);
      await tester.enterText(_nameField, name);
      await tester.pump();
    }

    if (province != null) {
      await _selectDropdownItem(_provinceDropdown, province);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    if (district != null) {
      await _selectDropdownItem(_districtDropdown, district);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    if (ward != null) {
      await _selectDropdownItem(_wardDropdown, ward);
    }

    if (detailAddress != null) {
      await tester.ensureVisible(_addressDetailField);
      await tester.enterText(_addressDetailField, detailAddress);
      await tester.pump();
    }

    if (phone != null) {
      await tester.ensureVisible(_phoneField);
      await tester.enterText(_phoneField, phone);
      await tester.pump();
    }

    if (timezone != null) {
      await _selectDropdownItem(_timezoneDropdown, timezone);
    }

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  Future<void> submitForm() async {
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
  }

  Future<void> expectCreateSuccess(String name) async {
    await tester.pumpAndSettle();
    expect(find.text('Tạo địa điểm làm việc'), findsNothing);

    // Tìm tên địa điểm trong list (có scroll nếu cần)
    final nameFinder = find.text(name);
    await tester.scrollUntilVisible(nameFinder, 500, scrollable: find.byKey(const ValueKey('location_list_scroll_view')));
    expect(nameFinder, findsOneWidget);
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
}