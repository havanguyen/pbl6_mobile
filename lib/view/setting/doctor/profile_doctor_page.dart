import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/view/doctor_management/doctor_detail_page.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

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
            appBar: AppBar(
              title: Text(
                AppLocalizations.of(context).translate('loading_data'),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).translate('error')),
            ),
            body: Center(
              child: Text(
                AppLocalizations.of(
                  context,
                ).translate('error_load_doctor_profile'),
              ),
            ),
          );
        }
        return DoctorDetailPage(doctorId: snapshot.data!.id, isSelfView: true);
      },
    );
  }
}
