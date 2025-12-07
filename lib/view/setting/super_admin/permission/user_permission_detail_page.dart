import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/view/setting/super_admin/permission/widgets/permission_tree_widget.dart';
import 'package:pbl6mobile/view_model/permission/permission_vm.dart';

class UserPermissionDetailPage extends StatefulWidget {
  final Staff user;

  const UserPermissionDetailPage({super.key, required this.user});

  @override
  State<UserPermissionDetailPage> createState() =>
      _UserPermissionDetailPageState();
}

class _UserPermissionDetailPageState extends State<UserPermissionDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionVm()
        ..fetchUserGroups(widget.user.id)
        ..fetchUserPermissions(widget.user.id),
      child: Scaffold(
        backgroundColor: context.theme.bg,
        appBar: AppBar(
          backgroundColor: context.theme.blue,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.theme.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Hero(
                tag: 'user_avatar_${widget.user.id}',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: context.theme.white.withOpacity(0.2),
                  child: Text(
                    widget.user.fullName.isNotEmpty
                        ? widget.user.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: context.theme.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.fullName,
                      style: TextStyle(
                        color: context.theme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.user.email,
                      style: TextStyle(
                        color: context.theme.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.black.withOpacity(0.05),
              child: TabBar(
                controller: _tabController,
                indicatorColor: context.theme.white,
                indicatorWeight: 3,
                labelColor: context.theme.white,
                unselectedLabelColor: context.theme.white.withOpacity(0.6),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(
                    text: AppLocalizations.of(
                      context,
                    ).translate('roles_groups'),
                  ),
                  Tab(
                    text: AppLocalizations.of(
                      context,
                    ).translate('direct_permissions'),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Consumer<PermissionVm>(
          builder: (context, vm, _) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildUserGroupsTab(context, vm),
                _buildUserDirectPermissionsTab(context, vm),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserGroupsTab(BuildContext context, PermissionVm vm) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManageUserGroupsDialog(context, vm),
        label: Text(AppLocalizations.of(context).translate('manage_groups')),
        icon: const Icon(Icons.group_add),
        backgroundColor: context.theme.blue,
        foregroundColor: Colors.white,
      ),
      body: vm.isLoading && vm.currentUserGroups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : vm.currentUserGroups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off_outlined,
                    size: 48,
                    color: context.theme.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('user_no_groups'),
                    style: TextStyle(color: context.theme.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.currentUserGroups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = vm.currentUserGroups[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: context.theme.grey.withOpacity(0.2),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(group.description),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildUserDirectPermissionsTab(BuildContext context, PermissionVm vm) {
    final permissions = vm.currentUserPermissions;
    final permissionIds = permissions
        .map((p) => p.permissionId.isNotEmpty ? p.permissionId : p.id)
        .toSet();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManageUserDirectPermissionsDialog(context, vm),
        label: Text(
          AppLocalizations.of(context).translate('manage_permissions'),
        ),
        icon: const Icon(Icons.security),
        backgroundColor: context.theme.blue,
        foregroundColor: Colors.white,
      ),
      body: vm.isLoading && permissions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  permissions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.security_outlined,
                                  size: 48,
                                  color: context.theme.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).translate('no_direct_permissions'),
                                  style: TextStyle(color: context.theme.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : PermissionTreeWidget(
                          allPermissions: permissions,
                          assignedPermissionIds: permissionIds,
                          onToggle: (_, __) {}, // Read-only
                          readOnly: true,
                        ),
                ],
              ),
            ),
    );
  }

  void _showManageUserGroupsDialog(BuildContext context, PermissionVm vm) {
    vm.getAllGroups();
    showDialog(
      context: context,
      builder: (_) => ManageUserGroupsDialog(
        userId: widget.user.id,
        currentGroups: vm.currentUserGroups,
        vm: vm,
      ),
    );
  }

  void _showManageUserDirectPermissionsDialog(
    BuildContext context,
    PermissionVm vm,
  ) {
    vm.fetchAllPermissions();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManageUserPermissionsDialog(
        userId: widget.user.id,
        currentPermissions: vm.currentUserPermissions,
        vm: vm,
      ),
    );
  }
}

class ManageUserGroupsDialog extends StatefulWidget {
  final String userId;
  final List<PermissionGroup> currentGroups;
  final PermissionVm vm;

  const ManageUserGroupsDialog({
    super.key,
    required this.userId,
    required this.currentGroups,
    required this.vm,
  });

  @override
  State<ManageUserGroupsDialog> createState() => _ManageUserGroupsDialogState();
}

class _ManageUserGroupsDialogState extends State<ManageUserGroupsDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.currentGroups.map((g) => g.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.vm,
      child: Consumer<PermissionVm>(
        builder: (context, vm, _) {
          return AlertDialog(
            title: Text(
              AppLocalizations.of(context).translate('manage_groups'),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: vm.isLoading && vm.groups.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: vm.groups.length,
                      itemBuilder: (context, index) {
                        final group = vm.groups[index];
                        final isSelected = _selectedIds.contains(group.id);
                        return CheckboxListTile(
                          title: Text(group.name),
                          subtitle: Text(group.description),
                          value: isSelected,
                          activeColor: context.theme.blue,
                          onChanged: (val) {
                            setState(() {
                              if (val == true)
                                _selectedIds.add(group.id);
                              else
                                _selectedIds.remove(group.id);
                            });
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await vm.updateUserGroupsList(
                    widget.userId,
                    _selectedIds.toList(),
                  );
                  if (success && context.mounted) Navigator.pop(context);
                },
                child: vm.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      )
                    : Text(AppLocalizations.of(context).translate('save')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ManageUserPermissionsDialog extends StatefulWidget {
  final String userId;
  final List<Permission> currentPermissions;
  final PermissionVm vm;

  const ManageUserPermissionsDialog({
    super.key,
    required this.userId,
    required this.currentPermissions,
    required this.vm,
  });

  @override
  State<ManageUserPermissionsDialog> createState() =>
      _ManageUserPermissionsDialogState();
}

class _ManageUserPermissionsDialogState
    extends State<ManageUserPermissionsDialog> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    // Use the VM helper to map snapshot permissions to system IDs
    final ids = widget.vm.getAssignedPermissionIdsForUser();
    if (ids.isNotEmpty) {
      _selectedIds = ids;
    } else {
      _selectedIds = {};
    }
  }

  @override
  void didUpdateWidget(covariant ManageUserPermissionsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the VM state changes (e.g. data loaded), update the selection
    // But ONLY if we currently have no selection (or maybe we should be smarter?)
    // Actually, getting assigned IDs is safe because it only finds matches.
    // If we have 0 selected, it might be because data wasn't loaded.
    // Let's check: if _selectedIds is empty, try to populate it.
    if (_selectedIds.isEmpty) {
      final ids = widget.vm.getAssignedPermissionIdsForUser();
      if (ids.isNotEmpty) {
        setState(() {
          _selectedIds = ids;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.vm,
      child: Consumer<PermissionVm>(
        builder: (context, vm, _) {
          final allPermissions = vm.allPermissions;

          return AlertDialog(
            backgroundColor: context.theme.bg,
            title: Text(
              AppLocalizations.of(context).translate('manage_permissions'),
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
                  final success = await vm.updateUserPermissionsList(
                    widget.userId,
                    _selectedIds.toList(),
                  );
                  if (success && context.mounted) Navigator.pop(context);
                },
                child: vm.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      )
                    : Text(AppLocalizations.of(context).translate('save')),
              ),
            ],
          );
        },
      ),
    );
  }
}
