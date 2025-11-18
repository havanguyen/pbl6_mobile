import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

class LocationForm extends StatefulWidget {
  final bool isUpdate;
  final WorkLocation? initialData;
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
    required this.initialData,
    required this.onSubmit,
  });

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String? _selectedTimezone;
  bool _isLoading = false;
  late List<String> _timezones;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.name);
    _phoneController = TextEditingController(text: widget.initialData?.phone);
    _addressController = TextEditingController(text: widget.initialData?.address);

    _selectedTimezone = widget.initialData?.timezone;

    tzData.initializeTimeZones();
    _timezones = tz.timeZoneDatabase.locations.keys.toList();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final success = await widget.onSubmit(
        id: widget.initialData?.id,
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        timezone: _selectedTimezone!,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          _showErrorDialog(
              '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} địa điểm thất bại. Vui lòng thử lại.');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Lỗi', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text(message,
            style: TextStyle(color: context.theme.popoverForeground)),
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
                  key: const ValueKey('location_form_name_field'),
                  controller: _nameController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tên địa điểm',
                    prefixIcon: Icon(Icons.location_on, color: context.theme.primary),
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
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên địa điểm';
                    }
                    if (value.length < 10 || value.length > 200) {
                      return 'Tên phải từ 10 đến 200 ký tự';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                  key: const ValueKey('location_form_address_field'),
                  controller: _addressController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ',
                    prefixIcon: Icon(Icons.home_work, color: context.theme.primary),
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
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                  key: const ValueKey('location_form_phone_field'),
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
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (!RegExp(r'^\+?\d{9,15}$').hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                child: DropdownButtonFormField2<String>(
                  key: const ValueKey('location_form_timezone_dropdown'),
                  value: _selectedTimezone,
                  isExpanded: true,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Múi giờ',
                    prefixIcon: Icon(Icons.access_time, color: context.theme.primary),
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
                  items: _timezones
                      .map((tz) => DropdownMenuItem(
                    value: tz,
                    child: Text(
                      tz,
                      style: TextStyle(color: context.theme.textColor),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTimezone = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? 'Vui lòng chọn múi giờ' : null,
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: context.theme.input,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            _buildAnimatedFormField(
              index: 4,
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
                  key: const ValueKey('location_form_save_button'),
                  onTap: () {
                    _submitForm(context);
                  },
                  text: _isLoading
                      ? 'Đang ${widget.isUpdate ? 'cập nhật' : 'tạo'}...'
                      : '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} địa điểm',
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