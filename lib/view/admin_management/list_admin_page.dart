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
      _searchQuery = _searchController.text;
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
        title: const Text('Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn xóa tài khoản: ${admin['fullName']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nhập mật khẩu Super Admin',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _confirmDelete(admin, passwordController.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => _confirmDelete(admin, passwordController.text),
            child: const Text('Xóa'),
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
        const SnackBar(content: Text('Xóa tài khoản thành công!')),
      );
      _fetchAdmins();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thất bại. Kiểm tra mật khẩu hoặc thử lại.'), backgroundColor: Colors.red),
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
          style: TextStyle(color: context.theme.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.white),
            onPressed: _fetchAdmins,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm theo tên hoặc email',
                    prefixIcon: Icon(Icons.search, color: context.theme.blue),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: context.theme.blue),
                      onPressed: () {
                        _searchController.clear();
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
                ? const Center(child: CircularProgressIndicator())
                : _isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Không tìm thấy tài khoản admin phù hợp'
                        : 'Danh sách tài khoản admin trống',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
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
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.theme.blue,
                      child: Text(
                        admin['fullName']?[0].toUpperCase() ?? 'A',
                        style: TextStyle(color: context.theme.white),
                      ),
                    ),
                    title: Text(admin['fullName'] ?? 'N/A'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(admin['email'] ?? 'N/A'),
                        Text('Vai trò: ${admin['role'] ?? 'ADMIN'}'),
                        if (admin['phone'] != null) Text('SĐT: ${admin['phone']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: context.theme.blue),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            Routes.updateAdmin,
                            arguments: admin
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
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