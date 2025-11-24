import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/permission/permission_vm.dart';

class PermissionGroupDetailPage extends StatefulWidget {
  final PermissionGroup group;

  const PermissionGroupDetailPage({super.key, required this.group});

  @override
  State<PermissionGroupDetailPage> createState() => _PermissionGroupDetailPageState();
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.error ?? 'Không thể cập nhật nhóm quyền'),
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
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa nhóm quyền này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await vm.deleteGroup(widget.group.id);
              if (success && context.mounted) Navigator.pop(context);
            },
            child: Text('Xóa', style: TextStyle(color: context.theme.destructive)),
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
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: ManagePermissionDialog(
          groupId: widget.group.id,
          initialPermissions: vm.getPermissionsForGroup(widget.group.id),
        ),
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
                _isEditing ? 'Chỉnh sửa nhóm' : widget.group.name,
                style: TextStyle(color: context.theme.white, fontWeight: FontWeight.bold),
              ),
              actions: [
                if (!_isEditing)
                  IconButton(
                    icon: Icon(Icons.edit, color: context.theme.white),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                if (_isEditing)
                  IconButton(
                    icon: Icon(Icons.check, color: context.theme.white),
                    onPressed: () => _saveChanges(context, vm),
                  ),
                if (!_isEditing)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: context.theme.destructive),
                    onPressed: () => _confirmDelete(context, vm),
                  ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.theme.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderField(context, 'Tên nhóm', _nameController, _isEditing),
                      const SizedBox(height: 12),
                      _buildHeaderField(context, 'Mô tả', _descController, _isEditing, maxLines: 2),
                    ],
                  ),
                ),
                Expanded(
                  child: vm.isLoading && permissions.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shield_outlined, color: context.theme.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Danh sách quyền (${permissions.length})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showManagePermissionDialog(context, vm),
                              icon: const Icon(Icons.settings, size: 16),
                              label: const Text('Cấu hình quyền'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.theme.blue.withOpacity(0.1),
                                foregroundColor: context.theme.blue,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: permissions.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_open, size: 48, color: context.theme.grey.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có quyền nào được gán',
                                style: TextStyle(color: context.theme.grey),
                              ),
                            ],
                          ),
                        )
                            : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: permissions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final permission = permissions[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.theme.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: context.theme.grey.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: context.theme.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      permission.resource.isNotEmpty
                                          ? permission.resource[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: context.theme.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${permission.resource.toUpperCase()} - ${permission.action}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: context.theme.textColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (permission.description.isNotEmpty)
                                          Text(
                                            permission.description,
                                            style: TextStyle(
                                              color: context.theme.grey,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      permission.effect,
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                    backgroundColor: permission.effect == 'ALLOW'
                                        ? Colors.green
                                        : Colors.red,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderField(BuildContext context, String label, TextEditingController controller, bool enabled, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.theme.grey, fontSize: 12)),
        const SizedBox(height: 4),
        enabled
            ? TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: UnderlineInputBorder(borderSide: BorderSide(color: context.theme.blue)),
          ),
          style: TextStyle(color: context.theme.textColor, fontWeight: FontWeight.w500),
        )
            : Text(
          controller.text,
          style: TextStyle(color: context.theme.textColor, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class ManagePermissionDialog extends StatefulWidget {
  final String groupId;
  final List<Permission> initialPermissions;

  const ManagePermissionDialog({
    super.key,
    required this.groupId,
    required this.initialPermissions,
  });

  @override
  State<ManagePermissionDialog> createState() => _ManagePermissionDialogState();
}

class _ManagePermissionDialogState extends State<ManagePermissionDialog> {
  late Set<String> _selectedIds;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Use permissionId for matching with all permissions list
    _selectedIds = widget.initialPermissions.map((e) => e.permissionId.isNotEmpty ? e.permissionId : e.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionVm>(
      builder: (context, vm, child) {
        final allPermissions = vm.allPermissions;

        final filteredPermissions = allPermissions.where((p) {
          final query = _searchQuery.toLowerCase();
          return p.resource.toLowerCase().contains(query) ||
              p.action.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query);
        }).toList();

        final groupedPermissions = <String, List<Permission>>{};
        for (var p in filteredPermissions) {
          if (!groupedPermissions.containsKey(p.resource)) {
            groupedPermissions[p.resource] = [];
          }
          groupedPermissions[p.resource]!.add(p);
        }

        return AlertDialog(
          backgroundColor: context.theme.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.all(20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.all(20),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quản lý quyền', style: TextStyle(color: context.theme.textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Chọn quyền để gán, bỏ chọn để thu hồi',
                style: TextStyle(color: context.theme.grey, fontSize: 12, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: context.theme.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: vm.isLoading && allPermissions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: groupedPermissions.keys.length,
                itemBuilder: (context, index) {
                  final resource = groupedPermissions.keys.elementAt(index);
                  final perms = groupedPermissions[resource]!;

                  final allChecked = perms.every((p) => _selectedIds.contains(p.id));
                  final someChecked = perms.any((p) => _selectedIds.contains(p.id));

                  return Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
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
                          Text(
                            resource.toUpperCase(),
                            style: TextStyle(
                              color: context.theme.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      children: perms.map((p) {
                        final isSelected = _selectedIds.contains(p.id);
                        return CheckboxListTile(
                          title: Text(p.action, style: TextStyle(color: context.theme.textColor)),
                          subtitle: Text(p.description, style: TextStyle(color: context.theme.grey, fontSize: 12)),
                          value: isSelected,
                          activeColor: context.theme.blue,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) _selectedIds.add(p.id);
                              else _selectedIds.remove(p.id);
                            });
                          },
                          contentPadding: const EdgeInsets.only(left: 16, right: 0),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.theme.grey,
                side: BorderSide(color: context.theme.grey.withOpacity(0.5)),
              ),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await vm.updateGroupPermissionsList(widget.groupId, _selectedIds.toList());
                if (success && context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.blue,
                foregroundColor: Colors.white,
              ),
              child: vm.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Lưu (${_selectedIds.length})'),
            ),
          ],
        );
      },
    );
  }
}