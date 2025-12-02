import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/dto/appointment_dto.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';
import 'package:pbl6mobile/view/appointment/widgets/appointment_scheduler.dart';
import 'package:pbl6mobile/view_model/appointment/appointment_vm.dart';
import 'package:provider/provider.dart';

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
        title: const Text('Cập nhật lịch hẹn'),
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
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá tiền (VND)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        double.tryParse(value) == null) {
                      return 'Vui lòng nhập số hợp lệ';
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
            child: const Text('Hủy'),
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
                      const SnackBar(
                        content: Text('Cập nhật thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(vm.actionError ?? 'Có lỗi xảy ra'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Lưu'),
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
        title: const Text('Hủy lịch hẹn'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bạn có chắc chắn muốn hủy lịch hẹn này không?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Lý do hủy *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập lý do';
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
            child: const Text('Đóng'),
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
                      const SnackBar(
                        content: Text('Đã hủy lịch hẹn'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(vm.actionError ?? 'Có lỗi xảy ra'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Hủy Lịch Hẹn',
              style: TextStyle(color: Colors.white),
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
        title: const Text('Xác nhận lịch hẹn'),
        content: const Text('Bạn có chắc chắn muốn xác nhận lịch hẹn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
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
            const SnackBar(
              content: Text('Đã xác nhận lịch hẹn'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(vm.actionError ?? 'Có lỗi xảy ra'),
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
          title: const Text('Dời lịch hẹn'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _selectedSlot == null
                  ? null
                  : () => _confirmReschedule(),
              child: const Text('Lưu'),
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
        title: const Text('Xác nhận dời lịch'),
        content: Text(
          'Dời sang ${_selectedSlot!.timeStart} ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
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
            const SnackBar(
              content: Text('Dời lịch thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(vm.actionError ?? 'Có lỗi xảy ra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
