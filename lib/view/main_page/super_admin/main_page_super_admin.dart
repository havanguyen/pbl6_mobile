import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../../shared/routes/routes.dart';
import '../../../shared/widgets/animation/scale_animation.dart';
import '../../../shared/widgets/button/custom_circular_button.dart';

class MainPageSuperAdmin extends StatelessWidget {
  const MainPageSuperAdmin({super.key});

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
                    key: const ValueKey('main_page_settings_button'),
                    icon: Icon(Icons.menu, color: context.theme.white, size: 35),
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.settingSuperAdmin);
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
                key: const ValueKey('main_page_appointment_button'),
                child: CustomCircularButton(
                  context,
                  size: 110,
                  icon: Icons.calendar_today_outlined,
                  label: 'QUẢN LÝ LỊCH KHÁM',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.listAppointment);
                  },
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.37,
              right: size.width * 0.15,
              child: ScaleAnimatedButton(
                key: const ValueKey('main_page_doctor_button'),
                child: CustomCircularButton(
                  context,
                  size: 110,
                  icon: Icons.question_answer_outlined,
                  label: 'QUẢN LÝ BÁC SĨ',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.listDoctor);
                  },
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.45,
              left: size.width * 0.15,
              child: ScaleAnimatedButton(
                key: const ValueKey('main_page_question_button'),
                child: CustomCircularButton(
                  context,
                  size: 140,
                  icon: Icons.rate_review_outlined,
                  label: 'QUẢN LÝ MỤC HỎI ĐÁP',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.listQuestion);
                  },
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.53,
              right: size.width * 0.15,
              child: ScaleAnimatedButton(
                key: const ValueKey('main_page_blog_button'),
                child: CustomCircularButton(
                  context,
                  size: 120,
                  icon: Icons.article_outlined,
                  label: 'QUẢN LÝ BLOG',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.listBlog);
                  },
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.63,
              left: size.width * 0.25,
              child: ScaleAnimatedButton(
                key: const ValueKey('admin_management_button'),
                child: CustomCircularButton(
                  context,
                  size: 140,
                  icon: Icons.lock_reset_outlined,
                  label: 'QUẢN LÝ TÀI KHOẢN ADMIN',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.listAdmin);
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
                  'Bạn đang đăng nhập với tư cách là super admin',
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