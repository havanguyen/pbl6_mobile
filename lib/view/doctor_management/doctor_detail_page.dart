import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorDetailPage extends StatefulWidget {
  final String doctorId;

  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
    });
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final doctorVm = context.watch<DoctorVm>();
    final doctor = doctorVm.doctorDetail;

    return Scaffold(
      appBar: AppBar(
        title: Text(doctor?.fullName ?? 'Đang tải...'),
        actions: [
          if (doctor != null)
            IconButton(
              icon: const Icon(Icons.edit),
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
          : _buildDoctorProfile(doctor),
    );
  }

  Widget _buildDoctorProfile(DoctorDetail doctor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(doctor),
          const SizedBox(height: 24),
          _buildInfoSection("Thông tin cá nhân", [
            _buildInfoRow(Icons.email, "Email", doctor.email),
            _buildInfoRow(Icons.phone, "Điện thoại", doctor.phone ?? 'Chưa cập nhật'),
            _buildInfoRow(Icons.cake, "Ngày sinh",
                doctor.dateOfBirth?.toString().split(' ')[0] ?? 'Chưa cập nhật'),
            _buildInfoRow(Icons.person, "Giới tính",
                doctor.isMale == null ? 'Chưa cập nhật' : (doctor.isMale! ? 'Nam' : 'Nữ')),
          ]),
          _buildInfoSection("Hồ sơ chuyên môn", [
            _buildInfoRow(Icons.school, "Học vị", doctor.degree ?? 'Chưa cập nhật'),
            _buildInfoRow(
                Icons.work, "Chức vụ", doctor.position?.join(', ') ?? 'Chưa cập nhật'),
            _buildInfoRow(
                Icons.star, "Giải thưởng", doctor.awards?.join(', ') ?? 'Chưa cập nhật'),
          ]),
          if (doctor.introduction != null && doctor.introduction!.isNotEmpty)
            _buildHtmlSection("Giới thiệu", doctor.introduction!),
          const SizedBox(height: 24),
          if (doctor.specialties.isNotEmpty)
            _buildListSection(
                "Chuyên khoa", doctor.specialties.map((e) => e.name).toList()),
          if (doctor.workLocations.isNotEmpty)
            _buildListSection(
                "Nơi công tác", doctor.workLocations.map((e) => e.name).toList()),
        ],
      ),
    );
  }

  Widget _buildHeader(DoctorDetail doctor) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
            _isValidUrl(doctor.avatarUrl) ? NetworkImage(doctor.avatarUrl!) : null,
            child: !_isValidUrl(doctor.avatarUrl)
                ? Text(
              doctor.fullName.isNotEmpty ? doctor.fullName[0].toUpperCase() : 'D',
              style: TextStyle(fontSize: 40, color: context.theme.primary),
            )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            doctor.fullName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            doctor.degree ?? 'Chưa có thông tin',
            style: TextStyle(
              fontSize: 18,
              color: context.theme.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(
              'Trạng thái hoạt động',
              style: TextStyle(color: context.theme.textColor),
            ),
            value: doctor.isActive,
            onChanged: (value) {
              if (doctor.profileId != null) {
                context.read<DoctorVm>().toggleDoctorStatus(doctor.profileId!, value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bác sĩ này chưa có hồ sơ, không thể thay đổi trạng thái.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.theme.textColor,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildHtmlSection(String title, String htmlContent) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.theme.textColor,
              ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.theme.primary, size: 20),
          const SizedBox(width: 16),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.theme.textColor,
            ),
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

  Widget _buildListSection(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.theme.textColor,
              ),
            ),
            const Divider(height: 24),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: context.theme.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(item,
                          style: TextStyle(color: context.theme.textColor))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}