import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../model/services/remote/work_location_service.dart';
import '../../shared/widgets/widget/location_form.dart';
import '../../shared/localization/app_localizations.dart';

class UpdateLocationWorkPage extends StatelessWidget {
  final WorkLocation location;

  const UpdateLocationWorkPage({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        title: Text(
          AppLocalizations.of(context).translate('update_location_title'),
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
          isUpdate: true,
          initialData: location,
          onSubmit:
              ({
                required name,
                required address,
                required phone,
                required timezone,
                googleMapUrl,
                id,
              }) async {
                return await LocationWorkService.updateLocation(
                  id: id!,
                  name: name,
                  address: address,
                  phone: phone,
                  timezone: timezone,
                  googleMapUrl: googleMapUrl,
                );
              },
        ),
      ),
    );
  }
}
