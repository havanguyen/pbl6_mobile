import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/dto/appointment_dto.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import 'package:pbl6mobile/view/appointment/widgets/appointment_scheduler.dart';
import 'package:pbl6mobile/view_model/appointment/appointment_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class AppointmentActionDialogs {
  static Future<void> showEditDialog(
    BuildContext context,
    AppointmentData appointment,
  ) async {
    final notesController = TextEditingController(text: appointment.notes);
    final priceController = TextEditingController(
      text: appointment.priceAmount?.toString() ?? '',
    );
    final reasonController = TextEditingController(text: appointment.reason);
    String selectedStatus = appointment.status;

    final formKey = GlobalKey<FormState>();

    final List<String> statusOptions = [
      'BOOKED',
      'CONFIRMED',
      'CANCELLED',
      'COMPLETED',
      'RESCHEDULED',
      'CANCELLED_BY_STAFF',
      'CANCELLED_BY_PATIENT',
      'NO_SHOW',
    ];

    final theme = context.theme;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context).translate('update_appointment_title'),
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: statusOptions.contains(selectedStatus)
                      ? selectedStatus
                      : statusOptions.first,
                  dropdownColor: theme.card,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('status'),
                    labelStyle: TextStyle(color: theme.mutedForeground),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                  ),
                  style: TextStyle(color: theme.textColor),
                  items: statusOptions.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedStatus = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('notes'),
                    labelStyle: TextStyle(color: theme.mutedForeground),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('reason'),
                    labelStyle: TextStyle(color: theme.mutedForeground),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('price_vnd'),
                    labelStyle: TextStyle(color: theme.mutedForeground),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return AppLocalizations.of(
                        context,
                      ).translate('error_invalid_number');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: theme.mutedForeground),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: theme.primaryForeground,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final vm = context.read<AppointmentVm>();
                final success = await vm.updateAppointment(
                  appointment.id,
                  notesController.text,
                  double.tryParse(priceController.text) ?? 0,
                  'VND',
                  selectedStatus,
                  reasonController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          ).translate('update_success'),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          vm.actionError ??
                              AppLocalizations.of(
                                context,
                              ).translate('error_occurred_short'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context).translate('save')),
          ),
        ],
      ),
    );
  }

  static Future<void> showCancelDialog(
    BuildContext context,
    AppointmentData appointment,
  ) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final theme = context.theme;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.destructive),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(
                context,
              ).translate('cancel_appointment_title'),
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                ).translate('cancel_appointment_confirm'),
                style: TextStyle(color: theme.mutedForeground),
              ),
              const SizedBox(height: 16),
              // Mini Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.muted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      context,
                      'patient',
                      appointment.patient.fullName,
                      theme,
                    ),
                    const SizedBox(height: 4),
                    _buildSummaryRow(
                      context,
                      'doctor',
                      appointment.doctor.name ?? '',
                      theme,
                    ),
                    const SizedBox(height: 4),
                    _buildSummaryRow(
                      context,
                      'time',
                      '${DateFormat('HH:mm').format(appointment.appointmentStartTime)} - ${DateFormat('dd/MM/yyyy').format(appointment.appointmentStartTime)}',
                      theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('cancel_reason_optional'),
                  labelStyle: TextStyle(color: theme.mutedForeground),
                  hintText: AppLocalizations.of(
                    context,
                  ).translate('cancel_reason_hint'),
                  hintStyle: TextStyle(color: theme.mutedForeground),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.primary),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.border),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('close'),
              style: TextStyle(color: theme.mutedForeground),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.destructive,
              foregroundColor: theme.primaryForeground,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final vm = context.read<AppointmentVm>();
                final success = await vm.cancelAppointment(
                  appointment.id,
                  reasonController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          ).translate('cancel_success'),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          vm.actionError ??
                              AppLocalizations.of(
                                context,
                              ).translate('error_occurred_short'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              AppLocalizations.of(context).translate('confirm_cancel'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSummaryRow(
    BuildContext context,
    String labelKey,
    String value,
    CustomThemeExtension theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${AppLocalizations.of(context).translate(labelKey)}:',
          style: TextStyle(fontSize: 12, color: theme.mutedForeground),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  static Future<void> showRescheduleDialog(
    BuildContext context,
    AppointmentData appointment,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RescheduleDialog(appointment: appointment),
    );
  }

  static Future<void> showCompleteDialog(
    BuildContext context,
    AppointmentData appointment,
  ) async {
    final theme = context.theme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context).translate('confirm_complete_title'),
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context).translate('confirm_complete_message'),
          style: TextStyle(color: theme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context).translate('close'),
              style: TextStyle(color: theme.mutedForeground),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).translate('complete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final vm = context.read<AppointmentVm>();
      final success = await vm.completeAppointment(appointment.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('complete_success'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                vm.actionError ??
                    AppLocalizations.of(
                      context,
                    ).translate('error_occurred_short'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  static Future<void> showConfirmDialog(
    BuildContext context,
    AppointmentData appointment,
  ) async {
    final theme = context.theme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context).translate('confirm_appointment_title'),
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context).translate('confirm_appointment_message'),
          style: TextStyle(color: theme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context).translate('close'),
              style: TextStyle(color: theme.mutedForeground),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: theme.primaryForeground,
            ),
            child: Text(AppLocalizations.of(context).translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final vm = context.read<AppointmentVm>();
      final success = await vm.confirmAppointment(appointment.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('confirm_success'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                vm.actionError ??
                    AppLocalizations.of(
                      context,
                    ).translate('error_occurred_short'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class RescheduleDialog extends StatefulWidget {
  final AppointmentData appointment;

  const RescheduleDialog({super.key, required this.appointment});

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  List<String> _availableDates = [];
  List<DoctorSlot> _slots = [];
  bool _isLoadingDates = false;
  bool _isLoadingSlots = false;
  DateTime? _selectedDate;
  DoctorSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _fetchAvailableDates();
  }

  Future<void> _fetchAvailableDates() async {
    setState(() => _isLoadingDates = true);

    // Fetch range of dates (next 30 days) from DoctorService if possible
    // Since we don't have a direct 'getAvailableDates' endpoint,
    // we might need to rely on the user picking a date and then checking slots.
    // However, to mimic React's behavior of highlighting available days,
    // we would ideally query the backend.
    // Current limitation: DoctorService.getDoctorSlots requires specific dates.
    // Compromise: We will continue to allow date picking freely,
    // but we can try to pre-check or just let the user pick and see slots.
    // For now, let's revert to a simple date picker logic
    // where we don't limit the calendar but show slots when picked.

    // Logic: React does query range. Since we don't have that endpoint ready-to-go
    // without heavy loops, we will simulate availability by just allowing generic
    // date selection for now, effectively "assuming" dates are potentially available.

    // To match React's UI which likely shows "dots" for available days:
    // We will attempt to fetch slots for the *current view* if feasible,
    // but to avoid N+1 requests, we'll keep it simple for MVP.

    final now = DateTime.now();
    final dates = List.generate(60, (index) {
      final date = now.add(Duration(days: index));
      return DateFormat('yyyy-MM-dd').format(date);
    });

    setState(() {
      _availableDates = dates;
      _isLoadingDates = false;
    });
  }

  Future<void> _fetchSlots(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
      _isLoadingSlots = true;
    });

    try {
      final appointmentService = AppointmentService();
      final slots = await appointmentService.getDoctorSlots(
        doctorId: widget.appointment.doctorId,
        date: DateFormat('yyyy-MM-dd').format(date),
        locationId: widget.appointment.locationId,
        allowPast: true,
      );

      if (mounted) {
        setState(() {
          _slots = slots?.where((s) => s.isAvailable != false).toList() ?? [];
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _slots = [];
          _isLoadingSlots = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Scaffold(
        backgroundColor: theme.bg,
        appBar: AppBar(
          backgroundColor: theme.card,
          foregroundColor: theme.textColor,
          elevation: 0,
          title: Text(
            AppLocalizations.of(
              context,
            ).translate('reschedule_appointment_title'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _selectedSlot == null
                  ? null
                  : () => _confirmReschedule(),
              child: Text(
                AppLocalizations.of(context).translate('save'),
                style: TextStyle(
                  color: _selectedSlot == null
                      ? theme.mutedForeground
                      : theme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: AppointmentScheduler(
            availableDates: _availableDates,
            slots: _slots,
            isLoadingSlots: _isLoadingSlots,
            isLoadingDates: _isLoadingDates,
            selectedDate: _selectedDate,
            selectedSlot: _selectedSlot,
            onDateSelect: _fetchSlots,
            onSlotSelect: (slot) => setState(() => _selectedSlot = slot),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReschedule() async {
    if (_selectedSlot == null || _selectedDate == null) return;

    final theme = context.theme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context).translate('confirm_reschedule_title'),
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${AppLocalizations.of(context).translate('reschedule_confirm_message')}${_selectedSlot!.timeStart} ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}?',
          style: TextStyle(color: theme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: theme.mutedForeground),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: theme.primaryForeground,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).translate('agree')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final vm = context.read<AppointmentVm>();

      final success = await vm.rescheduleAppointment(
        widget.appointment.id,
        _selectedSlot!.timeStart,
        _selectedSlot!.timeEnd,
        _selectedDate!,
        doctorId: widget.appointment.doctorId,
        locationId: widget.appointment.locationId,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context); // Close sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('reschedule_success'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                vm.actionError ??
                    AppLocalizations.of(
                      context,
                    ).translate('error_occurred_short'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
