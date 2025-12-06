import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CustomCalendarHeader extends StatelessWidget {
  final CalendarController controller;
  final CalendarView currentView;
  final VoidCallback onTodayTap;
  final Function(CalendarView) onViewChanged;
  final VoidCallback onAddTap;

  const CustomCalendarHeader({
    super.key,
    required this.controller,
    required this.currentView,
    required this.onTodayTap,
    required this.onViewChanged,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayDate = controller.displayDate ?? DateTime.now();
    final dateText = DateFormat('MMMM yyyy').format(displayDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.theme.card,
        border: Border(bottom: BorderSide(color: context.theme.border)),
      ),
      child: Column(
        children: [
          // Top Row: Today, Date Navigator, Add Button
          Row(
            children: [
              // Today Button (Compact)
              IconButton(
                onPressed: onTodayTap,
                icon: Icon(Icons.today, color: context.theme.textColor),
                tooltip: 'Today',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: context.theme.border),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Date Navigator
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: context.theme.textColor,
                      ),
                      onPressed: () {
                        controller.backward!();
                      },
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.theme.textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: context.theme.textColor,
                      ),
                      onPressed: () {
                        controller.forward!();
                      },
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Add Event Button (Compact)
              FilledButton(
                onPressed: onAddTap,
                style: FilledButton.styleFrom(
                  backgroundColor: context.theme.primary,
                  foregroundColor: context.theme.primaryForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Row: View Switcher
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.theme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.theme.border),
                  ),
                  child: Row(
                    children: [
                      _buildViewButton(
                        context,
                        icon: Icons.view_day_outlined,
                        view: CalendarView.day,
                        tooltip: 'Day',
                      ),
                      _buildDivider(context),
                      _buildViewButton(
                        context,
                        icon: Icons.view_week_outlined,
                        view: CalendarView.week,
                        tooltip: 'Week',
                      ),
                      _buildDivider(context),
                      _buildViewButton(
                        context,
                        icon: Icons.grid_view,
                        view: CalendarView.month,
                        tooltip: 'Month',
                      ),
                      _buildDivider(context),
                      _buildViewButton(
                        context,
                        icon: Icons.calendar_view_month,
                        view: CalendarView.schedule,
                        tooltip: 'Schedule',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(
    BuildContext context, {
    required IconData icon,
    required CalendarView view,
    required String tooltip,
  }) {
    final isSelected = currentView == view;

    return Expanded(
      child: Material(
        color: isSelected ? context.theme.card : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => onViewChanged(view),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    color: context.theme.card,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: context.theme.mutedForeground.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  )
                : null,
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? context.theme.primary
                  : context.theme.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(width: 1, height: 20, color: context.theme.border);
  }
}
