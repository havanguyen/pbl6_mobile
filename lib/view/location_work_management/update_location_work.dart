import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';

import '../../model/services/remote/work_location_service.dart';

class UpdateLocationWorkPage extends StatefulWidget {
  final Map<String, dynamic> location;

  const UpdateLocationWorkPage({super.key, required this.location});

  @override
  State<UpdateLocationWorkPage> createState() => _UpdateLocationWorkPageState();
}

class _UpdateLocationWorkPageState extends State<UpdateLocationWorkPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _timezoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location['name'] ?? '');
    _addressController = TextEditingController(text: widget.location['address'] ?? '');
    _phoneController = TextEditingController(text: widget.location['phone'] ?? '');
    _timezoneController = TextEditingController(text: widget.location['timezone'] ?? 'Asia/Ho_Chi_Minh');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _updateLocation() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final success = await LocationWorkService.updateLocation(
        id: widget.location['id'],
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        timezone: _timezoneController.text,
      );
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Cập nhật địa điểm thất bại. Vui lòng thử lại.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Thành công', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text('Cập nhật địa điểm thành công!', style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, Routes.listLocationWork);
            },
            child: Text('OK', style: TextStyle(color: context.theme.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Lỗi', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text(message, style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        title: Text(
          'Chỉnh sửa địa điểm làm việc',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: context.theme.bg,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Tên địa điểm',
                    prefixIcon: Icon(Icons.location_on, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.ring),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập tên địa điểm';
                    if (value.length < 10 || value.length > 200) return 'Tên phải từ 10 đến 200 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ',
                    prefixIcon: Icon(Icons.map, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.ring),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập địa chỉ';
                    if (value.length < 10 || value.length > 500) return 'Địa chỉ phải từ 10 đến 500 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.ring),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
                    if (!RegExp(r'^\+\d{10,12}$').hasMatch(value)) return 'Số điện thoại phải bắt đầu bằng + và có 10-12 chữ số';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timezoneController,
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Múi giờ',
                    prefixIcon: Icon(Icons.access_time, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.ring),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập múi giờ';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                CustomButtonBlue(
                  onTap: _updateLocation,
                  text: _isLoading ? 'Đang cập nhật...' : 'Cập nhật',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}