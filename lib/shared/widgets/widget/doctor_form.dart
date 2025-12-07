import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

enum ButtonState { idle, loading, success, error }

class AnimatedSubmitButton extends StatefulWidget {
  final Future<bool> Function() onSubmit;
  final String idleText;
  final String loadingText;
  final VoidCallback? onSuccess;

  const AnimatedSubmitButton({
    super.key,
    required this.onSubmit,
    required this.idleText,
    required this.loadingText,
    this.onSuccess,
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

    if (success) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        widget.onSuccess?.call();
      }
    } else {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _state = ButtonState.idle);
      }
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
            ),
          ),
        );
      case ButtonState.success:
        return SizedBox(
          key: const ValueKey('success'),
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
            child: Icon(Icons.close, color: context.theme.white),
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
  })
  onSubmit;
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
    _emailController = TextEditingController(
      text: widget.initialData?['email'] ?? '',
    );
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController(
      text: widget.initialData?['fullName'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialData?['phone'] ?? '',
    );
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
        print("Could not parse dateOfBirth as ISO string: $dob. Error: $e");
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
    DateTime initial;
    try {
      if (_dateOfBirthController.text.contains('/')) {
        final parts = _dateOfBirthController.text.split('/');
        initial = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } else {
        initial =
            DateTime.tryParse(_dateOfBirthController.text) ?? DateTime.now();
      }
    } catch (e) {
      initial = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          initial.isAfter(DateTime(1900)) && initial.isBefore(DateTime.now())
          ? initial
          : DateTime.now(),
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
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: context.theme.primary),
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
      setState(() {
        _dateOfBirthController.text = formattedDate;
      });
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

      if (!success && mounted) {
        _showErrorDialog(
          '${widget.isUpdate ? AppLocalizations.of(context).translate('update') : AppLocalizations.of(context).translate('create')} ${widget.role.toLowerCase()} ${AppLocalizations.of(context).translate('failed')}.',
        );
      }
      return success;
    }
    return false;
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text(
          AppLocalizations.of(context).translate('error'),
          style: TextStyle(color: context.theme.popoverForeground),
        ),
        content: Text(
          message,
          style: TextStyle(color: context.theme.popoverForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('ok'),
              style: TextStyle(color: context.theme.destructive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFormField({required int index, required Widget child}) {
    final delay = index * 100;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay / 800, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 20),
          child: Opacity(opacity: animation.value, child: child),
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
                  backgroundImage:
                      (widget.initialData?['avatarUrl'] != null &&
                          widget.initialData!['avatarUrl']!.isNotEmpty)
                      ? CachedNetworkImageProvider(
                          widget.initialData!['avatarUrl']!,
                        )
                      : null,
                  child:
                      (widget.initialData?['avatarUrl'] == null ||
                          widget.initialData!['avatarUrl']!.isEmpty)
                      ? Text(
                          widget.initialData?['fullName']?.isNotEmpty == true
                              ? widget.initialData!['fullName'][0].toUpperCase()
                              : 'D',
                          style: TextStyle(
                            fontSize: 40,
                            color: context.theme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
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
                      color: context.theme.textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
            _buildAnimatedFormField(
              index: 0,
              child: TextFormField(
                key: const ValueKey('edit_profile_name_field'),
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('full_name'),
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon: Icon(Icons.person, color: context.theme.primary),
                  enabledBorder: OutlineInputBorder(
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.theme.destructive),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.theme.destructive,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.theme.bg,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    ).translate('error_enter_full_name');
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
                style: TextStyle(
                  color: widget.isUpdate
                      ? context.theme.mutedForeground
                      : context.theme.textColor,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('email'),
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon: Icon(Icons.email, color: context.theme.primary),
                  enabledBorder: OutlineInputBorder(
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.theme.destructive,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.theme.destructive,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: widget.isUpdate
                      ? context.theme.input.withOpacity(0.5)
                      : context.theme.bg,
                ),
                readOnly: widget.isUpdate,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return AppLocalizations.of(
                      context,
                    ).translate('email_required');
                  if (!RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  ).hasMatch(value)) {
                    return AppLocalizations.of(
                      context,
                    ).translate('email_invalid');
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
                      ? AppLocalizations.of(
                          context,
                        ).translate('new_password_optional')
                      : AppLocalizations.of(context).translate('password'),
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon: Icon(Icons.lock, color: context.theme.primary),
                  enabledBorder: OutlineInputBorder(
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.theme.destructive,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.theme.destructive,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.theme.bg,
                ),
                obscureText: true,
                validator: (value) {
                  if (!widget.isUpdate && (value == null || value.isEmpty)) {
                    return AppLocalizations.of(
                      context,
                    ).translate('password_required');
                  }
                  if (widget.isUpdate && value != null && value.isNotEmpty) {
                    if (value.length < 8 ||
                        !value.contains(RegExp(r'[a-zA-Z]')) ||
                        !value.contains(RegExp(r'[0-9]'))) {
                      return AppLocalizations.of(
                        context,
                      ).translate('password_invalid');
                    }
                  } else if (!widget.isUpdate) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      ).translate('password_required');
                    }
                    if (value.length < 8 ||
                        !value.contains(RegExp(r'[a-zA-Z]')) ||
                        !value.contains(RegExp(r'[0-9]'))) {
                      return AppLocalizations.of(
                        context,
                      ).translate('password_invalid');
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedFormField(
              index: 3,
              child: TextFormField(
                key: const ValueKey('edit_profile_phone_field'),
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('phone_number'),
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon: Icon(Icons.phone, color: context.theme.primary),
                  enabledBorder: OutlineInputBorder(
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.theme.destructive,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.theme.destructive,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.theme.bg,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^(?:\+84|0)\d{9}$').hasMatch(value)) {
                      return AppLocalizations.of(
                        context,
                      ).translate('phone_number_invalid');
                    }
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
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('date_of_birth_format'),
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    color: context.theme.primary,
                  ),
                  enabledBorder: OutlineInputBorder(
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.theme.destructive,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.theme.destructive,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.theme.bg,
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    ).translate('date_of_birth_required');
                  }
                  try {
                    final parts = value.split('/');
                    if (parts.length != 3) throw FormatException();
                    DateTime(
                      int.parse(parts[2]),
                      int.parse(parts[1]),
                      int.parse(parts[0]),
                    );
                  } catch (e) {
                    return 'DD/MM/YYYY';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedFormField(
              index: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: context.theme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.theme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('gender_label'),
                      style: TextStyle(
                        color: context.theme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isMale = true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isMale
                                    ? context.theme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isMale
                                      ? context.theme.primary
                                      : context.theme.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).translate('male'),
                                  style: TextStyle(
                                    color: _isMale
                                        ? context.theme.primary
                                        : context.theme.textColor,
                                    fontWeight: _isMale
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isMale = false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isMale
                                    ? context.theme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !_isMale
                                      ? context.theme.primary
                                      : context.theme.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).translate('female'),
                                  style: TextStyle(
                                    color: !_isMale
                                        ? context.theme.primary
                                        : context.theme.textColor,
                                    fontWeight: !_isMale
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildAnimatedFormField(
              index: 6,
              child: AnimatedSubmitButton(
                key: const ValueKey('edit_profile_save_button'),
                onSubmit: _submitForm,
                idleText:
                    '${widget.isUpdate ? AppLocalizations.of(context).translate('update') : AppLocalizations.of(context).translate('create')} ${widget.role}',
                loadingText: AppLocalizations.of(
                  context,
                ).translate('processing'),
                onSuccess: widget.onSuccess,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
