import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view/dashboard/widgets/doctor_content_chart.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [const DoctorContentChart()]),
      ),
    );
  }
}
