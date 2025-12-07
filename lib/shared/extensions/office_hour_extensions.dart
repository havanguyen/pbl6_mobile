import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

extension OfficeHourUtils on int {
  String getDayName(BuildContext context) {
    switch (this) {
      case 0:
        return AppLocalizations.of(context).translate('sunday');
      case 1:
        return AppLocalizations.of(context).translate('monday');
      case 2:
        return AppLocalizations.of(context).translate('tuesday');
      case 3:
        return AppLocalizations.of(context).translate('wednesday');
      case 4:
        return AppLocalizations.of(context).translate('thursday');
      case 5:
        return AppLocalizations.of(context).translate('friday');
      case 6:
        return AppLocalizations.of(context).translate('saturday');
      default:
        return 'Unknown';
    }
  }
}

extension TimeFormatUtils on String {
  String formatTime(BuildContext context) {
    try {
      final parts = split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final date = DateTime(2024, 1, 1, hour, minute);
      final hour12 = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12
          ? AppLocalizations.of(context).translate('pm')
          : AppLocalizations.of(context).translate('am');
      final minuteStr = date.minute.toString().padLeft(2, '0');
      return '$hour12:$minuteStr $period';
    } catch (e) {
      return this;
    }
  }
}
