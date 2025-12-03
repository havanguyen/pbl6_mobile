import 'package:flutter/material.dart';
import 'package:pbl6mobile/view_model/appointment/appointment_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class CalendarSettingsDialog extends StatefulWidget {
  const CalendarSettingsDialog({super.key});

  @override
  State<CalendarSettingsDialog> createState() => _CalendarSettingsDialogState();
}

class _CalendarSettingsDialogState extends State<CalendarSettingsDialog> {
  late double _startHour;
  late double _endHour;
  late Map<int, bool> _workingDays;
  late String _badgeVariant;

  @override
  void initState() {
    super.initState();
    final vm = context.read<AppointmentVm>();
    _startHour = vm.startHour;
    _endHour = vm.endHour;
    _workingDays = Map.from(vm.workingDays);
    _badgeVariant = vm.badgeVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).translate('calendar_settings_title'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      AppLocalizations.of(context).translate('display_hours'),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_startHour.toInt()}:00',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_endHour.toInt()}:00',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: RangeValues(_startHour, _endHour),
                            min: 0,
                            max: 24,
                            divisions: 24,
                            labels: RangeLabels(
                              '${_startHour.toInt()}:00',
                              '${_endHour.toInt()}:00',
                            ),
                            onChanged: (RangeValues values) {
                              if (values.end - values.start >= 1) {
                                setState(() {
                                  _startHour = values.start;
                                  _endHour = values.end;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      AppLocalizations.of(context).translate('card_appearance'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildBadgeOption(
                          'colored',
                          AppLocalizations.of(
                            context,
                          ).translate('background_color'),
                          Icons.rectangle,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildBadgeOption(
                          'dot',
                          AppLocalizations.of(context).translate('dot'),
                          Icons.circle,
                          Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _buildBadgeOption(
                          'mixed',
                          AppLocalizations.of(context).translate('mixed'),
                          Icons.view_sidebar,
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      AppLocalizations.of(context).translate('working_days'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (index) {
                        final dayIndex = index + 1;
                        final isSelected = _workingDays[dayIndex] ?? true;
                        return FilterChip(
                          label: Text(_getDayName(dayIndex)),
                          selected: isSelected,
                          onSelected: (bool value) {
                            setState(() {
                              _workingDays[dayIndex] = value;
                            });
                          },
                          checkmarkColor: Colors.white,
                          selectedColor: theme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AppointmentVm>().updateCalendarSettings(
                          startHour: _startHour,
                          endHour: _endHour,
                          workingDays: _workingDays,
                          badgeVariant: _badgeVariant,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('save_changes'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildBadgeOption(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _badgeVariant == value;
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _badgeVariant = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.white,
            border: Border.all(
              color: isSelected ? theme.primaryColor : Colors.grey.shade200,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? theme.primaryColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(int dayIndex) {
    switch (dayIndex) {
      case DateTime.monday:
        return AppLocalizations.of(context).translate('mon');
      case DateTime.tuesday:
        return AppLocalizations.of(context).translate('tue');
      case DateTime.wednesday:
        return AppLocalizations.of(context).translate('wed');
      case DateTime.thursday:
        return AppLocalizations.of(context).translate('thu');
      case DateTime.friday:
        return AppLocalizations.of(context).translate('fri');
      case DateTime.saturday:
        return AppLocalizations.of(context).translate('sat');
      case DateTime.sunday:
        return AppLocalizations.of(context).translate('sun');
      default:
        return '';
    }
  }
}
