import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/model/services/remote/work_location_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/setting/office_hours_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

enum OfficeHourRuleType { specific, doctorDefault, locationDefault }

class CreateOfficeHourPage extends StatefulWidget {
  const CreateOfficeHourPage({super.key});

  @override
  State<CreateOfficeHourPage> createState() => _CreateOfficeHourPageState();
}

class _CreateOfficeHourPageState extends State<CreateOfficeHourPage> {
  final _formKey = GlobalKey<FormState>();

  OfficeHourRuleType _ruleType = OfficeHourRuleType.specific;

  String? _selectedDoctorId;
  String? _selectedWorkLocationId;
  int _selectedDay = 1; // Monday
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  List<Doctor> _doctors = [];
  List<WorkLocation> _locations = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final doctorsResponse = await DoctorService.getAllDoctors();
      final locationsResponse =
          await LocationWorkService.getAllActiveLocations();

      final List<Doctor> doctors = doctorsResponse.data;
      final List<WorkLocation> locations = [];

      if (locationsResponse['success'] == true &&
          locationsResponse['data'] != null) {
        for (var item in locationsResponse['data']) {
          locations.add(WorkLocation.fromJson(item));
        }
      }

      if (mounted) {
        setState(() {
          _doctors = doctors;
          _locations = locations;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('loading_data_error')}$e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.theme.primary,
              onPrimary: context.theme.primaryForeground,
              surface: context.theme.card,
              onSurface: context.theme.cardForeground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OfficeHoursVm>();

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).translate('add_office_hour'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingData
          ? Center(
              child: CircularProgressIndicator(color: context.theme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      AppLocalizations.of(context).translate('rule_type_label'),
                    ),
                    const SizedBox(height: 12),
                    _buildRuleTypeSelector(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Configuration'),
                    const SizedBox(height: 12),
                    if (_ruleType == OfficeHourRuleType.specific ||
                        _ruleType == OfficeHourRuleType.doctorDefault)
                      _buildDoctorDropdown(),
                    if (_ruleType == OfficeHourRuleType.specific ||
                        _ruleType == OfficeHourRuleType.locationDefault) ...[
                      if (_ruleType == OfficeHourRuleType.specific)
                        const SizedBox(height: 16),
                      _buildLocationDropdown(),
                    ],
                    const SizedBox(height: 16),
                    _buildDayDropdown(),
                    const SizedBox(height: 16),
                    _buildTimeRangePicker(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(vm),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.theme.textColor,
      ),
    );
  }

  Widget _buildRuleTypeSelector() {
    return Column(
      children: [
        _buildRadioTile(
          value: OfficeHourRuleType.specific,
          label: AppLocalizations.of(context).translate('rule_type_specific'),
          icon: Icons.person_pin_circle_outlined,
        ),
        const SizedBox(height: 8),
        _buildRadioTile(
          value: OfficeHourRuleType.doctorDefault,
          label: AppLocalizations.of(
            context,
          ).translate('rule_type_doctor_default'),
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 8),
        _buildRadioTile(
          value: OfficeHourRuleType.locationDefault,
          label: AppLocalizations.of(
            context,
          ).translate('rule_type_location_default'),
          icon: Icons.location_city_outlined,
        ),
      ],
    );
  }

  Widget _buildRadioTile({
    required OfficeHourRuleType value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _ruleType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _ruleType = value;
          // Reset fields not relevant to the new type
          if (_ruleType == OfficeHourRuleType.doctorDefault) {
            _selectedWorkLocationId = null;
          }
          if (_ruleType == OfficeHourRuleType.locationDefault) {
            _selectedDoctorId = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.theme.primary.withOpacity(0.1)
              : context.theme.card,
          border: Border.all(
            color: isSelected ? context.theme.primary : context.theme.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? context.theme.primary
                  : context.theme.mutedForeground,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? context.theme.primary
                      : context.theme.textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: context.theme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(
        AppLocalizations.of(context).translate('doctor'),
      ),
      value: _selectedDoctorId,
      items: _doctors
          .map((d) => DropdownMenuItem(value: d.id, child: Text(d.fullName)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedDoctorId = value;
        });
      },
      validator: (value) {
        if (_ruleType != OfficeHourRuleType.locationDefault && value == null) {
          return AppLocalizations.of(context).translate(
            'error_select_doctor',
          ); // Utilize existing generic error if specific missing, or default validation text
        }
        return null;
      },
      // Ensure icon color follows theme
      icon: Icon(Icons.arrow_drop_down, color: context.theme.mutedForeground),
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(
        AppLocalizations.of(context).translate('location'),
      ),
      value: _selectedWorkLocationId,
      items: _locations
          .map((l) => DropdownMenuItem(value: l.id, child: Text(l.name)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedWorkLocationId = value;
        });
      },
      validator: (value) {
        if (_ruleType != OfficeHourRuleType.doctorDefault && value == null) {
          return 'Please select a location'; // Fallback if key missing
        }
        return null;
      },
      icon: Icon(Icons.arrow_drop_down, color: context.theme.mutedForeground),
    );
  }

  Widget _buildDayDropdown() {
    return DropdownButtonFormField<int>(
      decoration: _inputDecoration(
        AppLocalizations.of(context).translate('day_of_week'),
      ),
      value: _selectedDay,
      items: [
        DropdownMenuItem(
          value: 1,
          child: Text(AppLocalizations.of(context).translate('monday')),
        ),
        DropdownMenuItem(
          value: 2,
          child: Text(AppLocalizations.of(context).translate('tuesday')),
        ),
        DropdownMenuItem(
          value: 3,
          child: Text(AppLocalizations.of(context).translate('wednesday')),
        ),
        DropdownMenuItem(
          value: 4,
          child: Text(AppLocalizations.of(context).translate('thursday')),
        ),
        DropdownMenuItem(
          value: 5,
          child: Text(AppLocalizations.of(context).translate('friday')),
        ),
        DropdownMenuItem(
          value: 6,
          child: Text(AppLocalizations.of(context).translate('saturday')),
        ),
        DropdownMenuItem(
          value: 0,
          child: Text(AppLocalizations.of(context).translate('sunday')),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedDay = value!;
        });
      },
      icon: Icon(Icons.arrow_drop_down, color: context.theme.mutedForeground),
    );
  }

  Widget _buildTimeRangePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(true),
            child: InputDecorator(
              decoration: _inputDecoration(
                AppLocalizations.of(context).translate('start_time'),
              ),
              child: Text(
                _formatTime(_startTime),
                style: TextStyle(fontSize: 16, color: context.theme.textColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(false),
            child: InputDecorator(
              decoration: _inputDecoration(
                AppLocalizations.of(context).translate('end_time'),
              ),
              child: Text(
                _formatTime(_endTime),
                style: TextStyle(fontSize: 16, color: context.theme.textColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.theme.mutedForeground),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.theme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.theme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.theme.primary, width: 2),
      ),
      filled: true,
      fillColor: context.theme.card,
    );
  }

  Widget _buildSubmitButton(OfficeHoursVm vm) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.theme.primary,
          foregroundColor: context.theme.primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: vm.isLoading ? null : _handleSubmit,
        child: vm.isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: context.theme.primaryForeground,
                  strokeWidth: 2,
                ),
              )
            : Text(
                AppLocalizations.of(
                  context,
                ).translate('create_office_hour_btn'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      // Logic from API Spec:
      // 1. Doctor-specific at location: doctorId not null, workLocationId not null
      // 2. Doctor-specific (all locations): doctorId not null, workLocationId null
      // 3. Global location hours: workLocationId not null, doctorId null, isGlobal true

      String? doctorId = _selectedDoctorId;
      String? workLocationId = _selectedWorkLocationId;
      bool isGlobal = false;

      if (_ruleType == OfficeHourRuleType.doctorDefault) {
        workLocationId = null;
      } else if (_ruleType == OfficeHourRuleType.locationDefault) {
        doctorId = null;
        isGlobal = true;
      }

      final vm = context.read<OfficeHoursVm>();
      final success = await vm.createOfficeHour(
        doctorId: doctorId,
        workLocationId: workLocationId,
        dayOfWeek: _selectedDay,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        isGlobal: isGlobal,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.theme.green,
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('create_office_hour_success'),
              style: TextStyle(color: context.theme.white),
            ),
          ),
        );
      }
    }
  }
}
