import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/dto/appointment_dto.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';
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
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('update_appointment_title'),
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
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('status'),
                    border: const OutlineInputBorder(),
                  ),
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
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('notes'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).translate('reason'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('price_vnd'),
                    border: const OutlineInputBorder(),
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
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          ElevatedButton(
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

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('cancel_appointment_title'),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                ).translate('cancel_appointment_confirm'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('cancel_reason_required'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    ).translate('error_enter_reason');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('close')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
              AppLocalizations.of(
                context,
              ).translate('cancel_appointment_title'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
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

  static Future<void> showConfirmDialog(
    BuildContext context,
    AppointmentData appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('confirm_appointment_title'),
        ),
        content: Text(
          AppLocalizations.of(context).translate('confirm_appointment_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('close')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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
    // Simulating available dates (next 30 days)
    final now = DateTime.now();
    final dates = List.generate(30, (index) {
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
        doctorId: widget.appointment.doctor.id,
        date: DateFormat('yyyy-MM-dd').format(date),
        locationId: widget.appointment.locationId,
      );

      if (mounted) {
        setState(() {
          _slots = slots ?? [];
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
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Scaffold(
        appBar: AppBar(
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
              child: Text(AppLocalizations.of(context).translate('save')),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('confirm_reschedule_title'),
        ),
        content: Text(
          '${AppLocalizations.of(context).translate('reschedule_confirm_message')}${_selectedSlot!.timeStart} ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).translate('agree')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final vm = context.read<AppointmentVm>();

      final _ = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      // Helper to combine date and time string
      DateTime combine(DateTime date, String time) {
        final parts = time.split(':');
        return DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      final startDt = combine(_selectedDate!, _selectedSlot!.timeStart);
      final endDt = combine(_selectedDate!, _selectedSlot!.timeEnd);

      final success = await vm.rescheduleAppointment(
        widget.appointment.id,
        startDt.toIso8601String(),
        endDt.toIso8601String(),
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
