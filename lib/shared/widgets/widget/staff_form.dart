import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

class StaffForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final String role;
  final Future<bool> Function({
  required String email,
  required String password,
  required String fullName,
  String? phone,
  required String dateOfBirth,
  required bool isMale,
  String? id,
  }) onSubmit;
  final VoidCallback? onSuccess; // Thêm callback khi thành công

  const StaffForm({
    super.key,
    required this.isUpdate,
    required this.initialData,
    required this.role,
    required this.onSubmit,
    this.onSuccess, // Thêm callback optional
  });

  @override
  State<StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<StaffForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfBirthController;
  late bool _isMale;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialData?['email'] ?? '');
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController(text: widget.initialData?['fullName'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData?['phone'] ?? '');
    _dateOfBirthController = TextEditingController();
    _isMale = widget.initialData?['isMale'] ?? true;

    // Khởi tạo animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Set initial date if available
    final dob = widget.initialData?['dateOfBirth'];
    if (dob != null) {
      try {
        final date = DateTime.parse(dob).toLocal();
        _dateOfBirthController.text = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        print('❌ Error parsing initial date: $e');
        _dateOfBirthController.text = dob.toString();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
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

      if (picked != null) {
        // Format date thành dd/mm/yyyy
        final day = picked.day.toString().padLeft(2, '0');
        final month = picked.month.toString().padLeft(2, '0');
        final year = picked.year.toString();
        final formattedDate = '$day/$month/$year';

        _dateOfBirthController.text = formattedDate;
        print('📅 Selected and formatted date: $formattedDate');
      }
    } catch (e) {
      print('❌ Error selecting date: $e');
    }
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      print('🔄 Submitting form...');
      print('📝 Date of birth: ${_dateOfBirthController.text}');

      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        dateOfBirth: _dateOfBirthController.text,
        isMale: _isMale,
      );

      setState(() => _isLoading = false);

      if (success) {
        print('✅ Form submitted successfully');

        // Gọi callback khi thành công nếu có
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }

        // Đóng trang và trả về kết quả
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        print('❌ Form submission failed');
        _showErrorDialog(
            '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} ${widget.role.toLowerCase()} thất bại. Vui lòng thử lại.');
      }
    }
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

  Widget _buildAnimatedFormField({
    required int index,
    required Widget child,
  }) {
    final delay = index * 100;
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        delay / 1000,
        1.0,
        curve: Curves.easeOutCubic,
      ),
    ));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 20),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Full Name Field
            _buildAnimatedFormField(
              index: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.border.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _fullNameController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.theme.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập họ và tên';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Email Field
            _buildAnimatedFormField(
              index: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.border.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.theme.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                    final emailRegex = RegExp(r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                    if (!emailRegex.hasMatch(value)) return 'Email không đúng định dạng';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password Field
            _buildAnimatedFormField(
              index: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.border.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _passwordController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.isUpdate
                        ? 'Mật khẩu mới (để trống nếu không thay đổi)'
                        : 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.theme.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (widget.isUpdate) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length < 8 || !value.contains(RegExp(r'[a-zA-Z]')) || !value.contains(RegExp(r'[0-9]'))) {
                          return 'Mật khẩu tối thiểu 8 ký tự, có ít nhất 1 chữ cái và 1 số';
                        }
                      }
                    } else {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (value.length < 8 || !value.contains(RegExp(r'[a-zA-Z]')) || !value.contains(RegExp(r'[0-9]'))) {
                        return 'Mật khẩu tối thiểu 8 ký tự, có ít nhất 1 chữ cái và 1 số';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Phone Field
            _buildAnimatedFormField(
              index: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.border.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _phoneController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.theme.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Số điện thoại phải là 10 chữ số';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date of Birth Field
            _buildAnimatedFormField(
              index: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.border.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _dateOfBirthController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh (dd/mm/yyyy)',
                    prefixIcon: Icon(Icons.calendar_today, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.theme.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng chọn ngày sinh';

                    // Validate date format
                    try {
                      final dateParts = value.split('/');
                      if (dateParts.length != 3) {
                        return 'Định dạng ngày không hợp lệ (dd/mm/yyyy)';
                      }

                      final day = int.tryParse(dateParts[0]);
                      final month = int.tryParse(dateParts[1]);
                      final year = int.tryParse(dateParts[2]);

                      if (day == null || month == null || year == null) {
                        return 'Ngày tháng năm phải là số';
                      }

                      return null;
                    } catch (e) {
                      return 'Định dạng ngày không hợp lệ';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Gender Selection
            _buildAnimatedFormField(
              index: 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: context.theme.input,
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.border.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giới tính',
                      style: TextStyle(
                        color: context.theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            _buildAnimatedFormField(
              index: 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomButtonBlue(
                  onTap: () {
                    _submitForm(context);
                  },
                  text: _isLoading
                      ? 'Đang ${widget.isUpdate ? 'cập nhật' : 'tạo'}...'
                      : '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} ${widget.role.toLowerCase()}',
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}