import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/office_hour.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view/setting/office_hours/create_office_hour_page.dart';
import 'package:pbl6mobile/view_model/setting/office_hours_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class OfficeHoursPage extends StatefulWidget {
  const OfficeHoursPage({super.key});

  @override
  State<OfficeHoursPage> createState() => _OfficeHoursPageState();
}

class _OfficeHoursPageState extends State<OfficeHoursPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfficeHoursVm>().fetchOfficeHours();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getDayName(BuildContext context, int day) {
    switch (day) {
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

  String _formatTime(String time) {
    // Assuming time is in HH:mm:ss or HH:mm format
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final date = DateTime(2024, 1, 1, hour, minute);
      // Simple AM/PM formatting
      final hour12 = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minuteStr = date.minute.toString().padLeft(2, '0');
      return '$hour12:$minuteStr $period';
    } catch (e) {
      return time;
    }
  }

  List<OfficeHour> _filterOfficeHours(List<OfficeHour> allHours, int tabIndex) {
    switch (tabIndex) {
      case 0: // All
        return allHours;
      case 1: // Doctor at Location
        return allHours
            .where(
              (h) =>
                  !h.isGlobal && h.doctorId != null && h.workLocationId != null,
            )
            .toList();
      case 2: // Doctor (All Locations)
        return allHours
            .where(
              (h) =>
                  !h.isGlobal && h.doctorId != null && h.workLocationId == null,
            )
            .toList();
      case 3: // Work Location
        return allHours
            .where(
              (h) =>
                  !h.isGlobal && h.doctorId == null && h.workLocationId != null,
            )
            .toList();
      case 4: // Global
        return allHours.where((h) => h.isGlobal).toList();
      default:
        return allHours;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OfficeHoursVm>();

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).translate('office_hours_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.theme.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateOfficeHourPage(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: context.theme.white,
          labelColor: context.theme.white,
          unselectedLabelColor: context.theme.white.withOpacity(0.7),
          tabs: [
            Tab(
              text:
                  '${AppLocalizations.of(context).translate('all')} (${vm.officeHours.length})',
            ),
            Tab(
              text: AppLocalizations.of(context).translate('doctor_at_loc_tab'),
            ),
            Tab(
              text: AppLocalizations.of(context).translate('doctor_only_tab'),
            ),
            Tab(
              text: AppLocalizations.of(context).translate('location_only_tab'),
            ),
            Tab(text: AppLocalizations.of(context).translate('global_tab')),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
          ? Center(child: Text(vm.error!))
          : TabBarView(
              controller: _tabController,
              children: List.generate(5, (index) {
                final filteredHours = _filterOfficeHours(vm.officeHours, index);
                return RefreshIndicator(
                  onRefresh: () => vm.fetchOfficeHours(),
                  child: filteredHours.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('no_office_hours_found'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredHours.length,
                          itemBuilder: (context, i) {
                            return _buildOfficeHourCard(
                              context,
                              filteredHours[i],
                              vm,
                            );
                          },
                        ),
                );
              }),
            ),
    );
  }

  Widget _buildOfficeHourCard(
    BuildContext context,
    OfficeHour item,
    OfficeHoursVm vm,
  ) {
    final isGlobal = item.isGlobal;
    final isDoctorSpecific = item.doctorId != null;
    final isLocationSpecific = item.workLocationId != null;

    Color borderColor;
    Color bgColor;
    Color textColor;
    String badgeText;

    if (isGlobal) {
      borderColor = Colors.blue.shade200;
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      badgeText = AppLocalizations.of(context).translate('global_badge');
    } else if (isDoctorSpecific && isLocationSpecific) {
      borderColor = Colors.green.shade200;
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      badgeText = AppLocalizations.of(context).translate('doctor_loc_badge');
    } else if (isDoctorSpecific) {
      borderColor = Colors.purple.shade200;
      bgColor = Colors.purple.shade50;
      textColor = Colors.purple.shade700;
      badgeText = AppLocalizations.of(context).translate('doctor_badge');
    } else {
      borderColor = Colors.orange.shade200;
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      badgeText = AppLocalizations.of(context).translate('location_badge');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.5),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: context.theme.destructive,
                  ),
                  onPressed: () => _confirmDelete(context, item, vm),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: context.theme.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_getDayName(context, item.dayOfWeek)}: ${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.theme.textColor,
                  ),
                ),
              ],
            ),
            if (isDoctorSpecific || isLocationSpecific) ...[
              const SizedBox(height: 8),
              if (isDoctorSpecific && item.doctor != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: context.theme.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.doctor!.fullName,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.theme.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isLocationSpecific && item.workLocation != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: context.theme.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.workLocation!.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.theme.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, OfficeHour item, OfficeHoursVm vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(
            context,
          ).translate('delete_office_hour_confirm_title'),
        ),
        content: Text(
          AppLocalizations.of(
            context,
          ).translate('delete_office_hour_confirm_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await vm.deleteOfficeHour(item.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      ).translate('delete_office_hour_success'),
                    ),
                  ),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
