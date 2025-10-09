import 'package:flutter/material.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../shared/widgets/widget/specialty_form.dart';

class UpdateSpecialtyPage extends StatelessWidget {
  final Map<String, dynamic> specialty;

  const UpdateSpecialtyPage({super.key, required this.specialty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa chuyên khoa',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SpecialtyForm(
          isUpdate: true,
          initialData: specialty,
          onSubmit: ({required name, description, id}) async {
            return await Provider.of<SpecialtyVm>(context, listen: false)
                .updateSpecialty(
              id: id!,
              name: name,
              description: description,
            );
          },
        ),
      ),
    );
  }
}