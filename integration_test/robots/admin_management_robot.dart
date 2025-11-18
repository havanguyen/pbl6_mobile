import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

class AdminManagementRobot {
  final WidgetTester tester;

  AdminManagementRobot(this.tester);

  Future<void> navigateToAdminList() async {
    final adminBtn = find.byKey(const ValueKey('admin_management_button'));

    await tester.pumpAndSettle();
    expect(adminBtn, findsOneWidget);

    await tester.tap(adminBtn);
    await tester.pumpAndSettle();

    expect(find.text('Quản lý Admin'), findsOneWidget);
  }

  Future<void> clickCreateAdmin() async {
    final createBtn = find.byKey(const Key('btn_add_admin'));
    await tester.tap(createBtn);
    await tester.pumpAndSettle();
  }

  Future<void> clickEditAdmin({int index = 0}) async {
    final editBtn = find.byKey(Key('btn_edit_admin_$index'));

    final scrollableList = find.descendant(
      of: find.byKey(const ValueKey('admin_list_scroll_view')),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      editBtn,
      500,
      scrollable: scrollableList,
    );

    await tester.tap(editBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('update_admin_page_view')), findsOneWidget);
  }

  Future<void> deleteAdmin({int index = 0, required String password}) async {
    final itemKey = Key('btn_edit_admin_$index');

    final scrollableList = find.descendant(
      of: find.byKey(const ValueKey('admin_list_scroll_view')),
      matching: find.byType(Scrollable),
    );

    final itemFinder = find.byKey(itemKey);
    await tester.scrollUntilVisible(
      itemFinder,
      500,
      scrollable: scrollableList,
    );
    await tester.pumpAndSettle();

    final slidableFinder = find.ancestor(of: itemFinder, matching: find.byType(Slidable));

    await tester.drag(slidableFinder, const Offset(-500.0, 0.0));
    await tester.pumpAndSettle();

    final deleteIcon = find.byIcon(Icons.delete);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận xóa'), findsOneWidget);

    final passField = find.byKey(const Key('field_confirm_delete_password'));
    await tester.ensureVisible(passField);
    await tester.enterText(passField, password);
    await tester.pump();

    final confirmBtn = find.text('Xóa');
    await tester.tap(confirmBtn);

    // Quay lại dùng pumpAndSettle để chờ Dialog đóng hẳn và UI ổn định
    await tester.pumpAndSettle();
  }

  Future<void> fillCreateForm({
    required String name,
    required String email,
    required String password,
    String phone = '0905123456',
  }) async {
    final nameField = find.byKey(const Key('field_staff_name'));
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, name);
    await tester.pump();

    final emailField = find.byKey(const Key('field_staff_email'));
    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, email);
    await tester.pump();

    final passField = find.byKey(const Key('field_staff_password'));
    await tester.ensureVisible(passField);
    await tester.enterText(passField, password);
    await tester.pump();

    final phoneField = find.byKey(const Key('field_staff_phone'));
    if (phoneField.evaluate().isNotEmpty) {
      await tester.ensureVisible(phoneField);
      await tester.enterText(phoneField, phone);
      await tester.pump();
    }

    final dobField = find.byKey(const Key('field_staff_dob'));
    await tester.ensureVisible(dobField);
    await tester.tap(dobField);
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final submitBtn = find.byKey(const Key('btn_submit_staff_form'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> updateInfo({String? name, String? email}) async {
    if (name != null) {
      final nameField = find.byKey(const Key('field_staff_name'));
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, '');
      await tester.enterText(nameField, name);
      await tester.pump();
    }

    if (email != null) {
      final emailField = find.byKey(const Key('field_staff_email'));
      await tester.ensureVisible(emailField);
      await tester.enterText(emailField, '');
      await tester.enterText(emailField, email);
      await tester.pump();
    }

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final submitBtn = find.byKey(const Key('btn_submit_staff_form'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> expectUpdateSuccess(String newName) async {
    await tester.pumpAndSettle();
    expect(find.text('Quản lý Admin'), findsOneWidget);
    expect(find.text(newName), findsOneWidget);
  }

  Future<void> expectCreateSuccess(String newName) async {
    await tester.pumpAndSettle();
    expect(find.text('Quản lý Admin'), findsOneWidget);
    expect(find.text(newName), findsOneWidget);
  }

  Future<void> expectDeleteSuccess() async {
    expect(find.text('Quản lý Admin'), findsOneWidget);

    expect(find.text('Xác nhận xóa'), findsNothing);

    expect(find.text('Lỗi'), findsNothing);
  }

  Future<void> expectValidationError(String message) async {
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
  }

  Future<void> expectBackendError(String message) async {
    await tester.pumpAndSettle();
    expect(find.textContaining(message), findsOneWidget);
    final closeBtn = find.text('OK');
    if (closeBtn.evaluate().isNotEmpty) {
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();
    }
  }
}