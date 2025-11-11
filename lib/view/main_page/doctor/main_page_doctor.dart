import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../../shared/routes/routes.dart';
import '../../../shared/widgets/animation/scale_animation.dart';
import '../../../shared/widgets/button/custom_circular_button.dart';

class MainPageDoctor extends StatefulWidget {
  const MainPageDoctor({super.key});

  @override
  State<MainPageDoctor> createState() => _MainPageDoctorState();
}

class _MainPageDoctorState extends State<MainPageDoctor> {
  bool _isNavigating = false;

  Future<void> _navigateToReviews(BuildContext context) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    try {
      final profile = await AuthService.getProfile();
      if (profile == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải hồ sơ bác sĩ.')));
        return;
      }

      final doctorDetail =
      await DoctorService.getDoctorWithProfile(profile.id);
      if (doctorDetail == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải hồ sơ chuyên môn.')));
        return;
      }

      Navigator.pushNamed(
        context,
        Routes.doctorReviewPage,
        arguments: {
          'doctorId': doctorDetail.id,
          'doctorName': profile.fullName,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xảy ra lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_bd.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0x802196F3),
              BlendMode.overlay,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: size.height * 0.06,
              left: size.width * 0.01,
              child: ScaleAnimatedButton(
                child: Container(
                  decoration: BoxDecoration(
                      color: context.theme.blue, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(Icons.menu, color: context.theme.white, size: 35),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.settingDoctor);
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.05,
              right: size.width * 0.01,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    width: 200,
                    color: context.theme.blue,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Positioned(
              top: size.height * 0.3,
              left: size.width * 0.25,
              child: ScaleAnimatedButton(
                child: CustomCircularButton(
                  context,
                  size: 110,
                  icon: Icons.calendar_today_outlined,
                  label: 'QUẢN LÝ LỊCH TRÌNH',
                  onTap: () {
                    print('Quản lý lịch trình');
                  },
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.37,
              right: size.width * 0.15,
              child: ScaleAnimatedButton(
                child: CustomCircularButton(
                  context,
                  size: 110,
                  icon: Icons.question_answer_outlined,
                  label: 'TRẢ LỜI CÂU HỎI',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.listQuestion);
                  },
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.45,
              left: size.width * 0.15,
              child: ScaleAnimatedButton(
                child: CustomCircularButton(
                  context,
                  size: 140,
                  icon: Icons.rate_review_outlined,
                  label: 'CẢM NHẬN BỆNH NHÂN',
                  onTap: () => _navigateToReviews(context),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.53,
              right: size.width * 0.15,
              child: ScaleAnimatedButton(
                child: CustomCircularButton(
                  context,
                  size: 120,
                  icon: Icons.account_circle_outlined,
                  label: 'QUẢN LÝ HỒ SƠ',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.profileDoctor);
                  },
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.63,
              left: size.width * 0.25,
              child: ScaleAnimatedButton(
                child: CustomCircularButton(
                  context,
                  size: 140,
                  icon: Icons.lock_reset_outlined,
                  label: 'ĐỔI MẬT KHẨU',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.changePassword);
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Ứng dụng quản lý dành cho bác sĩ',
                  style: TextStyle(
                    color: context.theme.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}