import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/dto/appointment_dto.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AppointmentScheduler extends StatefulWidget {
  final List<String> availableDates;
  final List<DoctorSlot> slots;
  final bool isLoadingSlots;
  final bool isLoadingDates;
  final DateTime? selectedDate;
  final DoctorSlot? selectedSlot;
  final Function(DateTime) onDateSelect;
  final Function(DoctorSlot) onSlotSelect;
  final bool disabled;

  const AppointmentScheduler({
    super.key,
    required this.availableDates,
    required this.slots,
    required this.isLoadingSlots,
    required this.isLoadingDates,
    required this.selectedDate,
    required this.selectedSlot,
    required this.onDateSelect,
    required this.onSlotSelect,
    this.disabled = false,
  });

  @override
  State<AppointmentScheduler> createState() => _AppointmentSchedulerState();
}

class _AppointmentSchedulerState extends State<AppointmentScheduler> {
  final CalendarController _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.disabled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'Please select a doctor first',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Calendar View
        Container(
          height: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              if (widget.isLoadingDates)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SfCalendar(
                  controller: _calendarController,
                  view: CalendarView.month,
                  headerHeight: 40,
                  viewHeaderHeight: 40,
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode: MonthAppointmentDisplayMode.none,
                    showTrailingAndLeadingDates: false,
                    dayFormat: 'EEE',
                  ),
                  onTap: (details) {
                    if (details.targetElement == CalendarElement.calendarCell &&
                        details.date != null) {
                      final dateStr = DateFormat(
                        'yyyy-MM-dd',
                      ).format(details.date!);
                      if (widget.availableDates.contains(dateStr)) {
                        widget.onDateSelect(details.date!);
                      }
                    }
                  },
                  monthCellBuilder: (context, details) {
                    final dateStr = DateFormat(
                      'yyyy-MM-dd',
                    ).format(details.date);
                    final isAvailable = widget.availableDates.contains(dateStr);
                    final isSelected =
                        widget.selectedDate != null &&
                        details.date.year == widget.selectedDate!.year &&
                        details.date.month == widget.selectedDate!.month &&
                        details.date.day == widget.selectedDate!.day;
                    final isPast = details.date.isBefore(
                      DateTime.now().subtract(const Duration(days: 1)),
                    );

                    Color? textColor;
                    Color? bgColor;
                    BoxDecoration? decoration;

                    if (isSelected) {
                      bgColor = theme.primaryColor;
                      textColor = Colors.white;
                      decoration = BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      );
                    } else if (isAvailable && !isPast) {
                      textColor = Colors.black;
                      // Add a dot indicator
                    } else {
                      textColor = Colors.grey.shade400;
                    }

                    return Container(
                      alignment: Alignment.center,
                      decoration: decoration,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            details.date.day.toString(),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: isAvailable && !isPast
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isAvailable && !isSelected && !isPast)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Time Slots
        const Text(
          'Select appointment time slot',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),

        if (widget.selectedDate == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade200,
                style: BorderStyle.solid,
              ),
            ),
            child: const Text(
              'Please select a date first',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          )
        else if (widget.isLoadingSlots)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (widget.slots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'No available time slots for the selected date.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.slots.map((slot) {
                      final isSelected = widget.selectedSlot == slot;
                      return InkWell(
                        onTap: () => widget.onSlotSelect(slot),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width:
                              (MediaQuery.of(context).size.width - 64) /
                              3, // 3 columns
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? theme.primaryColor
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              Text(
                                slot.timeStart,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'to ${slot.timeEnd}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.slots.length} available time slots',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
      ],
    );
  }
}
