import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class DoctorDetailPage extends StatefulWidget {
  final String doctorId;

  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorVm = context.watch<DoctorVm>();
    final doctor = doctorVm.doctorDetail;

    return Scaffold(
      appBar: AppBar(
        title: Text(doctor?.fullName ?? 'Đang tải...'),
        bottom: doctor == null
            ? null
            : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.work), text: 'Hồ sơ'),
            Tab(icon: Icon(Icons.manage_accounts), text: 'Tài khoản'),
          ],
        ),
        actions: [
          if (doctor != null)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Chỉnh sửa hồ sơ chuyên môn',
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  Routes.editDoctorProfile,
                  arguments: doctor,
                );
                if (result == true) {
                  doctorVm.fetchDoctorDetail(widget.doctorId);
                }
              },
            ),
        ],
      ),
      body: doctorVm.isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : doctor == null
          ? const Center(child: Text('Không thể tải dữ liệu bác sĩ'))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(doctor),
          _buildProfileTab(doctor),
          _buildAccountTab(doctor),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(DoctorDetail doctor) {
    bool isValidUrl(String? url) {
      if (url == null || url.isEmpty) return false;
      return Uri.tryParse(url)?.hasAbsolutePath ?? false;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: isValidUrl(doctor.avatarUrl)
                      ? NetworkImage(doctor.avatarUrl!)
                      : null,
                  child: !isValidUrl(doctor.avatarUrl)
                      ? Text(
                    doctor.fullName.isNotEmpty
                        ? doctor.fullName[0].toUpperCase()
                        : 'D',
                    style:
                    TextStyle(fontSize: 50, color: context.theme.primary),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  doctor.fullName,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  doctor.degree ?? 'Chưa có thông tin học vị',
                  style: TextStyle(
                      fontSize: 18, color: context.theme.mutedForeground),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Trạng thái hoạt động'),
                  value: doctor.isActive,
                  onChanged: (value) {
                    if (doctor.profileId != null) {
                      context
                          .read<DoctorVm>()
                          .toggleDoctorStatus(doctor.profileId!, value);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Bác sĩ này chưa có hồ sơ, không thể thay đổi trạng thái.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          _buildInfoSection(
            "Chuyên khoa",
            icon: Icons.medical_services,
            children: doctor.specialties.isNotEmpty
                ? doctor.specialties.map((e) => _buildChip(e.name)).toList()
                : [_buildInfoRow(null, "Chưa cập nhật", "")],
          ),
          _buildInfoSection(
            "Nơi công tác",
            icon: Icons.location_city,
            children: doctor.workLocations.isNotEmpty
                ? doctor.workLocations.map((e) => _buildChip(e.name)).toList()
                : [_buildInfoRow(null, "Chưa cập nhật", "")],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(DoctorDetail doctor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (doctor.introduction != null && doctor.introduction!.isNotEmpty)
            _buildHtmlSection("Giới thiệu", doctor.introduction!),
          _buildListSection("Chức vụ", doctor.position),
          _buildListSection("Thành viên hiệp hội", doctor.memberships),
          _buildListSection("Giải thưởng", doctor.awards),
          _buildListSection("Quá trình đào tạo", doctor.trainingProcess),
          _buildListSection("Kinh nghiệm", doctor.experience),
          if (doctor.research != null && doctor.research!.isNotEmpty)
            _buildHtmlSection("Nghiên cứu khoa học", doctor.research!),
        ],
      ),
    );
  }

  Widget _buildAccountTab(DoctorDetail doctor) {
    final doctorAsMap = {
      'id': doctor.id,
      'fullName': doctor.fullName,
      'email': doctor.email,
      'phone': doctor.phone,
      'isMale': doctor.isMale,
      'dateOfBirth': doctor.dateOfBirth?.toIso8601String(),
      'role': doctor.role,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInfoSection(
            "Thông tin tài khoản",
            icon: Icons.person_pin_rounded,
            children: [
              _buildInfoRow(Icons.email, "Email", doctor.email),
              _buildInfoRow(
                  Icons.phone, "Điện thoại", doctor.phone ?? 'Chưa cập nhật'),
              _buildInfoRow(
                  Icons.cake,
                  "Ngày sinh",
                  doctor.dateOfBirth?.toString().split(' ')[0] ??
                      'Chưa cập nhật'),
              _buildInfoRow(
                  Icons.person,
                  "Giới tính",
                  doctor.isMale == null
                      ? 'Chưa cập nhật'
                      : (doctor.isMale! ? 'Nam' : 'Nữ')),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa tài khoản'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: context.theme.primary,
              foregroundColor: context.theme.primaryForeground,
            ),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                Routes.updateDoctor,
                arguments: doctorAsMap,
              );
              if (result == true) {
                context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
              }
            },
          )
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title,
      {IconData? icon, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: context.theme.primary, size: 22),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(spacing: 8, runSpacing: 8, children: children),
          ],
        ),
      ),
    );
  }

  Widget _buildHtmlSection(String title, String content) {
    String htmlContent;
    try {
      final deltaJson = jsonDecode(content);
      final converter = QuillDeltaToHtmlConverter(List.castFrom(deltaJson));
      htmlContent = converter.convert();
    } catch (e) {
      htmlContent = content.replaceAll('\n', '<br>');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Html(
              data: htmlContent,
              onLinkTap: (url, _, __) async {
                if (url != null && await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
              style: {
                "body": Style(
                  fontSize: FontSize(16),
                  color: context.theme.mutedForeground,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(String title, List<String>? items) {
    if (items == null || items.isEmpty) {
      return _buildInfoSection(title, children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Chưa cập nhật",
              style: TextStyle(color: context.theme.mutedForeground)),
        )
      ]);
    }

    return _buildInfoSection(
      title,
      children: items
          .map((item) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              color: context.theme.green, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(item)),
        ],
      ))
          .toList(),
    );
  }

  Widget _buildInfoRow(IconData? icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: context.theme.primary, size: 20),
            const SizedBox(width: 16),
          ],
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: context.theme.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: context.theme.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: context.theme.primary),
    );
  }
}