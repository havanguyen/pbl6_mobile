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

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final patientVm = Provider.of<PatientVm>(context, listen: false);
    patientVm.loadPatients(isRefresh: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        patientVm.loadPatients();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientVm = context.watch<PatientVm>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Bệnh nhân'),
        backgroundColor: context.theme.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              patientVm.includeDeleted
                  ? Icons.history
                  : Icons.history_toggle_off,
            ),
            onPressed: () {
              patientVm.toggleIncludeDeleted();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => patientVm.loadPatients(isRefresh: true),
        child: patientVm.isLoading && patientVm.patients.isEmpty
            ? _buildShimmerLoading()
            : _buildPatientList(patientVm),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Routes.createPatient);
        },
        backgroundColor: context.theme.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPatientList(PatientVm patientVm) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: patientVm.patients.length + (patientVm.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == patientVm.patients.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final patient = patientVm.patients[index];
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
                        Navigator.pushNamed(
                          context,
                          Routes.updatePatient,
                          arguments: patient,
                        );
                      },
                      backgroundColor: context.theme.green,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Sửa',
                    ),
                    SlidableAction(
                      onPressed: (context) {
                        if (isDeleted) {
                          patientVm.restorePatient(patient.id);
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => PatientDeleteConfirmDialog(
                              patient: patient,
                            ),
                          );
                        }
                      },
                      backgroundColor:
                      isDeleted ? context.theme.blue : context.theme.red,
                      foregroundColor: Colors.white,
                      icon: isDeleted ? Icons.restore : Icons.delete,
                      label: isDeleted ? 'Khôi phục' : 'Xóa',
                    ),
                  ],
                ),
                child: _buildPatientTile(patient, isDeleted),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientTile(Patient patient, bool isDeleted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDeleted
            ? context.theme.grey.withOpacity(0.3)
            : context.theme.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.theme.blue.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: context.theme.blue,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDeleted ? context.theme.grey : context.theme.bg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  patient.email,
                  style: TextStyle(
                    color: context.theme.grey,
                  ),
                ),
                if (patient.phone != null)
                  Text(
                    patient.phone!,
                    style: TextStyle(
                      color: context.theme.grey,
                    ),
                  ),
                if (patient.dateOfBirth != null)
                  Text(
                    'Ngày sinh: ${DateFormat('dd/MM/yyyy').format(patient.dateOfBirth!)}',
                    style: TextStyle(
                      color: context.theme.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
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
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}