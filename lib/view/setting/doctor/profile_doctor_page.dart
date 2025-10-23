import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/view/doctor_management/doctor_detail_page.dart';

class ProfileDoctorPage extends StatefulWidget {
  const ProfileDoctorPage({super.key});

  @override
  State<ProfileDoctorPage> createState() => _ProfileDoctorPageState();
}

class _ProfileDoctorPageState extends State<ProfileDoctorPage> {
  Future<DoctorDetail?> _fetchDoctorDetail() async {
    final profile = await AuthService.getProfile();
    if (profile != null) {
      return await DoctorService.getDoctorWithProfile(profile.id);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DoctorDetail?>(
      future: _fetchDoctorDetail(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text("Đang tải hồ sơ...")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Lỗi")),
            body: const Center(child: Text('Không thể tải hồ sơ chuyên môn.')),
          );
        }
        return DoctorDetailPage(doctorId: snapshot.data!.id, isSelfView: true);
      },
    );
  }
}