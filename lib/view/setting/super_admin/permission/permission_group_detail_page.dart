import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionVm()..fetchGroupPermissions(widget.group.id),
      child: Consumer<PermissionVm>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: context.theme.bg,
            appBar: AppBar(
              backgroundColor: context.theme.blue,
              elevation: 0.5,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: context.theme.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(
                widget.group.name,
                style: TextStyle(
                  color: context.theme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit, color: context.theme.white),
                  onPressed: () {
                    if (_isEditing) {
                      _saveChanges(context, vm);
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
                ),
                if (!_isEditing)
                  IconButton(
                    icon: Icon(Icons.delete, color: context.theme.destructive),
                    onPressed: () => _confirmDelete(context, vm),
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddPermissionDialog(context, vm),
              backgroundColor: context.theme.blue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách quyền',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.theme.textColor,
                        ),
                      ),
                      if (vm.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (vm.getPermissionsForGroup(widget.group.id).isEmpty && !vm.isLoading)
                    Text(
                      'Chưa có quyền nào được gán',
                      style: TextStyle(color: context.theme.grey),
                    )
                  else
                    ...vm.getPermissionsForGroup(widget.group.id).map((permission) {
                      return Card(
                        color: context.theme.bg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: context.theme.grey.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            '${permission.resource} - ${permission.action}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.theme.textColor,
                            ),
                          ),
                          subtitle: Text(
                            permission.description,
                            style: TextStyle(color: context.theme.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  permission.effect,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor: permission.effect == 'ALLOW'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: context.theme.destructive),
                                onPressed: () => _confirmRevoke(
                                  context, 
                                  vm, 
                                  permission.permissionId.isNotEmpty ? permission.permissionId : permission.id
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          enabled: _isEditing,
          decoration: InputDecoration(
            labelText: 'Tên nhóm',
            labelStyle: TextStyle(color: context.theme.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.theme.grey),
            ),
            disabledBorder: InputBorder.none,
          ),
          style: TextStyle(
            color: context.theme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          enabled: _isEditing,
          decoration: InputDecoration(
            labelText: 'Mô tả',
            labelStyle: TextStyle(color: context.theme.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.theme.grey),
            ),
            disabledBorder: InputBorder.none,
          ),
          style: TextStyle(color: context.theme.textColor),
          maxLines: 3,
        ),
      ],
    );
  }

  Future<void> _saveChanges(BuildContext context, PermissionVm vm) async {
    final success = await vm.updateGroup(
      widget.group.id,
      _nameController.text,
      _descController.text,
    );

    if (success) {
      setState(() {
        _isEditing = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công')),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Cập nhật thất bại')),
      );
    }
  }

  void _confirmDelete(BuildContext context, PermissionVm vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.bg,
        title: Text('Xác nhận xóa', style: TextStyle(color: context.theme.textColor)),
        content: Text(
          'Bạn có chắc chắn muốn xóa nhóm quyền này không?',
          style: TextStyle(color: context.theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: context.theme.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final success = await vm.deleteGroup(widget.group.id);
              if (success && context.mounted) {
                Navigator.pop(context); // Close page
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(vm.error ?? 'Xóa thất bại')),
                );
              }
            },
            child: Text('Xóa', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  void _confirmRevoke(BuildContext context, PermissionVm vm, String permissionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.bg,
        title: Text('Thu hồi quyền', style: TextStyle(color: context.theme.textColor)),
        content: Text(
          'Bạn có chắc chắn muốn thu hồi quyền này khỏi nhóm?',
          style: TextStyle(color: context.theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: context.theme.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await vm.revokePermissions(widget.group.id, [permissionId]);
            },
            child: Text('Thu hồi', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  void _showAddPermissionDialog(BuildContext context, PermissionVm vm) {
    vm.fetchAllPermissions();
    final selectedPermissions = <String>{};

    showDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: vm,
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: context.theme.bg,
                title: Text('Thêm quyền', style: TextStyle(color: context.theme.textColor)),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Consumer<PermissionVm>(
                    builder: (context, vm, child) {
                      if (vm.isLoading && vm.allPermissions.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final assignedIds = vm.getPermissionsForGroup(widget.group.id).map((p) => p.id).toSet();
                      final availablePermissions = vm.allPermissions.where((p) => !assignedIds.contains(p.id)).toList();

                      if (availablePermissions.isEmpty) {
                        return Text(
                          'Không còn quyền nào để thêm',
                          style: TextStyle(color: context.theme.grey),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: availablePermissions.length,
                        itemBuilder: (context, index) {
                          final permission = availablePermissions[index];
                          return CheckboxListTile(
                            title: Text(
                              '${permission.resource} - ${permission.action}',
                              style: TextStyle(color: context.theme.textColor),
                            ),
                            subtitle: Text(
                              permission.description,
                              style: TextStyle(color: context.theme.grey),
                            ),
                            value: selectedPermissions.contains(permission.id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedPermissions.add(permission.id);
                                } else {
                                  selectedPermissions.remove(permission.id);
                                }
                              });
                            },
                            activeColor: context.theme.blue,
                            checkColor: Colors.white,
                          );
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Hủy', style: TextStyle(color: context.theme.grey)),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (selectedPermissions.isNotEmpty) {
                        Navigator.pop(context);
                        await vm.assignPermissions(widget.group.id, selectedPermissions.toList());
                      }
                    },
                    child: Text('Thêm', style: TextStyle(color: context.theme.blue)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
