import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/location_work_vm.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class AppointmentFilterDialog extends StatefulWidget {
  final String? selectedDoctorId;
  final String? selectedWorkLocationId;
  final String? selectedSpecialtyId;
  final bool isDoctor;

  const AppointmentFilterDialog({
    super.key,
    this.selectedDoctorId,
    this.selectedWorkLocationId,
    this.selectedSpecialtyId,
    this.isDoctor = false,
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
      if (!widget.isDoctor) {
        context.read<DoctorVm>().fetchAllDoctors();
      }
      context.read<LocationWorkVm>().fetchActiveLocations();
      context.read<SpecialtyVm>().fetchSpecialties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context).translate('appointment_filter_title'),
      ),
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
              if (!widget.isDoctor) {
                _selectedDoctorId = null;
              }
              _selectedWorkLocationId = null;
              _selectedSpecialtyId = null;
            });
          },
          child: Text(AppLocalizations.of(context).translate('reset')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).translate('cancel')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'doctorId': _selectedDoctorId,
              'workLocationId': _selectedWorkLocationId,
              'specialtyId': _selectedSpecialtyId,
            });
          },
          child: Text(AppLocalizations.of(context).translate('apply')),
        ),
      ],
    );
  }

  Widget _buildDoctorDropdown() {
    if (widget.isDoctor) {
      if (_selectedDoctorId == null) {
        // If it's a doctor but no ID is selected (shouldn't happen if initialized correctly), show loading
        return const Center(child: CircularProgressIndicator());
      }
      // Since we don't want to load all doctors just to show the current doctor's name,
      // and we might not have the name if we only have the ID.
      // However, usually the doctor fetches their own profile before this.
      // We will try to get it from the vm if available, or just show "Current Doctor".
      // A better approach is to fetch the specific doctor info or rely on what we have.
      // Given the constraints and previous crash, a simple read-only field is safest.

      return Consumer<DoctorVm>(
        builder: (context, vm, child) {
          // Attempt to find the doctor in the loaded list if available, or just show ID/Placeholder
          final doctorNameFuture = Future.value(
            vm.allDoctors
                    .cast<Doctor?>()
                    .firstWhere(
                      (d) => d?.id == _selectedDoctorId,
                      orElse: () => null,
                    )
                    ?.fullName ??
                'Current Doctor',
          );

          return FutureBuilder<String>(
            future: doctorNameFuture,
            builder: (context, snapshot) {
              return InkWell(
                onTap: null,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('doctor'),
                    border: const OutlineInputBorder(),
                    filled: true,
                    enabled: false,
                  ),
                  child: Text(
                    snapshot.data ?? 'Loading...',
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return Consumer<DoctorVm>(
      builder: (context, vm, child) {
        if (vm.allDoctors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return DropdownButtonFormField<String>(
          value: _selectedDoctorId,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).translate('doctor'),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                AppLocalizations.of(context).translate('all_doctors'),
              ),
            ),
            ...vm.allDoctors.map((Doctor doctor) {
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
        if (vm.activeLocations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return DropdownButtonFormField<String>(
          value: _selectedWorkLocationId,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).translate('work_location'),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                AppLocalizations.of(context).translate('all_locations'),
              ),
            ),
            ...vm.activeLocations.map((WorkLocation location) {
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
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).translate('specialty'),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                AppLocalizations.of(context).translate('all_specialties'),
              ),
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
