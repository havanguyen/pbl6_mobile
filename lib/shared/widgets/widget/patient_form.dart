import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class PatientForm extends StatefulWidget {
  final Patient? patient;
  final Function(Map<String, dynamic>) onSubmit;
  final bool isLoading;

  const PatientForm({
    super.key,
    this.patient,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<PatientForm> createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressLineController;
  late TextEditingController _districtController;
  late TextEditingController _provinceController;
  late TextEditingController _dateOfBirthController;

  bool? _isMale;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.patient?.fullName ?? '',
    );
    _emailController = TextEditingController(text: widget.patient?.email ?? '');
    _phoneController = TextEditingController(text: widget.patient?.phone ?? '');
    _addressLineController = TextEditingController(
      text: widget.patient?.addressLine ?? '',
    );
    _districtController = TextEditingController(
      text: widget.patient?.district ?? '',
    );
    _provinceController = TextEditingController(
      text: widget.patient?.province ?? '',
    );

    _isMale = widget.patient?.isMale;
    _selectedDate = widget.patient?.dateOfBirth;

    _dateOfBirthController = TextEditingController(
      text: _selectedDate != null
          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
          : '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'addressLine': _addressLineController.text.isEmpty
            ? null
            : _addressLineController.text,
        'district': _districtController.text.isEmpty
            ? null
            : _districtController.text,
        'province': _provinceController.text.isEmpty
            ? null
            : _provinceController.text,
        'isMale': _isMale,
        'dateOfBirth': _selectedDate?.toIso8601String().substring(0, 10),
      };

      widget.onSubmit(data);
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: context.theme.blue.withOpacity(0.8)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: context.theme.grey.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.theme.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.theme.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.theme.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AnimationLimiter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          ).translate('personal_information'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.theme.blue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: _buildInputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).translate('full_name'),
                            icon: Icons.person_outline,
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: _buildInputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).translate('email'),
                            icon: Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(
                                context,
                              ).translate('email_required');
                            }
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                              return AppLocalizations.of(
                                context,
                              ).translate('email_invalid');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: _buildInputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).translate('phone_number'),
                            icon: Icons.phone_outlined,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dateOfBirthController,
                          decoration: _buildInputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).translate('date_of_birth'),
                            icon: Icons.calendar_today_outlined,
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<bool?>(
                          value: _isMale,
                          decoration: _buildInputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).translate('gender'),
                            icon: Icons.wc_outlined,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('unknown'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text(
                                AppLocalizations.of(context).translate('male'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('female'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _isMale = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          ).translate('contact_address'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.theme.blue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _addressLineController,
                          decoration: _buildInputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).translate('address'),
                            icon: Icons.home_work_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _districtController,
                          decoration: _buildInputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).translate('district'),
                            icon: Icons.map_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _provinceController,
                          decoration: _buildInputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).translate('province'),
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                widget.isLoading
                    ? const CircularProgressIndicator()
                    : CustomButtonBlue(
                        text: widget.patient == null
                            ? AppLocalizations.of(
                                context,
                              ).translate('create_new')
                            : AppLocalizations.of(context).translate('update'),
                        onTap: _submitForm,
                      ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
