import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class AppointmentFilterDialog extends StatefulWidget {
  final String? selectedDoctorId;
  final bool isDoctor;

  const AppointmentFilterDialog({
    super.key,
    this.selectedDoctorId,
    this.isDoctor = false,
  });

  @override
  State<AppointmentFilterDialog> createState() =>
      _AppointmentFilterDialogState();
}

class _AppointmentFilterDialogState extends State<AppointmentFilterDialog> {
  String? _selectedDoctorId;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.selectedDoctorId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorVm>().fetchAllDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return AlertDialog(
      backgroundColor: theme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        AppLocalizations.of(context).translate('appointment_filter_title'),
        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildDoctorDropdown(theme)],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedDoctorId = null;
            });
          },
          child: Text(
            AppLocalizations.of(context).translate('reset'),
            style: TextStyle(color: theme.mutedForeground),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context).translate('cancel'),
            style: TextStyle(color: theme.mutedForeground),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: theme.primaryForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.pop(context, {'doctorId': _selectedDoctorId});
          },
          child: Text(AppLocalizations.of(context).translate('apply')),
        ),
      ],
    );
  }

  Widget _buildDoctorDropdown(CustomThemeExtension theme) {
    return Consumer<DoctorVm>(
      builder: (context, vm, child) {
        if (vm.allDoctors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return DropdownButtonFormField<String>(
          value: _selectedDoctorId,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).translate('doctor'),
            labelStyle: TextStyle(color: theme.mutedForeground),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: theme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          dropdownColor: theme.card,
          style: TextStyle(color: theme.textColor),
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
}
