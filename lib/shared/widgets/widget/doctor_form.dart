import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

enum ButtonState { idle, loading, success, error }

class AnimatedSubmitButton extends StatefulWidget {
  final Future<bool> Function() onSubmit;
  final String idleText;
  final String loadingText;

  const AnimatedSubmitButton({
    super.key,
    required this.onSubmit,
    required this.idleText,
    required this.loadingText,
  });

  @override
  State<AnimatedSubmitButton> createState() => _AnimatedSubmitButtonState();
}

class _AnimatedSubmitButtonState extends State<AnimatedSubmitButton> {
  ButtonState _state = ButtonState.idle;

  void _handleSubmit() async {
    if (_state == ButtonState.loading) return;

    setState(() => _state = ButtonState.loading);
    final success = await widget.onSubmit();
    setState(() => _state = success ? ButtonState.success : ButtonState.error);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _state = ButtonState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: _buildButtonChild(),
    );
  }

  Widget _buildButtonChild() {
    switch (_state) {
      case ButtonState.loading:
        return SizedBox(
          key: const ValueKey('loading'),
          height: 52,
          child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: context.theme.primaryForeground,
                  strokeWidth: 2,
                ),
              )),
        );
      case ButtonState.success:
        return  SizedBox(
          key: ValueKey('success'),
          height: 52,
          child: CircleAvatar(
            backgroundColor: context.theme.green,
            child: Icon(Icons.check, color: context.theme.white),
          ),
        );
      case ButtonState.error:
        return SizedBox(
          key: const ValueKey('error'),
          height: 52,
          child: CircleAvatar(
            backgroundColor: context.theme.destructive,
            child:  Icon(Icons.close, color: context.theme.white),
          ),
        );
      case ButtonState.idle:
      return SizedBox(
          key: const ValueKey('idle'),
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primary,
              foregroundColor: context.theme.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.idleText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        );
    }
  }
}

class DoctorForm extends StatefulWidget {
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
  final VoidCallback? onSuccess;

  const DoctorForm({
    super.key,
    required this.isUpdate,
    required this.initialData,
    required this.role,
    required this.onSubmit,
    this.onSuccess,
  });

  @override
  State<DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends State<DoctorForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfBirthController;
  late bool _isMale;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _emailController =
        TextEditingController(text: widget.initialData?['email'] ?? '');
    _passwordController = TextEditingController();
    _fullNameController =
        TextEditingController(text: widget.initialData?['fullName'] ?? '');
    _phoneController =
        TextEditingController(text: widget.initialData?['phone'] ?? '');
    _dateOfBirthController = TextEditingController();
    _isMale = widget.initialData?['isMale'] ?? true;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final dob = widget.initialData?['dateOfBirth'];
    if (dob != null) {
      try {
        final date = DateTime.parse(dob).toLocal();
        _dateOfBirthController.text =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
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
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      final formattedDate = '$day/$month/$year';
      _dateOfBirthController.text = formattedDate;
    }
  }

  Future<bool> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        dateOfBirth: _dateOfBirthController.text,
        isMale: _isMale,
      );

      if (success) {
        widget.onSuccess?.call();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      } else {
        _showErrorDialog(
            '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} ${widget.role.toLowerCase()} thất bại.');
      }
      return success;
    }
    return false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title:
        Text('Lỗi', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text(message,
            style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            Text('OK', style: TextStyle(color: context.theme.destructive)),
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
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay / 800, 1.0, curve: Curves.easeOutCubic),
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
            if (widget.isUpdate) ...[
              Hero(
                tag: 'avatar_${widget.initialData?['id']}',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: context.theme.primary.withOpacity(0.1),
                  child: Text(
                    widget.initialData?['fullName']?.isNotEmpty == true
                        ? widget.initialData!['fullName'][0].toUpperCase()
                        : 'D',
                    style: TextStyle(
                        fontSize: 40,
                        color: context.theme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Hero(
                tag: 'name_${widget.initialData?['id']}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    widget.initialData?['fullName'] ?? '',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.theme.textColor),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
            _buildAnimatedFormField(
              index: 0,
              child: TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person, color: context.theme.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedFormField(
              index: 1,
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: context.theme.primary),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(value)) {
                    return 'Email không đúng định dạng';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedFormField(
              index: 2,
              child: TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: widget.isUpdate
                      ? 'Mật khẩu mới (để trống nếu không đổi)'
                      : 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock, color: context.theme.primary),
                ),
                obscureText: true,
                validator: (value) {
                  if (!widget.isUpdate && (value == null || value.isEmpty)) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      (value.length < 8 ||
                          !value.contains(RegExp(r'[a-zA-Z]')) ||
                          !value.contains(RegExp(r'[0-9]')))) {
                    return 'Mật khẩu tối thiểu 8 ký tự, có chữ và số';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedFormField(
              index: 3,
              child: TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone, color: context.theme.primary),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Số điện thoại phải là 10 chữ số';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedFormField(
              index: 4,
              child: TextFormField(
                controller: _dateOfBirthController,
                decoration: InputDecoration(
                  labelText: 'Ngày sinh (dd/mm/yyyy)',
                  prefixIcon:
                  Icon(Icons.calendar_today, color: context.theme.primary),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn ngày sinh';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedFormField(
                index: 5,
                child: Row(
                  children: [
                    Text('Giới tính:',
                        style: TextStyle(color: context.theme.textColor)),
                    Radio<bool>(
                        value: true,
                        groupValue: _isMale,
                        onChanged: (value) => setState(() => _isMale = true)),
                    Text('Nam', style: TextStyle(color: context.theme.textColor)),
                    Radio<bool>(
                        value: false,
                        groupValue: _isMale,
                        onChanged: (value) => setState(() => _isMale = false)),
                    Text('Nữ', style: TextStyle(color: context.theme.textColor)),
                  ],
                )),
            const SizedBox(height: 32),
            _buildAnimatedFormField(
              index: 6,
              child: AnimatedSubmitButton(
                onSubmit: _submitForm,
                idleText:
                '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} ${widget.role.toLowerCase()}',
                loadingText: 'Đang xử lý...',
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}