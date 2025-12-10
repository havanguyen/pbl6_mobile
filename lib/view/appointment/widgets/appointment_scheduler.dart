import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/dto/appointment_dto.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
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
    final theme = context.theme;

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
          height: 380, // Slightly increased height for better breathing room
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (widget.isLoadingDates)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(color: theme.primary),
                  ),
                )
              else
                SfCalendar(
                  controller: _calendarController,
                  view: CalendarView.month,
                  headerHeight: 50,
                  viewHeaderHeight: 40,
                  backgroundColor: Colors.transparent,
                  headerStyle: CalendarHeaderStyle(
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  viewHeaderStyle: ViewHeaderStyle(
                    dayTextStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.mutedForeground,
                    ),
                  ),
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode: MonthAppointmentDisplayMode.none,
                    showTrailingAndLeadingDates: false,
                    dayFormat: 'EEE',
                  ),
                  onTap: (details) {
                    if (details.targetElement == CalendarElement.calendarCell &&
                        details.date != null) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final isPast = details.date!.isBefore(today);

                      if (isPast) return; // Strictly disable past dates

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

                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final isPast = details.date.isBefore(today);

                    Color? textColor;
                    Color? bgColor;
                    BoxDecoration? decoration;

                    if (isSelected) {
                      bgColor = theme.primary;
                      textColor = theme.primaryForeground;
                      decoration = BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      );
                    } else if (isAvailable && !isPast) {
                      textColor = theme.textColor;
                    } else {
                      textColor = theme.mutedForeground.withOpacity(
                        0.5,
                      ); // Disabled/Past dates
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
                              fontSize: 14,
                            ),
                          ),
                          if (isAvailable && !isSelected && !isPast)
                            Positioned(
                              bottom: 6,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: theme.primary,
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
        const SizedBox(height: 24),

        // 2. Time Slots
        Text(
          AppLocalizations.of(context).translate('select_time'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 12),

        if (widget.selectedDate == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.muted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.border, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 32,
                  color: theme.mutedForeground,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please select a date first',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.mutedForeground, fontSize: 14),
                ),
              ],
            ),
          )
        else if (widget.isLoadingSlots)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.border),
            ),
            child: Center(
              child: CircularProgressIndicator(color: theme.primary),
            ),
          )
        else if (widget.slots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.destructive.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.destructive.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 32,
                  color: theme.destructive,
                ),
                const SizedBox(height: 8),
                Text(
                  'No available time slots for the selected date.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.destructive,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.border),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.slots.map((slot) {
                      final isSelected =
                          widget.selectedSlot != null &&
                          widget.selectedSlot!.timeStart == slot.timeStart &&
                          widget.selectedSlot!.timeEnd == slot.timeEnd;
                      return InkWell(
                        onTap: () => widget.onSlotSelect(slot),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width:
                              (MediaQuery.of(context).size.width - 80) /
                              3, // 3 columns with padding adjustment
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primary : theme.card,
                            border: Border.all(
                              color: isSelected ? theme.primary : theme.border,
                              width: isSelected ? 0 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.primary.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                slot.timeStart,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.primaryForeground
                                      : theme.textColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'to ${slot.timeEnd}',
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.primaryForeground.withOpacity(0.9)
                                      : theme.mutedForeground,
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '${widget.slots.length} available time slots',
                  style: TextStyle(color: theme.mutedForeground, fontSize: 12),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
