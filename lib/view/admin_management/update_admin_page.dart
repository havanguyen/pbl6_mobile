import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';

class UpdateAdminPage extends StatefulWidget {
  final Map<String, dynamic> admin;

  const UpdateAdminPage({super.key, required this.admin});

  @override
  State<UpdateAdminPage> createState() => _UpdateAdminPageState();
}

class _UpdateAdminPageState extends State<UpdateAdminPage> {
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
    _fullNameController = TextEditingController(text: widget.admin['fullName'] ?? '');
    _emailController = TextEditingController(text: widget.admin['email'] ?? '');
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: widget.admin['phone'] ?? '');
    _dateOfBirthController = TextEditingController();
    final dob = widget.admin['dateOfBirth'];
    if (dob != null) {
      final date = DateTime.parse(dob).toLocal();
      _dateOfBirthController.text = '${date.day}/${date.month}/${date.year}';
    }
    _isMale = widget.admin['isMale'] ?? true;
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.theme.primary,
            onPrimary: context.theme.primaryForeground,
            surface: context.theme.popover,
            onSurface: context.theme.popoverForeground,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      _dateOfBirthController.text = '${date.day}/${date.month}/${date.year}';
    }
  }

  void _updateAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final success = await StaffService.updateStaff(
        widget.admin['id'],
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
        backgroundColor: context.theme.popover,
        title: Text('Thành công', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text('Cập nhật tài khoản thành công!', style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, Routes.listAdmin);
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
        backgroundColor: context.theme.blue,
        title: Text(
          'Chỉnh sửa tài khoản admin',
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
                  controller: _fullNameController,
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person, color: context.theme.primary),
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
                    if (value == null || value.isEmpty) return 'Vui lòng nhập họ và tên';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.ring),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
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
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới (để trống nếu không thay đổi)',
                    prefixIcon: Icon(Icons.lock, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.ring),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
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
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Số điện thoại phải là 10 chữ số';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateOfBirthController,
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh (dd/mm/yyyy)',
                    prefixIcon: Icon(Icons.calendar_today, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.ring),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
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
                      activeColor: context.theme.primary,
                      checkColor: context.theme.primaryForeground,
                    ),
                    Text('Nam', style: TextStyle(color: context.theme.textColor)),
                    Radio<bool>(
                      value: true,
                      groupValue: _isMale,
                      onChanged: (value) => setState(() => _isMale = true),
                      activeColor: context.theme.primary,
                    ),
                    const SizedBox(width: 16),
                    Radio<bool>(
                      value: false,
                      groupValue: _isMale,
                      onChanged: (value) => setState(() => _isMale = false),
                      activeColor: context.theme.primary,
                    ),
                    Text('Nữ', style: TextStyle(color: context.theme.textColor)),
                  ],
                ),
                const SizedBox(height: 32),
                CustomButtonBlue(
                  onTap: _updateAdmin,
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