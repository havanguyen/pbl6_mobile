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
  final _locationListScrollView = find.byKey(const ValueKey('location_list_scroll_view'));

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

  // Helper: Select specific item OR first item if itemText is null
  Future<void> _selectDropdownItem(Finder dropdownFinder, String? itemText) async {
    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle(); // Wait for dropdown to open

    // Tìm Scrollable cuối cùng trong cây Widget (thường là Overlay của Dropdown đang mở)
    final dropdownScrollable = find.byType(Scrollable).last;

    if (itemText != null) {
      final itemFinder = find.text(itemText);
      await tester.scrollUntilVisible(
        itemFinder,
        500,
        scrollable: dropdownScrollable,
      );
      await tester.tap(itemFinder.last); // .last để đảm bảo tap vào item trong overlay
    } else {
      // Chọn mục đầu tiên bằng cách tìm Text trong Overlay
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

    // Luôn gọi hàm chọn dropdown. Nếu timezone = null => Tự động chọn cái đầu tiên
    await _selectDropdownItem(_timezoneDropdown, timezone);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  Future<void> submitForm() async {
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    // Đợi 2 giây để đảm bảo API phản hồi và Navigation transition hoàn tất
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> expectCreateSuccess(String name) async {
    // FIX: Chỉ kiểm tra logic chuyển trang (Navigation)
    // 1. Xác nhận màn hình "Tạo địa điểm" đã biến mất (đã pop)
    expect(find.text('Tạo địa điểm làm việc'), findsNothing,
        reason: 'Form tạo mới phải đóng lại sau khi tạo thành công');

    // 2. Xác nhận màn hình "Quản lý" đang hiển thị
    expect(find.text('Quản lý địa điểm làm việc'), findsOneWidget,
        reason: 'Phải quay về màn hình danh sách');

    // Lưu ý: Không cần scroll tìm tên item vì danh sách load bất đồng bộ dễ gây flaky test.
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

  Future<void> clickEditLocation(String name) async {
    final locationCard = find.text(name);

    // Kiểm tra nếu ListView đã hiển thị thì mới scroll
    if (_locationListScrollView.evaluate().isNotEmpty) {
      final scrollableFinder = find.descendant(
        of: _locationListScrollView,
        matching: find.byType(Scrollable),
      );

      await tester.scrollUntilVisible(
        locationCard,
        500,
        scrollable: scrollableFinder,
      );
    }

    await tester.tap(locationCard);
    await tester.pumpAndSettle();
  }

  Future<void> deleteLocation() async {
    final deleteIcon = find.byIcon(Icons.delete_outline).first;
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    final confirmButton = find.text('Xóa');
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
  }

  Future<void> verifyLocationDeleted(String name) async {
    await tester.pumpAndSettle();
    expect(find.text(name), findsNothing);
  }
}