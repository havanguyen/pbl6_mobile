import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _editProfile(DoctorDetail doctor) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.editDoctorProfile,
      arguments: doctor,
    );
    if (result == true && mounted) {
      context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
    }
  }

  void _editAccount(DoctorDetail doctor) async {
    final doctorAsMap = {
      'id': doctor.id,
      'fullName': doctor.fullName,
      'email': doctor.email,
      'phone': doctor.phone,
      'isMale': doctor.isMale,
      'dateOfBirth': doctor.dateOfBirth?.toIso8601String(),
      'role': doctor.role,
    };
    final result = await Navigator.pushNamed(
      context,
      Routes.updateDoctor,
      arguments: doctorAsMap,
    );
    if (result == true && mounted) {
      context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
    }
  }

  void _showEditOptions(BuildContext context, DoctorDetail doctor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.account_box, color: context.theme.primary),
                title: const Text('Chỉnh sửa thông tin tài khoản'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editAccount(doctor);
                },
              ),
              ListTile(
                leading: Icon(Icons.medical_information,
                    color: context.theme.primary),
                title: const Text('Chỉnh sửa hồ sơ chuyên môn'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editProfile(doctor);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorVm = context.watch<DoctorVm>();
    final doctor = doctorVm.doctorDetail;
    final isOffline = doctorVm.isOffline;

    return Scaffold(
      appBar: AppBar(
        title: Text(doctor?.fullName ?? 'Đang tải...'),
        bottom: doctor == null
            ? null
            : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.work_outline), text: 'Hồ sơ Chi tiết'),
          ],
        ),
      ),
      body: doctorVm.isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : doctor == null
          ? const Center(child: Text('Không thể tải dữ liệu bác sĩ'))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(doctor, isOffline),
          _buildProfileTab(doctor),
        ],
      ),
      floatingActionButton: (doctor == null || isOffline)
          ? null
          : FloatingActionButton(
        onPressed: () => _showEditOptions(context, doctor),
        backgroundColor: context.theme.primary,
        tooltip: 'Chỉnh sửa',
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildOverviewTab(DoctorDetail doctor, bool isOffline) {
    bool isValidUrl(String? url) {
      if (url == null || url.isEmpty) return false;
      return Uri.tryParse(url)?.hasAbsolutePath ?? false;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                    style: TextStyle(
                        fontSize: 50, color: context.theme.primary),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  doctor.fullName,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  doctor.degree ?? 'Chưa có thông tin học vị',
                  style:
                  TextStyle(fontSize: 18, color: context.theme.mutedForeground),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Trạng thái hoạt động'),
                  value: doctor.isActive,
                  onChanged: isOffline
                      ? null
                      : (value) {
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      children: [
        if (doctor.introduction != null && doctor.introduction!.isNotEmpty)
          _buildExpansionHtmlSection("Giới thiệu", doctor.introduction!),
        _buildExpansionListSection("Chức vụ", doctor.position),
        _buildExpansionListSection("Thành viên hiệp hội", doctor.memberships),
        _buildExpansionListSection("Giải thưởng", doctor.awards),
        _buildExpansionListSection("Quá trình đào tạo", doctor.trainingProcess),
        _buildExpansionListSection("Kinh nghiệm", doctor.experience),
        if (doctor.research != null && doctor.research!.isNotEmpty)
          _buildExpansionHtmlSection("Nghiên cứu khoa học", doctor.research!),
      ],
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionHtmlSection(String title, String content) {
    String htmlContent;
    try {
      final deltaJson = jsonDecode(content);
      final converter = QuillDeltaToHtmlConverter(List.castFrom(deltaJson));
      htmlContent = converter.convert();
    } catch (e) {
      htmlContent = content.replaceAll('\n', '<br>');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Html(
              data: htmlContent,
              onLinkTap: (url, _, __) async {
                if (url != null && await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
              style: {
                "body": Style(
                  fontSize: FontSize(15),
                  color: context.theme.mutedForeground,
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExpansionListSection(String title, List<String>? items) {
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: items
            .map((item) => ListTile(
          leading: Icon(Icons.check_circle_outline,
              color: context.theme.green, size: 18),
          title: Text(item),
        ))
            .toList(),
      ),
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