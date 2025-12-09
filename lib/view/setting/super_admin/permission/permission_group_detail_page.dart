import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/view/setting/super_admin/permission/widgets/permission_tree_widget.dart';
import 'package:pbl6mobile/view_model/permission/permission_vm.dart';

class PermissionGroupDetailPage extends StatefulWidget {
  final PermissionGroup group;

  const PermissionGroupDetailPage({super.key, required this.group});

  @override
  State<PermissionGroupDetailPage> createState() =>
      _PermissionGroupDetailPageState();
}

class _PermissionGroupDetailPageState extends State<PermissionGroupDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descController = TextEditingController(text: widget.group.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(BuildContext context, PermissionVm vm) async {
    final success = await vm.updateGroup(
      widget.group.id,
      _nameController.text,
      _descController.text,
    );

    if (success) {
      setState(() => _isEditing = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('group_update_success'),
            ),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vm.error ?? AppLocalizations.of(context).translate('failed'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, PermissionVm vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('confirm_delete_title'),
        ),
        content: Text(
          AppLocalizations.of(context).translate('group_delete_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await vm.deleteGroup(widget.group.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      ).translate('group_delete_success'),
                    ),
                  ),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: TextStyle(color: context.theme.destructive),
            ),
          ),
        ],
      ),
    );
  }

  void _showManagePermissionDialog(BuildContext context, PermissionVm vm) {
    vm.fetchAllPermissions();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManagePermissionDialog(
        groupId: widget.group.id,
        initialPermissions: vm.getPermissionsForGroup(widget.group.id),
        vm: vm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionVm()..fetchGroupPermissions(widget.group.id),
      child: Consumer<PermissionVm>(
        builder: (context, vm, child) {
          final permissions = vm.getPermissionsForGroup(widget.group.id);
          final permissionIds = permissions
              .map((p) => p.permissionId.isNotEmpty ? p.permissionId : p.id)
              .toSet();

          return Scaffold(
            backgroundColor: context.theme.bg,
            appBar: AppBar(
              flexibleSpace: Container(
                decoration: _isEditing
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade700,
                            Colors.orange.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      )
                    : null,
              ),
              backgroundColor: _isEditing
                  ? Colors.transparent
                  : context.theme.primary,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.theme.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                _isEditing
                    ? AppLocalizations.of(context).translate('update')
                    : AppLocalizations.of(
                        context,
                      ).translate('permission_group_detail'),
                style: TextStyle(
                  color: context.theme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                if (!_isEditing)
                  IconButton(
                    icon: Icon(Icons.edit, color: context.theme.white),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: AppLocalizations.of(context).translate('edit'),
                  ),
                if (_isEditing)
                  IconButton(
                    icon: Icon(Icons.check, color: context.theme.white),
                    onPressed: () => _saveChanges(context, vm),
                    tooltip: AppLocalizations.of(context).translate('save'),
                  ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.theme.card,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderField(
                        context,
                        AppLocalizations.of(
                          context,
                        ).translate('group_name_label'),
                        _nameController,
                        _isEditing,
                      ),
                      const SizedBox(height: 16),
                      _buildHeaderField(
                        context,
                        AppLocalizations.of(
                          context,
                        ).translate('group_desc_label'),
                        _descController,
                        _isEditing,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: vm.isLoading && permissions.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      ).translate('resource_permissions'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: context.theme.textColor,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showManagePermissionDialog(
                                            context,
                                            vm,
                                          ),
                                      icon: const Icon(
                                        Icons.settings,
                                        size: 16,
                                      ),
                                      label: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).translate('manage_permissions'),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.theme.primary
                                            .withOpacity(0.1),
                                        foregroundColor: context.theme.primary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PermissionTreeWidget(
                                allPermissions: permissions,
                                assignedPermissionIds: permissionIds,
                                onToggle: (_, __) {}, // Read-only signature fix
                                readOnly: true,
                              ),
                              const SizedBox(height: 32),
                              if (!_isEditing)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.theme.destructive
                                        .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.theme.destructive
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).translate('danger_zone'),
                                        style: TextStyle(
                                          color: context.theme.destructive,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).translate('delete_group_warning'),
                                        style: TextStyle(
                                          color: context.theme.destructive
                                              .withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _confirmDelete(context, vm),
                                          icon: Icon(
                                            Icons.delete_forever,
                                            size: 16,
                                            color: context.theme.destructive,
                                          ),
                                          label: Text(
                                            AppLocalizations.of(
                                              context,
                                            ).translate('delete'),
                                            style: TextStyle(
                                              color: context.theme.destructive,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            backgroundColor: context
                                                .theme
                                                .destructive
                                                .withOpacity(0.1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderField(
    BuildContext context,
    String label,
    TextEditingController controller,
    bool enabled, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: context.theme.grey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        enabled
            ? TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.theme.blue),
                  ),
                ),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  controller.text,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
      ],
    );
  }
}

class ManagePermissionDialog extends StatefulWidget {
  final String groupId;
  final List<Permission> initialPermissions;
  final PermissionVm vm;

  const ManagePermissionDialog({
    super.key,
    required this.groupId,
    required this.initialPermissions,
    required this.vm,
  });

  @override
  State<ManagePermissionDialog> createState() => _ManagePermissionDialogState();
}

class _ManagePermissionDialogState extends State<ManagePermissionDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialPermissions
        .map((e) => e.permissionId.isNotEmpty ? e.permissionId : e.id)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.vm,
      child: Consumer<PermissionVm>(
        builder: (context, vm, child) {
          final allPermissions = vm.allPermissions;

          return AlertDialog(
            backgroundColor: context.theme.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              AppLocalizations.of(context).translate('manage_permissions'),
              style: TextStyle(
                color: context.theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: vm.isLoading && allPermissions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: PermissionTreeWidget(
                        allPermissions: allPermissions,
                        assignedPermissionIds: _selectedIds,
                        onToggle: (permissionId, isGranted) {
                          setState(() {
                            if (isGranted) {
                              _selectedIds.add(permissionId);
                            } else {
                              _selectedIds.remove(permissionId);
                            }
                          });
                        },
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await vm.updateGroupPermissionsList(
                    widget.groupId,
                    _selectedIds.toList(),
                  );
                  if (success && context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: vm.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '${AppLocalizations.of(context).translate('save')} (${_selectedIds.length})',
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
