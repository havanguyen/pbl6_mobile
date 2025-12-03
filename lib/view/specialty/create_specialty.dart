import 'package:flutter/material.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import '../../shared/widgets/widget/specialty_form.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class CreateSpecialtyPage extends StatelessWidget {
  const CreateSpecialtyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        title: Text(
          AppLocalizations.of(context).translate('create_specialty_title'),
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
        child: SpecialtyForm(
          isUpdate: false,
          onSubmit: ({required name, description, id}) async {
            return await Provider.of<SpecialtyVm>(
              context,
              listen: false,
            ).createSpecialty(name: name, description: description);
          },
        ),
      ),
    );
  }
}
