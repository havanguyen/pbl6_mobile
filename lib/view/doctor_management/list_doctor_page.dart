import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({super.key});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  bool _isEmpty = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _searchController.addListener(() {
      _searchQuery = _searchController.text;
      _fetchDoctors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    final result = await StaffService.getDoctors(search: _searchQuery);
    if (mounted) {
      setState(() {
        _doctors = result['data'] ?? [];
        _isEmpty = _doctors.isEmpty;
        _isLoading = false;
      });
    }
  }

  void _showDeleteDialog(dynamic doctor) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn xóa tài khoản: ${doctor['fullName']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nhập mật khẩu của bạn',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _confirmDelete(doctor, passwordController.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => _confirmDelete(doctor, passwordController.text),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(dynamic doctor, String password) async {
    final success = await StaffService.deleteStaff(doctor['id'], password: password);
    Navigator.pop(context);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa tài khoản thành công!')),
      );
      _fetchDoctors();
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
          'Quản lý tài khoản bác sĩ',
          style: TextStyle(color: context.theme.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.white),
            onPressed: _fetchDoctors,
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
                        _fetchDoctors();
                      },
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButtonBlue(
                  onTap: () => Navigator.pushNamed(context, Routes.createDoctor),
                  text: 'Tạo tài khoản bác sĩ',
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
                        ? 'Không tìm thấy tài khoản bác sĩ phù hợp'
                        : 'Danh sách tài khoản bác sĩ trống',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.theme.blue,
                      child: Text(
                        doctor['fullName']?[0].toUpperCase() ?? 'A',
                        style: TextStyle(color: context.theme.white),
                      ),
                    ),
                    title: Text(doctor['fullName'] ?? 'N/A'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor['email'] ?? 'N/A'),
                        Text('Vai trò: ${doctor['role'] ?? 'DOCTOR'}'),
                        if (doctor['phone'] != null) Text('SĐT: ${doctor['phone']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: context.theme.blue),
                          onPressed: () => Navigator.pushNamed(
                              context,
                              Routes.updateDoctor,
                              arguments: doctor
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteDialog(doctor),
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