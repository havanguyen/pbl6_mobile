import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/shared/constants/permission_constants.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class PermissionTreeWidget extends StatefulWidget {
  final List<Permission> allPermissions;
  final Set<String> assignedPermissionIds;

  /// Callback to toggle a permission.
  /// [permissionId] is the ID of the permission to add/remove.
  /// [isGranted] is the new state.
  final Function(String permissionId, bool isGranted) onToggle;
  final bool readOnly;

  const PermissionTreeWidget({
    super.key,
    required this.allPermissions,
    required this.assignedPermissionIds,
    required this.onToggle,
    this.readOnly = false,
  });

  @override
  State<PermissionTreeWidget> createState() => _PermissionTreeWidgetState();
}

class _PermissionTreeWidgetState extends State<PermissionTreeWidget> {
  // Helper to find a permission by resource and action
  Permission? _getPermission(String resource, String action) {
    try {
      return widget.allPermissions.firstWhere(
        (p) =>
            p.resource.toLowerCase() == resource.toLowerCase() &&
            p.action.toLowerCase() == action.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.theme.border),
        borderRadius: BorderRadius.circular(12),
        color: context.theme.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  ).translate('resource_permissions').toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: context.theme.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.theme.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.assignedPermissionIds.length} ${AppLocalizations.of(context).translate('grant')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: PermissionConstants.resources.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final resource = PermissionConstants.resources[index];
              return _buildResourceTile(resource);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResourceTile(String resource) {
    final grantedCount = _getGrantedCount(resource);
    final totalActions = PermissionConstants.actions.length;
    final isAllGranted = grantedCount == totalActions;
    final isNoneGranted = grantedCount == 0;
    final progress = totalActions > 0 ? grantedCount / totalActions : 0.0;

    final resourceKey = 'resource_${resource.toLowerCase()}';
    final localizedResource = AppLocalizations.of(
      context,
    ).translate(resourceKey);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              backgroundColor: context.theme.grey.withOpacity(0.1),
              color: isAllGranted ? Colors.green : Colors.orange,
              strokeWidth: 3,
            ),
            Icon(
              isAllGranted
                  ? Icons.check
                  : (isNoneGranted ? Icons.security : Icons.shield),
              color: isAllGranted
                  ? Colors.green
                  : (isNoneGranted ? context.theme.grey : Colors.orange),
              size: 16,
            ),
          ],
        ),
        title: Text(
          localizedResource,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.theme.textColor,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$grantedCount / $totalActions ${AppLocalizations.of(context).translate('allow').toLowerCase()}',
            style: TextStyle(color: context.theme.grey, fontSize: 13),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: PermissionConstants.actions.map((action) {
                return _buildActionChip(resource, action);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String resource, String action) {
    final permission = _getPermission(resource, action);
    final exists = permission != null;
    final isGranted = exists && _isGranted(permission);

    final actionKey = 'action_${action.toLowerCase()}';
    final localizedAction = AppLocalizations.of(context).translate(actionKey);

    return InkWell(
      onTap: (widget.readOnly || !exists)
          ? null
          : () {
              final permId = permission.permissionId.isNotEmpty
                  ? permission.permissionId
                  : permission.id;
              widget.onToggle(permId, !isGranted);
            },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isGranted
              ? context.theme.blue
              : (exists
                    ? context.theme.bg
                    : context.theme.grey.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isGranted
                ? context.theme.blue
                : (exists
                      ? context.theme.border
                      : context.theme.border.withOpacity(0.5)),
            width: 1,
          ),
          boxShadow: isGranted
              ? [
                  BoxShadow(
                    color: context.theme.blue.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGranted) ...[
              const Icon(Icons.check, color: Colors.white, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              localizedAction,
              style: TextStyle(
                color: isGranted
                    ? Colors.white
                    : (exists ? context.theme.textColor : context.theme.grey),
                fontWeight: isGranted ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
                decoration: !exists ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isGranted(Permission permission) {
    final idToCheck = permission.permissionId.isNotEmpty
        ? permission.permissionId
        : permission.id;
    return widget.assignedPermissionIds.contains(idToCheck);
  }

  int _getGrantedCount(String resource) {
    int count = 0;
    for (final action in PermissionConstants.actions) {
      final perm = _getPermission(resource, action);
      if (perm != null && _isGranted(perm)) {
        count++;
      }
    }
    return count;
  }
}
