import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/office_hour.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view/setting/office_hours/create_office_hour_page.dart';
import 'package:pbl6mobile/view_model/setting/office_hours_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pbl6mobile/shared/extensions/office_hour_extensions.dart';

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

  List<OfficeHour> _filterOfficeHours(List<OfficeHour> allHours, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return allHours;
      case 1:
        return allHours
            .where(
              (h) =>
                  !h.isGlobal && h.doctorId != null && h.workLocationId != null,
            )
            .toList();
      case 2:
        return allHours
            .where(
              (h) =>
                  !h.isGlobal && h.doctorId != null && h.workLocationId == null,
            )
            .toList();
      case 3:
        return allHours
            .where(
              (h) =>
                  !h.isGlobal && h.doctorId == null && h.workLocationId != null,
            )
            .toList();
      case 4:
        return allHours.where((h) => h.isGlobal).toList();
      default:
        return allHours;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OfficeHoursVm>();
    // White text on colored AppBar requires explicit style or theme override
    // We use semantic colors but ensure Header text is white on Blue background

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
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
          ? Center(
              child: CircularProgressIndicator(color: context.theme.primary),
            )
          : vm.error != null
          ? Center(
              child: Text(
                AppLocalizations.of(context).translate(vm.error!),
                style: TextStyle(color: context.theme.destructive),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: List.generate(5, (index) {
                final filteredHours = _filterOfficeHours(vm.officeHours, index);
                return RefreshIndicator(
                  onRefresh: () => vm.fetchOfficeHours(),
                  color: context.theme.primary,
                  backgroundColor: context.theme.card,
                  child: filteredHours.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: context.theme.muted.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_today_outlined,
                                  size: 64,
                                  color: context.theme.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('no_office_hours_found'),
                                style: TextStyle(
                                  color: context.theme.foreground,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('add_new_office_hour_hint'),
                                style: TextStyle(
                                  color: context.theme.mutedForeground,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredHours.length,
                            itemBuilder: (context, i) {
                              return AnimationConfiguration.staggeredList(
                                position: i,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildOfficeHourCard(
                                      context,
                                      filteredHours[i],
                                      vm,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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

    Color badgeBg;
    Color badgeText;
    String labelText;
    IconData badgeIcon;

    String priorityLabel = '';

    if (isGlobal) {
      // Global System Default
      badgeBg = context.theme.muted;
      badgeText = context.theme.mutedForeground;
      labelText = 'Global Default';
      badgeIcon = Icons.public;
      priorityLabel = 'Lowest';
    } else if (!isDoctorSpecific && isLocationSpecific) {
      // Location Only
      badgeBg = context.theme.accent;
      badgeText = context.theme.accentForeground;
      labelText = AppLocalizations.of(context).translate('location_badge');
      badgeIcon = Icons.location_city;
      priorityLabel = 'Low';
    } else if (isDoctorSpecific && !isLocationSpecific) {
      // Doctor Only
      badgeBg = context.theme.primary.withOpacity(0.15);
      badgeText = context.theme.primary;
      labelText = AppLocalizations.of(context).translate('doctor_badge');
      badgeIcon = Icons.person;
      priorityLabel = 'Medium';
    } else if (isDoctorSpecific && isLocationSpecific) {
      // Specific
      badgeBg = context.theme.green.withOpacity(0.15);
      badgeText = context.theme.green;
      labelText = AppLocalizations.of(context).translate('doctor_loc_badge');
      badgeIcon = Icons.person_pin_circle;
      priorityLabel = 'Highest';
    } else {
      // Fallback
      badgeBg = context.theme.muted;
      badgeText = context.theme.mutedForeground;
      labelText = 'Unknown';
      badgeIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: context.theme.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Edit logic in future
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, size: 14, color: badgeText),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    labelText,
                                    style: TextStyle(
                                      color: badgeText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (priorityLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.theme.muted.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.theme.mutedForeground
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Priority: $priorityLabel',
                                style: TextStyle(
                                  color: context.theme.mutedForeground,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
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
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 20,
                      color: context.theme.blue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.dayOfWeek.getDayName(context),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context
                            .theme
                            .foreground, // Use 'foreground' for main text
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.theme.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.startTime.formatTime(context)} - ${item.endTime.formatTime(context)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: context.theme.foreground,
                      ),
                    ),
                  ],
                ),
                if (isDoctorSpecific || isLocationSpecific) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: context.theme.border),
                  const SizedBox(height: 12),
                  if (isDoctorSpecific && item.doctor != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: context.theme.mutedForeground,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.doctor!.fullName,
                              style: TextStyle(
                                fontSize: 14,
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
                          Icons.location_on,
                          size: 16,
                          color: context.theme.mutedForeground,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.workLocation!.name,
                            style: TextStyle(
                              fontSize: 14,
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
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, OfficeHour item, OfficeHoursVm vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(
            context,
          ).translate('delete_office_hour_confirm_title'),
          style: TextStyle(color: context.theme.foreground),
        ),
        content: Text(
          AppLocalizations.of(
            context,
          ).translate('delete_office_hour_confirm_message'),
          style: TextStyle(color: context.theme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: context.theme.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final successMsg = AppLocalizations.of(
                context,
              ).translate('delete_office_hour_success');
              final success = await vm.deleteOfficeHour(item.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: context.theme.green,
                    content: Text(
                      successMsg,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: TextStyle(color: context.theme.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
