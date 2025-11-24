import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/permission/permission_vm.dart';
import 'package:provider/provider.dart';

class UserPermissionDetailPage extends StatefulWidget {
  final Staff user;

  const UserPermissionDetailPage({super.key, required this.user});

  @override
  State<UserPermissionDetailPage> createState() => _UserPermissionDetailPageState();
}

class _UserPermissionDetailPageState extends State<UserPermissionDetailPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionVm()
        ..fetchUserPermissions(widget.user.id)
        ..fetchUserGroups(widget.user.id)
        ..fetchAllPermissions()
        ..getAllGroups(),
      child: Consumer<PermissionVm>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: context.theme.bg,
            appBar: AppBar(
              backgroundColor: context.theme.blue,
              elevation: 0.5,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.theme.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.user.fullName,
                style: TextStyle(color: context.theme.white, fontWeight: FontWeight.bold),
              ),
            ),
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'Nhóm quyền', () => _showAddGroupDialog(context, vm)),
                        const SizedBox(height: 16),
                        if (vm.currentUserGroups.isEmpty)
                          Text('Chưa có nhóm quyền nào', style: TextStyle(color: context.theme.grey))
                        else
                          ...vm.currentUserGroups.map((group) => Card(
                                color: context.theme.bg,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(group.name, style: TextStyle(color: context.theme.textColor, fontWeight: FontWeight.bold)),
                                  subtitle: Text(group.description, style: TextStyle(color: context.theme.grey)),
                                  trailing: IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: context.theme.destructive),
                                    onPressed: () => _confirmRevokeGroup(context, vm, group.id),
                                  ),
                                ),
                              )),
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, 'Quyền riêng lẻ', () => _showAddPermissionDialog(context, vm)),
                        const SizedBox(height: 16),
                        if (vm.currentUserPermissions.isEmpty)
                          Text('Chưa có quyền riêng lẻ nào', style: TextStyle(color: context.theme.grey))
                        else
                          ...vm.currentUserPermissions.map((permission) => Card(
                                color: context.theme.bg,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text('${permission.resource} - ${permission.action}', style: TextStyle(color: context.theme.textColor, fontWeight: FontWeight.bold)),
                                  subtitle: Text(permission.description, style: TextStyle(color: context.theme.grey)),
                                  trailing: IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: context.theme.destructive),
                                    onPressed: () => _confirmRevokePermission(context, vm, permission.permissionId.isNotEmpty ? permission.permissionId : permission.id),
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.theme.textColor),
        ),
        IconButton(
          icon: Icon(Icons.add_circle, color: context.theme.blue),
          onPressed: onAdd,
        ),
      ],
    );
  }

  void _showAddGroupDialog(BuildContext context, PermissionVm vm) {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: vm,
        child: Builder(
          builder: (context) {
            final availableGroups = vm.groups.where((g) => !vm.currentUserGroups.any((ug) => ug.id == g.id)).toList();
            return AlertDialog(
              backgroundColor: Theme.of(context).extension<CustomThemeExtension>()!.bg,
              title: Text('Thêm nhóm quyền', style: TextStyle(color: Theme.of(context).extension<CustomThemeExtension>()!.textColor)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableGroups.length,
                  itemBuilder: (context, index) {
                    final group = availableGroups[index];
                    return ListTile(
                      title: Text(group.name, style: TextStyle(color: Theme.of(context).extension<CustomThemeExtension>()!.textColor)),
                      subtitle: Text(group.description, style: TextStyle(color: Theme.of(context).extension<CustomThemeExtension>()!.grey)),
                      onTap: () async {
                        Navigator.pop(context);
                        await vm.assignUserGroups(widget.user.id, [group.id]);
                      },
                    );
                  },
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  void _showAddPermissionDialog(BuildContext context, PermissionVm vm) {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: vm,
        child: Builder(
          builder: (context) {
            final availablePermissions = vm.allPermissions; // Ideally filter out already assigned ones
            return AlertDialog(
              backgroundColor: Theme.of(context).extension<CustomThemeExtension>()!.bg,
              title: Text('Thêm quyền', style: TextStyle(color: Theme.of(context).extension<CustomThemeExtension>()!.textColor)),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: availablePermissions.length,
                  itemBuilder: (context, index) {
                    final permission = availablePermissions[index];
                    return ListTile(
                      title: Text('${permission.resource} - ${permission.action}', style: TextStyle(color: Theme.of(context).extension<CustomThemeExtension>()!.textColor)),
                      subtitle: Text(permission.description, style: TextStyle(color: Theme.of(context).extension<CustomThemeExtension>()!.grey)),
                      onTap: () async {
                        Navigator.pop(context);
                        await vm.assignUserPermissions(widget.user.id, [permission.id]);
                      },
                    );
                  },
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  void _confirmRevokeGroup(BuildContext context, PermissionVm vm, String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn gỡ nhóm quyền này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await vm.revokeUserGroups(widget.user.id, [groupId]);
            },
            child: const Text('Gỡ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmRevokePermission(BuildContext context, PermissionVm vm, String permissionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn thu hồi quyền này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await vm.revokeUserPermissions(widget.user.id, [permissionId]);
            },
            child: const Text('Thu hồi', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
