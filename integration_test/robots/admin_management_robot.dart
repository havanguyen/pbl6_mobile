import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class AdminManagementRobot {
  final WidgetTester tester;

  AdminManagementRobot(this.tester);

  Future<void> navigateToAdminList() async {
    final adminBtn = find.byKey(const ValueKey('admin_management_button'));

    await tester.pumpAndSettle();
    expect(adminBtn, findsOneWidget, reason: "Không tìm thấy nút 'Quản lý tài khoản Admin' trên Dashboard");

    await tester.tap(adminBtn);
    await tester.pumpAndSettle();

    expect(find.text('Quản lý Admin'), findsOneWidget);
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