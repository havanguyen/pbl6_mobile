import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/model/services/remote/work_location_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/setting/office_hours_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class CreateOfficeHourPage extends StatefulWidget {
  const CreateOfficeHourPage({super.key});

  @override
  State<CreateOfficeHourPage> createState() => _CreateOfficeHourPageState();
}

class _CreateOfficeHourPageState extends State<CreateOfficeHourPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedDoctorId;
  String? _selectedWorkLocationId;
  int _selectedDay = 1; // Monday
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isGlobal = false;

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
        backgroundColor: context.theme.blue,
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Global Checkbox
                    CheckboxListTile(
                      title: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('global_hours_label'),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('global_hours_subtitle'),
                      ),
                      value: _isGlobal,
                      onChanged: (value) {
                        setState(() {
                          _isGlobal = value ?? false;
                          if (_isGlobal) {
                            _selectedDoctorId = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Doctor Selection
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('doctor_optional'),
                        border: const OutlineInputBorder(),
                      ),
                      value: _selectedDoctorId,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('no_doctor_selected'),
                          ),
                        ),
                        ..._doctors.map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.fullName),
                          ),
                        ),
                      ],
                      onChanged: _isGlobal
                          ? null
                          : (value) {
                              setState(() {
                                _selectedDoctorId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 16),

                    // Location Selection
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('location_optional'),
                        border: const OutlineInputBorder(),
                      ),
                      value: _selectedWorkLocationId,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('all_locations'),
                          ),
                        ),
                        ..._locations.map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedWorkLocationId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Day Selection
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('day_of_week'),
                        border: const OutlineInputBorder(),
                      ),
                      value: _selectedDay,
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                            AppLocalizations.of(context).translate('monday'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            AppLocalizations.of(context).translate('tuesday'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text(
                            AppLocalizations.of(context).translate('wednesday'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text(
                            AppLocalizations.of(context).translate('thursday'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text(
                            AppLocalizations.of(context).translate('friday'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child: Text(
                            AppLocalizations.of(context).translate('saturday'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 0,
                          child: Text(
                            AppLocalizations.of(context).translate('sunday'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Time Range
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                ).translate('start_time'),
                                border: const OutlineInputBorder(),
                              ),
                              child: Text(
                                _formatTime(_startTime),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                ).translate('end_time'),
                                border: const OutlineInputBorder(),
                              ),
                              child: Text(
                                _formatTime(_endTime),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.theme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: vm.isLoading
                            ? null
                            : () async {
                                final success = await vm.createOfficeHour(
                                  doctorId: _selectedDoctorId,
                                  workLocationId: _selectedWorkLocationId,
                                  dayOfWeek: _selectedDay,
                                  startTime: _formatTime(_startTime),
                                  endTime: _formatTime(_endTime),
                                  isGlobal: _isGlobal,
                                );
                                if (success && mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context).translate(
                                          'create_office_hour_success',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: vm.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('create_office_hour_btn'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
