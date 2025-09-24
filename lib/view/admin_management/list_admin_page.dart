import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

class AdminListPage extends StatefulWidget {
  const AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  List<dynamic> _admins = [];
  bool _isLoading = true;
  bool _isEmpty = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _fetchAdmins();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    final result = await StaffService.getAdmins(search: _searchQuery);
    if (mounted) {
      setState(() {
        _admins = result['data'] ?? [];
        _isEmpty = _admins.isEmpty;
        _isLoading = false;
      });
    }
  }

  void _showDeleteDialog(dynamic admin) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Xác nhận xóa', style: TextStyle(color: context.theme.popoverForeground)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa tài khoản: ${admin['fullName']}?',
              style: TextStyle(color: context.theme.popoverForeground),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Nhập mật khẩu Super Admin',
                labelStyle: TextStyle(color: context.theme.mutedForeground),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: context.theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.theme.ring),
                ),
                filled: true,
                fillColor: context.theme.input,
              ),
              onSubmitted: (_) => _confirmDelete(admin, passwordController.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: context.theme.mutedForeground)),
          ),
          TextButton(
            onPressed: () => _confirmDelete(admin, passwordController.text),
            child: Text('Xóa', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(dynamic admin, String password) async {
    final success = await StaffService.deleteStaff(admin['id'], password: password);
    Navigator.pop(context);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa tài khoản thành công!', style: TextStyle(color: context.theme.primaryForeground)),
          backgroundColor: context.theme.green,
        ),
      );
      _fetchAdmins();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Xóa thất bại. Kiểm tra mật khẩu hoặc thử lại.',
            style: TextStyle(color: context.theme.destructiveForeground),
          ),
          backgroundColor: context.theme.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        title: Text(
          'Quản lý tài khoản admin',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.primaryForeground),
            onPressed: _fetchAdmins,
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm theo tên hoặc email',
                    labelStyle: TextStyle(color: context.theme.mutedForeground),
                    prefixIcon: Icon(Icons.search, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.ring),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: context.theme.primary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _fetchAdmins();
                      },
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButtonBlue(
                  onTap: () => Navigator.pushNamed(context, Routes.createAdmin),
                  text: 'Tạo tài khoản admin',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: context.theme.primary))
                : _isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings_outlined, size: 64, color: context.theme.muted),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Không tìm thấy tài khoản admin phù hợp'
                        : 'Danh sách tài khoản admin trống',
                    style: TextStyle(fontSize: 18, color: context.theme.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _admins.length,
              itemBuilder: (context, index) {
                final admin = _admins[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: context.theme.card,
                  child: ListTile(
                    textColor: context.theme.cardForeground,
                    leading: CircleAvatar(
                      backgroundColor: context.theme.primary,
                      child: Text(
                        admin['fullName']?[0].toUpperCase() ?? 'A',
                        style: TextStyle(color: context.theme.primaryForeground),
                      ),
                    ),
                    title: Text(
                      admin['fullName'] ?? 'N/A',
                      style: TextStyle(color: context.theme.cardForeground),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(admin['email'] ?? 'N/A', style: TextStyle(color: context.theme.mutedForeground)),
                        Text('Vai trò: ${admin['role'] ?? 'ADMIN'}', style: TextStyle(color: context.theme.mutedForeground)),
                        if (admin['phone'] != null) Text('SĐT: ${admin['phone']}', style: TextStyle(color: context.theme.mutedForeground)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: context.theme.primary),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            Routes.updateAdmin,
                            arguments: admin,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: context.theme.destructive),
                          onPressed: () => _showDeleteDialog(admin),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}