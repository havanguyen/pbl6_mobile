import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

import 'package:pbl6mobile/shared/routes/routes.dart';

class UpdateDoctorPage extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const UpdateDoctorPage({super.key, required this.doctor});

  @override
  State<UpdateDoctorPage> createState() => _UpdateDoctorPageState();
}

class _UpdateDoctorPageState extends State<UpdateDoctorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfBirthController;
  late bool _isMale;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.doctor['fullName'] ?? '');
    _emailController = TextEditingController(text: widget.doctor['email'] ?? '');
    _passwordController = TextEditingController(); // Không load password
    _phoneController = TextEditingController(text: widget.doctor['phone'] ?? '');
    _dateOfBirthController = TextEditingController();
    final dob = widget.doctor['dateOfBirth'];
    if (dob != null) {
      final date = DateTime.parse(dob).toLocal();
      _dateOfBirthController.text = '${date.day}/${date.month}/${date.year}';
    }
    _isMale = widget.doctor['isMale'] ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _dateOfBirthController.text = '${date.day}/${date.month}/${date.year}';
    }
  }

  void _updateDoctor() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final success = await StaffService.updateStaff(
        widget.doctor['id'],
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        dateOfBirth: _dateOfBirthController.text,
        isMale: _isMale,
      );
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Cập nhật thất bại. Vui lòng thử lại.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành công'),
        content: const Text('Cập nhật tài khoản thành công!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, Routes.listDoctor);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        title: Text(
          'Chỉnh sửa tài khoản bác sĩ',
          style: TextStyle(color: context.theme.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person, color: context.theme.blue),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập họ và tên';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: context.theme.blue),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                    final emailRegex = RegExp(r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                    if (!emailRegex.hasMatch(value)) return 'Email không đúng định dạng';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới (để trống nếu không thay đổi)',
                    prefixIcon: Icon(Icons.lock, color: context.theme.blue),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 8 || !value.contains(RegExp(r'[a-zA-Z]')) || !value.contains(RegExp(r'[0-9]'))) {
                        return 'Mật khẩu tối thiểu 8 ký tự, có ít nhất 1 chữ cái và 1 số';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone, color: context.theme.blue),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Số điện thoại phải là 10 chữ số';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateOfBirthController,
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh (dd/mm/yyyy)',
                    prefixIcon: Icon(Icons.calendar_today, color: context.theme.blue),
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng chọn ngày sinh';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isMale,
                      onChanged: (value) => setState(() => _isMale = value ?? true),
                    ),
                    const Text('Nam'),
                    Radio<bool>(
                      value: true,
                      groupValue: _isMale,
                      onChanged: (value) => setState(() => _isMale = true),
                    ),
                    const SizedBox(width: 16),
                    Radio<bool>(
                      value: false,
                      groupValue: _isMale,
                      onChanged: (value) => setState(() => _isMale = false),
                    ),
                    const Text('Nữ'),
                  ],
                ),
                const SizedBox(height: 32),
                CustomButtonBlue(
                  onTap: _updateDoctor,
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