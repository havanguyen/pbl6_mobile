import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../model/services/remote/work_location_service.dart';
import '../../shared/widgets/widget/location_form.dart';
import '../../shared/localization/app_localizations.dart';

class CreateLocationWorkPage extends StatelessWidget {
  const CreateLocationWorkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        title: Text(
          AppLocalizations.of(context).translate('create_location_title'),
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
        child: LocationForm(
          isUpdate: false,
          onSubmit:
              ({
                required name,
                required address,
                required phone,
                required timezone,
                id,
              }) async {
                return await LocationWorkService.createLocation(
                  name: name,
                  address: address,
                  phone: phone,
                  timezone: timezone,
                );
              },
          initialData: null,
        ),
      ),
    );
  }
}
