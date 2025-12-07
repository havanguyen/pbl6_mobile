import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/my_permission.dart';
import 'package:pbl6mobile/model/services/remote/permission_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class MyPermissionsPage extends StatefulWidget {
  const MyPermissionsPage({super.key});

  @override
  State<MyPermissionsPage> createState() => _MyPermissionsPageState();
}

class _MyPermissionsPageState extends State<MyPermissionsPage> {
  late Future<List<MyPermission>> _permissionsFuture;

  @override
  void initState() {
    super.initState();
    _permissionsFuture = PermissionService.getMyPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).translate('my_permissions_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<MyPermission>>(
        future: _permissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(
                  context,
                ).translate('error_loading_permissions'),
                style: TextStyle(color: context.theme.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context).translate('no_permissions_found'),
                style: TextStyle(color: context.theme.grey),
              ),
            );
          }

          final permissions = snapshot.data!;
          final groupedPermissions = <String, List<MyPermission>>{};

          for (var p in permissions) {
            if (!groupedPermissions.containsKey(p.resource)) {
              groupedPermissions[p.resource] = [];
            }
            groupedPermissions[p.resource]!.add(p);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: groupedPermissions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final resource = groupedPermissions.keys.elementAt(index);
              final perms = groupedPermissions[resource]!;

              return Card(
                elevation: 0,
                color: context.theme.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: context.theme.border.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_shared_outlined,
                            color: context.theme.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            resource.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.theme.textColor,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: perms
                            .map((p) => _buildPermissionChip(p))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPermissionChip(MyPermission permission) {
    Color color;
    switch (permission.action.toLowerCase()) {
      case 'create':
        color = Colors.green;
        break;
      case 'read':
        color = Colors.blue;
        break;
      case 'update':
        color = Colors.orange;
        break;
      case 'delete':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    final hasConditions =
        permission.conditions != null && permission.conditions!.isNotEmpty;

    return Tooltip(
      message: hasConditions
          ? permission.conditions!
                .map((c) => '${c.field} ${c.operator} ${c.displayValue}')
                .join('\n')
          : AppLocalizations.of(context).translate('no_conditions'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              permission.action.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasConditions) ...[
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
