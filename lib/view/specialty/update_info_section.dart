
import 'package:flutter/material.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../shared/widgets/widget/info_section_form.dart';

class UpdateInfoSectionPage extends StatelessWidget {
  final Map<String, dynamic> args;

  const UpdateInfoSectionPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final infoSection = args['infoSection'];
    final specialtyId = args['specialtyId'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        title: Text(
          'Chỉnh sửa phần thông tin',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: context.theme.bg,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: InfoSectionForm(
          isUpdate: true,
          initialData: infoSection,
          specialtyId: specialtyId,
          onSubmit: ({required name, required content, id}) async {
            return await Provider.of<SpecialtyVm>(context, listen: false).updateInfoSection(
              id: id!,
              name: name,
              content: content,
            );
          },
        ),
      ),
    );
  }
}