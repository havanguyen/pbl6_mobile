import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/widget/patient_delete_confirm.dart';
import 'package:pbl6mobile/view_model/patient/patient_vm.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset search on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientVm>(context, listen: false)
        ..setSearch('')
        ..loadPatients(isRefresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<PatientVm>().loadPatients();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientVm = context.watch<PatientVm>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('patient_management_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.theme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              patientVm.includeDeleted
                  ? Icons.history
                  : Icons.history_toggle_off,
              color: context.theme.white,
            ),
            tooltip: patientVm.includeDeleted
                ? 'Hide deleted'
                : 'Show deleted history',
            onPressed: () {
              patientVm.toggleIncludeDeleted();
            },
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: Column(
        children: [
          _buildSearchBar(patientVm),
          if (patientVm.isOffline) _buildOfflineBanner(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => patientVm.loadPatients(isRefresh: true),
              child: patientVm.isLoading && patientVm.patients.isEmpty
                  ? _buildShimmerLoading()
                  : _buildPatientList(patientVm),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (patientVm.isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  ).translate('offline_create_patient_error'),
                ),
              ),
            );
          } else {
            Navigator.pushNamed(context, Routes.createPatient);
          }
        },
        backgroundColor: patientVm.isOffline
            ? context.theme.grey
            : context.theme.primary,
        child: const Icon(Icons.add_outlined),
      ),
    );
  }

  Widget _buildSearchBar(PatientVm vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: context.theme.bg, // Match background for seamless look
      child: TextField(
        controller: _searchController,
        onChanged: (value) => vm.setSearch(value),
        style: TextStyle(color: context.theme.textColor),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(
            context,
          ).translate('search_patient_hint'),
          hintStyle: TextStyle(color: context.theme.mutedForeground),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.theme.primary,
            size: 24,
          ),
          filled: true,
          fillColor: context.theme.card, // Use card color for input background
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: context.theme.grey),
                  onPressed: () {
                    _searchController.clear();
                    vm.setSearch('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors
          .amber
          .shade100, // Warning color, keep generic for now or verify theme
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).translate('offline_banner'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.amber.shade900,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(PatientVm patientVm) {
    if (patientVm.patients.isEmpty && !patientVm.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: context.theme.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('no_patients_found'),
              style: TextStyle(
                color: context.theme.mutedForeground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: patientVm.patients.length + (patientVm.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == patientVm.patients.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.theme.primary,
                ),
              ),
            ),
          );
        }
        final patient = patientVm.patients[index];
        bool isDeleted = patient.deletedAt != null;
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Slidable(
                  key: ValueKey(patient.id),
                  enabled: !patientVm.isOffline,
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: isDeleted ? 0.25 : 0.5,
                    children: [
                      if (!isDeleted)
                        SlidableAction(
                          onPressed: (context) {
                            Navigator.pushNamed(
                              context,
                              Routes.updatePatient,
                              arguments: patient,
                            );
                          },
                          backgroundColor: context.theme.primary,
                          foregroundColor: Colors.white,
                          icon: Icons.edit_rounded,
                          label: AppLocalizations.of(context).translate('edit'),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                        ),
                      SlidableAction(
                        onPressed: (context) {
                          if (isDeleted) {
                            patientVm.restorePatient(patient.id);
                          } else {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  PatientDeleteConfirmDialog(patient: patient),
                            );
                          }
                        },
                        backgroundColor: isDeleted
                            ? context.theme.green
                            : context.theme.destructive,
                        foregroundColor: Colors.white,
                        icon: isDeleted
                            ? Icons.restore_from_trash_rounded
                            : Icons.delete_outline_rounded,
                        label: isDeleted
                            ? AppLocalizations.of(context).translate('restore')
                            : AppLocalizations.of(context).translate('delete'),
                        borderRadius: isDeleted
                            ? BorderRadius.circular(12)
                            : const BorderRadius.horizontal(
                                right: Radius.circular(12),
                              ),
                      ),
                    ],
                  ),
                  child: _buildPatientTile(patient, isDeleted, patientVm),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientTile(
    Patient patient,
    bool isDeleted,
    PatientVm patientVm,
  ) {
    // Avoid hardcoded colors, use theme or safely derive from theme
    // For gender, we can use theme colors or standard distinct colors
    Color avatarBg;
    IconData genderIcon;

    if (patient.isMale == true) {
      avatarBg = context.theme.blue.withOpacity(0.1);
      genderIcon = Icons.male;
    } else if (patient.isMale == false) {
      avatarBg = context.theme.secondary.withOpacity(
        0.1,
      ); // Use secondary (purple/pink often)
      genderIcon = Icons.female;
    } else {
      avatarBg = context.theme.grey.withOpacity(0.1);
      genderIcon = Icons.person_outline;
    }

    // Calculate Age
    String ageText = '';
    if (patient.dateOfBirth != null) {
      final age = DateTime.now().year - patient.dateOfBirth!.year;
      ageText = '$age';
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDeleted
          ? context.theme.muted.withOpacity(0.05)
          : context.theme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.theme.border.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (patientVm.isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).translate('offline_edit_error'),
                ),
              ),
            );
            return;
          }
          Navigator.pushNamed(
            context,
            Routes.updatePatient,
            arguments: patient,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    genderIcon,
                    // Use theme primary for male, accent/secondary for female to fit theme
                    color: patient.isMale == true
                        ? context.theme.blue
                        : (patient.isMale == false
                              ? context.theme.secondary
                              : context.theme.grey),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDeleted
                                  ? context.theme.mutedForeground
                                  : context.theme.textColor,
                              decoration: isDeleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ageText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.theme.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$ageText ${AppLocalizations.of(context).translate('years_old_suffix')}", // Fallback if trans missing
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.theme.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (patient.phone != null && patient.phone!.isNotEmpty)
                      _buildInfoRow(
                        context,
                        Icons.phone_rounded,
                        patient.phone!,
                        isDeleted,
                      ),
                    const SizedBox(height: 4),
                    if (patient.addressLine != null || patient.district != null)
                      _buildInfoRow(
                        context,
                        Icons.location_on_rounded,
                        [
                          patient.addressLine,
                          patient.district,
                          patient.province,
                        ].where((e) => e != null && e.isNotEmpty).join(', '),
                        isDeleted,
                      ),

                    if (isDeleted)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.theme.destructive.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_forever,
                                size: 12,
                                color: context.theme.destructive,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('deleted'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.theme.destructive,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text,
    bool isDeleted,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 14,
          color: context.theme.mutedForeground.withOpacity(0.7),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: context.theme.mutedForeground,
              fontSize: 13,
              decoration: isDeleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: context.theme.grey.withOpacity(0.1),
      highlightColor: context.theme.grey.withOpacity(0.05),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }
}
