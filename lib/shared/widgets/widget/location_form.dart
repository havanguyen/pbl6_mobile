import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

class LocationForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final Future<bool> Function({
  required String name,
  required String address,
  required String phone,
  required String timezone,
  String? id,
  }) onSubmit;

  const LocationForm({
    super.key,
    required this.isUpdate,
    this.initialData,
    required this.onSubmit,
  });

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _timezoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _addressController = TextEditingController(text: widget.initialData?['address'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData?['phone'] ?? '');
    _timezoneController = TextEditingController(text: widget.initialData?['timezone'] ?? 'Asia/Ho_Chi_Minh');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        timezone: _timezoneController.text,
      );
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('${widget.isUpdate ? 'Cập nhật' : 'Tạo'} địa điểm thất bại. Vui lòng thử lại.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Thành công', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text('${widget.isUpdate ? 'Cập nhật' : 'Tạo'} địa điểm thành công!', style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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
    return Form(
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
                border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.ring)),
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
                border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.ring)),
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
                border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.ring)),
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
                border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.ring)),
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
              onTap: _submitForm,
              text: _isLoading ? 'Đang ${widget.isUpdate ? 'cập nhật' : 'tạo'}...' : '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} địa điểm',
            ),
          ],
        ),
      ),
    );
  }
}