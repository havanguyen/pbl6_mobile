import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/view/appointment/widgets/appointment_scheduler.dart';
import 'package:pbl6mobile/view_model/appointment/create_appointment_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({super.key});

  @override
  State<CreateAppointmentPage> createState() => _CreateAppointmentPageState();
}

class _CreateAppointmentPageState extends State<CreateAppointmentPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateAppointmentVm()..init(),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateAppointmentVm>();
    final theme = Theme.of(context);

    final List<String> steps = [
      AppLocalizations.of(context).translate('step_patient'),
      AppLocalizations.of(context).translate('step_service'),
      AppLocalizations.of(context).translate('step_schedule'),
      AppLocalizations.of(context).translate('step_details'),
      AppLocalizations.of(context).translate('step_confirm'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('create_appointment_title'),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Custom Step Indicator
          _buildStepIndicator(theme, steps),

          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCurrentStep(vm, theme),
              ),
            ),
          ),

          // Bottom Controls
          _buildBottomControls(vm, theme),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, List<String> steps) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: Colors.white,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : (index <= _currentStep
                                  ? theme.primaryColor
                                  : Colors.grey.shade300),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isCurrent
                            ? theme.primaryColor
                            : Colors.white,
                        border: Border.all(
                          color: isCompleted || isCurrent
                              ? theme.primaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == steps.length - 1
                            ? Colors.transparent
                            : (index < _currentStep
                                  ? theme.primaryColor
                                  : Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent
                        ? theme.primaryColor
                        : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(CreateAppointmentVm vm, ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildPatientStep(vm, theme);
      case 1:
        return _buildServiceStep(vm, theme);
      case 2:
        return _buildScheduleStep(vm, theme);
      case 3:
        return _buildDetailsStep(vm, theme);
      case 4:
        return _buildReviewStep(vm, theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomControls(CreateAppointmentVm vm, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppLocalizations.of(context).translate('back')),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: vm.isLoading ? null : _onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: vm.isLoading && _currentStep == 4
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentStep == 4
                          ? AppLocalizations.of(
                              context,
                            ).translate('confirm_booking')
                          : AppLocalizations.of(
                              context,
                            ).translate('continue_step'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    final vm = context.read<CreateAppointmentVm>();
    print(
      '--- [DEBUG] _onNext Clicked. Step: $_currentStep. isLoading: ${vm.isLoading} ---',
    );

    if (_currentStep < 4) {
      // Validation logic
      bool isValid = true;
      if (_currentStep == 0 && vm.selectedPatient == null) {
        print('--- [DEBUG] Step 0 Validation Failed: No Patient Selected ---');
        isValid = false;
        _showError(
          AppLocalizations.of(context).translate('error_select_patient'),
        );
      } else if (_currentStep == 1) {
        if (vm.selectedLocation == null ||
            vm.selectedSpecialty == null ||
            vm.selectedDoctor == null) {
          print(
            '--- [DEBUG] Step 1 Validation Failed: Missing Service Info ---',
          );
          isValid = false;
          _showError(
            AppLocalizations.of(context).translate('error_select_service_info'),
          );
        }
      } else if (_currentStep == 2 && vm.selectedSlot == null) {
        print('--- [DEBUG] Step 2 Validation Failed: No Slot Selected ---');
        isValid = false;
        _showError(
          AppLocalizations.of(context).translate('error_select_datetime'),
        );
      }

      if (isValid) {
        print('--- [DEBUG] Moving to Step ${_currentStep + 1} ---');
        setState(() => _currentStep++);
      }
    } else {
      print('--- [DEBUG] Submitting form ... ---');
      _submit(vm);
    }
  }

  Widget _buildPatientStep(CreateAppointmentVm vm, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('search_select_patient'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Autocomplete<Patient>(
          displayStringForOption: (Patient option) => option.fullName,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              await vm.searchPatients('');
              return vm.patients;
            }
            await vm.searchPatients(textEditingValue.text);
            return vm.patients;
          },
          onSelected: (Patient selection) {
            vm.selectPatient(selection);
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('search_patient_hint'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: vm.isLoadingPatients
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                );
              },
        ),
        if (vm.selectedPatient != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.primaryColor.withOpacity(0.2),
                  child: Text(
                    vm.selectedPatient!.fullName[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.selectedPatient!.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vm.selectedPatient!.email ??
                            AppLocalizations.of(context).translate('no_email'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        vm.selectedPatient!.phone ??
                            AppLocalizations.of(context).translate('no_phone'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    // Clear selection logic if needed
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServiceStep(CreateAppointmentVm vm, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('service_info'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDropdown<WorkLocation>(
          label: AppLocalizations.of(context).translate('location'),
          value: vm.selectedLocation,
          items: vm.locations,
          itemLabel: (item) => item.name,
          onChanged: vm.selectLocation,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        _buildDropdown<Specialty>(
          label: AppLocalizations.of(context).translate('specialty'),
          value: vm.selectedSpecialty,
          items: vm.allSpecialties,
          itemLabel: (item) => item.name,
          onChanged: vm.selectSpecialty,
          icon: Icons.category_outlined,
        ),
        const SizedBox(height: 16),
        _buildDropdown<Doctor>(
          label: AppLocalizations.of(context).translate('doctor'),
          value: vm.selectedDoctor,
          items: vm.doctors,
          itemLabel: (item) => item.fullName,
          onChanged:
              (vm.selectedLocation != null && vm.selectedSpecialty != null)
              ? vm.selectDoctor
              : null,
          icon: Icons.medical_services_outlined,
          hint: vm.isLoadingDoctors
              ? AppLocalizations.of(context).translate('loading_list')
              : AppLocalizations.of(context).translate('select_doctor'),
        ),
        if (vm.selectedDoctor != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(
                    vm.selectedDoctor!.avatarUrl ??
                        'https://via.placeholder.com/150',
                  ),
                  onBackgroundImageError: (_, __) {},
                  child: vm.selectedDoctor!.avatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.selectedDoctor!.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vm.selectedSpecialty?.name ??
                            AppLocalizations.of(context).translate('specialty'),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleStep(CreateAppointmentVm vm, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('select_time'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        AppointmentScheduler(
          availableDates: vm.availableDates,
          slots: vm.slots,
          isLoadingDates: vm.isLoadingDates,
          isLoadingSlots: vm.isLoadingSlots,
          selectedDate: vm.selectedDate,
          selectedSlot: vm.selectedSlot,
          onDateSelect: vm.selectDate,
          onSlotSelect: vm.selectSlot,
          disabled: vm.selectedDoctor == null,
        ),
        if (vm.selectedSlot != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context).translate('selected_slot')}${vm.selectedSlot!.timeStart} - ${DateFormat('dd/MM/yyyy').format(vm.selectedDate!)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsStep(CreateAppointmentVm vm, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('details_info'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(
              context,
            ).translate('reason_for_visit'),
            prefixIcon: const Icon(Icons.assignment_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: vm.setReason,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(
              context,
            ).translate('additional_notes'),
            prefixIcon: const Icon(Icons.note_alt_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
          onChanged: vm.setNotes,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('examination_price'),
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: vm.setPrice,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('currency'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                value: vm.currency,
                items: ['VND', 'USD'].map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) vm.setCurrency(val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStep(CreateAppointmentVm vm, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('confirm_info'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildReviewRow(
                AppLocalizations.of(context).translate('step_patient'),
                vm.selectedPatient?.fullName ?? '',
              ),
              const Divider(height: 24),
              _buildReviewRow(
                AppLocalizations.of(context).translate('doctor'),
                vm.selectedDoctor?.fullName ?? '',
              ),
              _buildReviewRow(
                AppLocalizations.of(context).translate('specialty'),
                vm.selectedSpecialty?.name ?? '',
              ),
              _buildReviewRow(
                AppLocalizations.of(context).translate('location'),
                vm.selectedLocation?.name ?? '',
              ),
              const Divider(height: 24),
              _buildReviewRow(
                AppLocalizations.of(context).translate('time'),
                vm.selectedSlot != null
                    ? '${vm.selectedSlot!.timeStart} - ${DateFormat('dd/MM/yyyy').format(vm.selectedDate!)}'
                    : '',
                isHighlight: true,
              ),
              const Divider(height: 24),
              _buildReviewRow(
                AppLocalizations.of(context).translate('reason'),
                vm.reason.isEmpty
                    ? AppLocalizations.of(context).translate('none')
                    : vm.reason,
              ),
              _buildReviewRow(
                AppLocalizations.of(context).translate('notes'),
                vm.notes.isEmpty
                    ? AppLocalizations.of(context).translate('none')
                    : vm.notes,
              ),
              _buildReviewRow(
                AppLocalizations.of(context).translate('price'),
                vm.priceAmount != null
                    ? '${vm.priceAmount} ${vm.currency}'
                    : AppLocalizations.of(context).translate('not_entered'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isHighlight ? 16 : 14,
                color: isHighlight ? Colors.blue : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?)? onChanged,
    required IconData icon,
    String? hint,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      hint: hint != null ? Text(hint) : null,
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submit(CreateAppointmentVm vm) async {
    final success = await vm.confirmBooking();
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('booking_success'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (vm.error != null && mounted) {
      _showError(vm.error!);
    }
  }
}
