import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/model/services/remote/work_location_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/setting/office_hours_vm.dart';
import 'package:provider/provider.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
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
          'Thêm giờ làm việc',
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
                      title: const Text('Global Hours'),
                      subtitle: const Text(
                        'Áp dụng cho tất cả địa điểm (không chọn bác sĩ)',
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
                      decoration: const InputDecoration(
                        labelText: 'Bác sĩ (Tùy chọn)',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDoctorId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Không chọn bác sĩ'),
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
                      decoration: const InputDecoration(
                        labelText: 'Địa điểm (Tùy chọn)',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedWorkLocationId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tất cả địa điểm'),
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
                      decoration: const InputDecoration(
                        labelText: 'Ngày trong tuần',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDay,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Monday')),
                        DropdownMenuItem(value: 2, child: Text('Tuesday')),
                        DropdownMenuItem(value: 3, child: Text('Wednesday')),
                        DropdownMenuItem(value: 4, child: Text('Thursday')),
                        DropdownMenuItem(value: 5, child: Text('Friday')),
                        DropdownMenuItem(value: 6, child: Text('Saturday')),
                        DropdownMenuItem(value: 0, child: Text('Sunday')),
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
                              decoration: const InputDecoration(
                                labelText: 'Giờ bắt đầu',
                                border: OutlineInputBorder(),
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
                              decoration: const InputDecoration(
                                labelText: 'Giờ kết thúc',
                                border: OutlineInputBorder(),
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
                                    const SnackBar(
                                      content: Text('Tạo thành công'),
                                    ),
                                  );
                                }
                              },
                        child: vm.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Tạo giờ làm việc',
                                style: TextStyle(
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
