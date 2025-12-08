import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class LocationForm extends StatefulWidget {
  final bool isUpdate;
  final WorkLocation? initialData;
  final Future<bool> Function({
    required String name,
    required String address,
    required String phone,
    required String timezone,
    String? googleMapUrl,
    String? id,
  })
  onSubmit;

  const LocationForm({
    super.key,
    required this.isUpdate,
    required this.initialData,
    required this.onSubmit,
  });

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _googleMapUrlController;

  String? _selectedTimezone;
  bool _isLoading = false;
  late List<String> _timezones;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.name);
    _phoneController = TextEditingController(text: widget.initialData?.phone);
    _addressController = TextEditingController(
      text: widget.initialData?.address,
    );
    _googleMapUrlController = TextEditingController(
      text: widget.initialData?.googleMapUrl,
    );

    _selectedTimezone = widget.initialData?.timezone;

    tzData.initializeTimeZones();
    // Ensure unique and sorted
    final zones = tz.timeZoneDatabase.locations.keys.toSet().toList()..sort();
    _timezones = zones;

    // Ensure selected timezone is in the list to avoid DropdownButton error
    if (_selectedTimezone != null &&
        _selectedTimezone!.isNotEmpty &&
        !_timezones.contains(_selectedTimezone)) {
      print(
        '--- [WARN] Selected timezone "$_selectedTimezone" not found in database. Adding explicitly. ---',
      );
      _timezones.insert(0, _selectedTimezone!);
    }

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
    _googleMapUrlController.dispose();
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
        timezone: _selectedTimezone ?? '',
        googleMapUrl: _googleMapUrlController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          _showErrorDialog(
            AppLocalizations.of(context).translate('save_location_failed'),
          );
        }
      }
    }
  }

  void _showErrorDialog(String message) {
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
        curve: Interval(delay / 1000, 1.0, curve: Curves.easeOutCubic),
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

  void _generateMapUrl() {
    final address = _addressController.text.trim();
    if (address.isNotEmpty) {
      final encodedAddress = Uri.encodeComponent(address);
      setState(() {
        _googleMapUrlController.text =
            'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).translate('address_required_for_map_error'),
          ),
        ),
      );
    }
  }

  Future<void> _openMapUrl() async {
    final urlString = _googleMapUrlController.text.trim();
    if (urlString.isNotEmpty) {
      final uri = Uri.tryParse(urlString);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('invalid_url_error'),
            ),
          ),
        );
      }
    }
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
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('location_name_label'),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: context.theme.primary,
                    ),
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
                      return AppLocalizations.of(
                        context,
                      ).translate('location_name_required');
                    }
                    if (value.length < 2 || value.length > 160) {
                      // Updated validation to 2-160 chars
                      return AppLocalizations.of(
                        context,
                      ).translate('location_name_length_error');
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
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('address_label'),
                    prefixIcon: Icon(
                      Icons.home_work,
                      color: context.theme.primary,
                    ),
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
                    // Optional field
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
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('phone_label'),
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
                      if (!RegExp(r'^\+?\d{9,15}$').hasMatch(value)) {
                        return AppLocalizations.of(
                          context,
                        ).translate('phone_invalid');
                      }
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
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('timezone_label'),
                    prefixIcon: Icon(
                      Icons.access_time,
                      color: context.theme.primary,
                    ),
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
                      .map(
                        (tz) => DropdownMenuItem(
                          value: tz,
                          child: Text(
                            tz,
                            style: TextStyle(color: context.theme.textColor),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTimezone = value;
                    });
                  },
                  validator: (value) => null, // Optional
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
            const SizedBox(height: 20),
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
                  key: const ValueKey('location_form_google_map_url_field'),
                  controller: _googleMapUrlController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('google_map_url_label'),
                    prefixIcon: Icon(Icons.map, color: context.theme.primary),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_addressController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.auto_fix_high),
                            tooltip: AppLocalizations.of(
                              context,
                            ).translate('generate_map_url_tooltip'),
                            onPressed: _generateMapUrl,
                            color: context.theme.primary,
                          ),
                        if (_googleMapUrlController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            tooltip: AppLocalizations.of(
                              context,
                            ).translate('open_map_tooltip'),
                            onPressed: _openMapUrl,
                            color: context.theme.primary,
                          ),
                      ],
                    ),
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
                    if (value != null && value.isNotEmpty) {
                      final uri = Uri.tryParse(value);
                      if (uri == null || !uri.hasAbsolutePath) {
                        return AppLocalizations.of(
                          context,
                        ).translate('invalid_url_error');
                      }
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 32),

            _buildAnimatedFormField(
              index: 5,
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
                      ? (widget.isUpdate
                            ? AppLocalizations.of(context).translate('updating')
                            : AppLocalizations.of(
                                context,
                              ).translate('creating'))
                      : (widget.isUpdate
                            ? AppLocalizations.of(
                                context,
                              ).translate('update_location_btn')
                            : AppLocalizations.of(
                                context,
                              ).translate('create_location_btn')),
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
