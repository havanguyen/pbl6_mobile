import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/permission/permission_vm.dart';

class UserPermissionDetailPage extends StatefulWidget {
  final Staff user;

  const UserPermissionDetailPage({super.key, required this.user});

  @override
  State<UserPermissionDetailPage> createState() => _UserPermissionDetailPageState();
}

class _UserPermissionDetailPageState extends State<UserPermissionDetailPage> with SingleTickerProviderStateMixin {
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
              CircleAvatar(
                radius: 16,
                backgroundColor: context.theme.white.withOpacity(0.2),
                child: Text(
                  widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'U',
                  style: TextStyle(color: context.theme.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.fullName,
                      style: TextStyle(color: context.theme.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.user.email,
                      style: TextStyle(color: context.theme.white.withOpacity(0.8), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: context.theme.white,
            labelColor: context.theme.white,
            unselectedLabelColor: context.theme.white.withOpacity(0.6),
            tabs: const [
              Tab(text: 'Nhóm quyền (Roles)'),
              Tab(text: 'Quyền trực tiếp'),
            ],
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
        label: const Text('Quản lý Nhóm'),
        icon: const Icon(Icons.group_add),
        backgroundColor: context.theme.blue,
        foregroundColor: Colors.white,
      ),
      body: vm.isLoading && vm.currentUserGroups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : vm.currentUserGroups.isEmpty
          ? Center(
        child: Text(
          'Người dùng chưa thuộc nhóm quyền nào',
          style: TextStyle(color: context.theme.grey),
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
              side: BorderSide(color: context.theme.grey.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_outlined, color: Colors.orange),
              ),
              title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(group.description),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserDirectPermissionsTab(BuildContext context, PermissionVm vm) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showManageUserDirectPermissionsDialog(context, vm),
        label: const Text('Quản lý Quyền'),
        icon: const Icon(Icons.security),
        backgroundColor: context.theme.blue,
        foregroundColor: Colors.white,
      ),
      body: vm.isLoading && vm.currentUserPermissions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : vm.currentUserPermissions.isEmpty
          ? Center(
        child: Text(
          'Không có quyền trực tiếp nào',
          style: TextStyle(color: context.theme.grey),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: vm.currentUserPermissions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final perm = vm.currentUserPermissions[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.theme.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.theme.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: context.theme.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${perm.resource.toUpperCase()} - ${perm.action}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                ),
                Chip(
                  label: Text(perm.effect, style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: perm.effect == 'ALLOW' ? Colors.green : Colors.red,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )
              ],
            ),
          );
        },
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

  void _showManageUserDirectPermissionsDialog(BuildContext context, PermissionVm vm) {
    vm.fetchAllPermissions();
    showDialog(
      context: context,
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
            title: const Text('Quản lý Nhóm quyền'),
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
                        if (val == true) _selectedIds.add(group.id);
                        else _selectedIds.remove(group.id);
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  final success = await vm.updateUserGroupsList(widget.userId, _selectedIds.toList());
                  if (success && context.mounted) Navigator.pop(context);
                },
                child: vm.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                    : const Text('Lưu'),
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
  State<ManageUserPermissionsDialog> createState() => _ManageUserPermissionsDialogState();
}

class _ManageUserPermissionsDialogState extends State<ManageUserPermissionsDialog> {
  late Set<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Use permissionId for matching with all permissions list
    _selectedIds = widget.currentPermissions.map((p) => p.permissionId.isNotEmpty ? p.permissionId : p.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.vm,
      child: Consumer<PermissionVm>(
        builder: (context, vm, _) {
          final filtered = vm.allPermissions.where((p) =>
          p.resource.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.action.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

          final grouped = <String, List<Permission>>{};
          for (var p in filtered) {
            if (!grouped.containsKey(p.resource)) grouped[p.resource] = [];
            grouped[p.resource]!.add(p);
          }

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cấp quyền trực tiếp'),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: vm.isLoading && vm.allPermissions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final resource = grouped.keys.elementAt(index);
                  final perms = grouped[resource]!;

                  final allChecked = perms.every((p) => _selectedIds.contains(p.id));
                  final someChecked = perms.any((p) => _selectedIds.contains(p.id));

                  return ExpansionTile(
                    initiallyExpanded: true,
                    title: Row(
                      children: [
                        Checkbox(
                          value: allChecked ? true : (someChecked ? null : false),
                          tristate: true,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.addAll(perms.map((p) => p.id));
                              } else {
                                _selectedIds.removeAll(perms.map((p) => p.id));
                              }
                            });
                          },
                        ),
                        Text(resource.toUpperCase(), style: TextStyle(color: context.theme.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    children: perms.map((p) {
                      final isSelected = _selectedIds.contains(p.id);
                      return CheckboxListTile(
                        title: Text(p.action),
                        subtitle: Text(p.description),
                        value: isSelected,
                        activeColor: context.theme.blue,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) _selectedIds.add(p.id);
                            else _selectedIds.remove(p.id);
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  final success = await vm.updateUserPermissionsList(widget.userId, _selectedIds.toList());
                  if (success && context.mounted) Navigator.pop(context);
                },
                child: vm.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                    : const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }
}