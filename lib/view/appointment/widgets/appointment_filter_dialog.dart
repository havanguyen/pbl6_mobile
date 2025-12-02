import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/location_work_vm.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';

class AppointmentFilterDialog extends StatefulWidget {
  final String? selectedDoctorId;
  final String? selectedWorkLocationId;
  final String? selectedSpecialtyId;

  const AppointmentFilterDialog({
    super.key,
    this.selectedDoctorId,
    this.selectedWorkLocationId,
    this.selectedSpecialtyId,
  });

  @override
  State<AppointmentFilterDialog> createState() =>
      _AppointmentFilterDialogState();
}

class _AppointmentFilterDialogState extends State<AppointmentFilterDialog> {
  String? _selectedDoctorId;
  String? _selectedWorkLocationId;
  String? _selectedSpecialtyId;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.selectedDoctorId;
    _selectedWorkLocationId = widget.selectedWorkLocationId;
    _selectedSpecialtyId = widget.selectedSpecialtyId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorVm>().fetchDoctors();
      context.read<LocationWorkVm>().fetchLocations();
      context.read<SpecialtyVm>().fetchSpecialties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bộ lọc lịch hẹn'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDoctorDropdown(),
            const SizedBox(height: 16),
            _buildLocationDropdown(),
            const SizedBox(height: 16),
            _buildSpecialtyDropdown(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedDoctorId = null;
              _selectedWorkLocationId = null;
              _selectedSpecialtyId = null;
            });
          },
          child: const Text('Đặt lại'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'doctorId': _selectedDoctorId,
              'workLocationId': _selectedWorkLocationId,
              'specialtyId': _selectedSpecialtyId,
            });
          },
          child: const Text('Áp dụng'),
        ),
      ],
    );
  }

  Widget _buildDoctorDropdown() {
    return Consumer<DoctorVm>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.doctors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return DropdownButtonFormField<String>(
          value: _selectedDoctorId,
          decoration: const InputDecoration(
            labelText: 'Bác sĩ',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Tất cả bác sĩ'),
            ),
            ...vm.doctors.map((Doctor doctor) {
              return DropdownMenuItem<String>(
                value: doctor.id,
                child: Text(doctor.fullName, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDoctorId = value;
            });
          },
          isExpanded: true,
        );
      },
    );
  }

  Widget _buildLocationDropdown() {
    return Consumer<LocationWorkVm>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.locations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return DropdownButtonFormField<String>(
          value: _selectedWorkLocationId,
          decoration: const InputDecoration(
            labelText: 'Cơ sở làm việc',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Tất cả cơ sở'),
            ),
            ...vm.locations.map((WorkLocation location) {
              return DropdownMenuItem<String>(
                value: location.id,
                child: Text(location.name, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedWorkLocationId = value;
            });
          },
          isExpanded: true,
        );
      },
    );
  }

  Widget _buildSpecialtyDropdown() {
    return Consumer<SpecialtyVm>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.specialties.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return DropdownButtonFormField<String>(
          value: _selectedSpecialtyId,
          decoration: const InputDecoration(
            labelText: 'Chuyên khoa',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Tất cả chuyên khoa'),
            ),
            ...vm.specialties.map((Specialty specialty) {
              return DropdownMenuItem<String>(
                value: specialty.id,
                child: Text(specialty.name, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSpecialtyId = value;
            });
          },
          isExpanded: true,
        );
      },
    );
  }
}
