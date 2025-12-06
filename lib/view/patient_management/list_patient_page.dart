import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
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
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    final patientVm = Provider.of<PatientVm>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientVm>(
        context,
        listen: false,
      ).loadPatients(isRefresh: true);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        patientVm.loadPatients();
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
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
        backgroundColor: context.theme.appBar,
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
            onPressed: () {
              patientVm.toggleIncludeDeleted();
            },
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: Column(
        children: [
          _buildSearchBar(),
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
            : context.theme.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: context.theme.textColor),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(
            context,
          ).translate('search_patient_hint'),
          hintStyle: TextStyle(
            color: context.theme.mutedForeground.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.theme.primary,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: context.theme.border.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.theme.primary, width: 1.5),
          ),
          filled: true,
          fillColor: context.theme.input,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.theme.grey.withOpacity(0.3),
      padding: const EdgeInsets.all(8),
      child: Text(
        AppLocalizations.of(context).translate('offline_banner'),
        textAlign: TextAlign.center,
        style: TextStyle(color: context.theme.bg, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildPatientList(PatientVm patientVm) {
    final displayedPatients = patientVm.patients.where((patient) {
      final query = _searchText.toLowerCase();
      return patient.fullName.toLowerCase().contains(query) ||
          (patient.email?.toLowerCase().contains(query) ?? false) ||
          (patient.phone?.contains(query) ?? false);
    }).toList();

    if (displayedPatients.isEmpty && !patientVm.isLoading) {
      return Center(
        child: Text(
          AppLocalizations.of(context).translate('no_patients_found'),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: displayedPatients.length + (patientVm.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayedPatients.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final patient = displayedPatients[index];
        bool isDeleted = patient.deletedAt != null;
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Slidable(
                key: ValueKey(patient.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        if (patientVm.isOffline) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('offline_edit_error'),
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
                      backgroundColor: context.theme.green,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: AppLocalizations.of(context).translate('edit'),
                    ),
                    SlidableAction(
                      onPressed: (context) {
                        if (patientVm.isOffline) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('offline_delete_error'),
                              ),
                            ),
                          );
                          return;
                        }
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
                          ? context.theme.blue
                          : context.theme.red,
                      foregroundColor: Colors.white,
                      icon: isDeleted ? Icons.restore : Icons.delete,
                      label: isDeleted
                          ? AppLocalizations.of(context).translate('restore')
                          : AppLocalizations.of(context).translate('delete'),
                    ),
                  ],
                ),
                child: _buildPatientTile(patient, isDeleted, patientVm),
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
    final titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: isDeleted ? context.theme.grey : null,
      decoration: isDeleted ? TextDecoration.lineThrough : TextDecoration.none,
    );

    IconData genderIcon = Icons.person;
    Color genderColor = context.theme.grey;
    if (patient.isMale != null) {
      if (patient.isMale!) {
        genderIcon = Icons.male;
        genderColor = context.theme.blue;
      } else {
        genderIcon = Icons.female;
        genderColor = Colors.pink;
      }
    }

    return GestureDetector(
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
        Navigator.pushNamed(context, Routes.updatePatient, arguments: patient);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        elevation: 2,
        shadowColor: context.theme.border.withOpacity(0.1),
        color: isDeleted
            ? context.theme.muted.withOpacity(0.1)
            : context.theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 16,
          ),
          leading: CircleAvatar(
            backgroundColor: genderColor.withOpacity(0.1),
            child: Icon(genderIcon, color: genderColor),
          ),
          title: Text(patient.fullName, style: titleStyle),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (patient.email != null)
                _buildInfoRow(
                  context,
                  Icons.email_outlined,
                  patient.email!,
                  isDeleted,
                ),
              if (patient.phone != null)
                _buildInfoRow(
                  context,
                  Icons.phone_outlined,
                  patient.phone!,
                  isDeleted,
                ),
              if (patient.dateOfBirth != null)
                _buildInfoRow(
                  context,
                  Icons.cake_outlined,
                  DateFormat('dd/MM/yyyy').format(patient.dateOfBirth!),
                  isDeleted,
                ),
              if (isDeleted)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Chip(
                    label: Text(
                      AppLocalizations.of(context).translate('deleted'),
                    ),
                    backgroundColor: context.theme.grey.withOpacity(0.2),
                    labelStyle: TextStyle(
                      fontSize: 10,
                      color: context.theme.grey,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    visualDensity: VisualDensity.compact,
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
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.theme.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.theme.grey,
                fontSize: 12,
                decoration: isDeleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: context.theme.grey.withOpacity(0.3),
      highlightColor: context.theme.grey.withOpacity(0.1),
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
              leading: const CircleAvatar(backgroundColor: Colors.white),
              title: Container(width: 150, height: 16, color: Colors.white),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(width: 200, height: 12, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(width: 100, height: 12, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
