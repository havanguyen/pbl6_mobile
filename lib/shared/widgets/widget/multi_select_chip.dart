
import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

class MultiSelectChipField<T> extends StatefulWidget {
  final String label;
  final List<T> allItems;
  final List<T> initialSelectedItems;
  final String Function(T) itemName;
  final ValueChanged<List<T>> onSelectionChanged;
  final bool isReadOnly;

  const MultiSelectChipField({super.key,
    required this.label,
    required this.allItems,
    required this.initialSelectedItems,
    required this.itemName,
    required this.onSelectionChanged,
    this.isReadOnly = false,
  });

  @override
  MultiSelectChipFieldState<T> createState() =>
      MultiSelectChipFieldState<T>();
}

class MultiSelectChipFieldState<T> extends State<MultiSelectChipField<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelectedItems);
  }

  @override
  void didUpdateWidget(covariant MultiSelectChipField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool listsAreEqual = _compareLists(widget.initialSelectedItems, _selectedItems);

    if (!listsAreEqual) {
      _selectedItems = List.from(widget.initialSelectedItems);
    }
    if (widget.allItems.isNotEmpty && _selectedItems.isNotEmpty) {
      _selectedItems.removeWhere((selected) =>
      !widget.allItems.any((allItem) => (allItem as dynamic).id == (selected as dynamic).id));
    }
  }

  bool _compareLists(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    var ids1 = list1.map((e) => (e as dynamic).id).toSet();
    var ids2 = list2.map((e) => (e as dynamic).id).toSet();
    return ids1.length == ids2.length && ids1.containsAll(ids2);
  }


  void _showMultiSelectDialog() {
    if (widget.isReadOnly) return;

    showDialog(
      context: context,
      builder: (context) {
        final tempSelectedItems = List<T>.from(_selectedItems);
        String searchQuery = "";

        return StatefulBuilder(builder: (context, menuSetState) {
          final filteredItems = widget.allItems.where((item) {
            final name = widget.itemName(item).toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return AlertDialog(
            backgroundColor: context.theme.popover,
            title: Text('Chọn ${widget.label}', style: TextStyle(color: context.theme.popoverForeground)),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    style: TextStyle(color: context.theme.popoverForeground),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: TextStyle(color: context.theme.mutedForeground),
                      prefixIcon: Icon(Icons.search, color: context.theme.mutedForeground),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) {
                      menuSetState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: widget.allItems.isEmpty
                      ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: Text("Không có dữ liệu", style: TextStyle(color: context.theme.popoverForeground)))
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isSelected = tempSelectedItems.any((selectedItem) => (selectedItem as dynamic).id == (item as dynamic).id);
                      return CheckboxListTile(
                        title: Text(widget.itemName(item), style: TextStyle(color: context.theme.popoverForeground)),
                        value: isSelected,
                        activeColor: context.theme.primary,
                        checkColor: context.theme.primaryForeground,
                        onChanged: (bool? selected) {
                          menuSetState(() {
                            if (selected == true) {
                              tempSelectedItems.add(item);
                            } else {
                              tempSelectedItems.removeWhere((selectedItem) => (selectedItem as dynamic).id == (item as dynamic).id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy', style: TextStyle(color: context.theme.mutedForeground)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: context.theme.primary, foregroundColor: context.theme.primaryForeground),
                onPressed: () {
                  setState(() {
                    _selectedItems = tempSelectedItems;
                    widget.onSelectionChanged(_selectedItems);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Xong'),
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedSelectedItems = List<T>.from(_selectedItems)
      ..sort((a, b) => widget.itemName(a).compareTo(widget.itemName(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.theme.textColor)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isReadOnly ? context.theme.muted.withOpacity(0.3) : context.theme.input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.theme.border),
          ),
          child: _selectedItems.isEmpty
              ? GestureDetector(
              onTap: widget.isReadOnly ? null : _showMultiSelectDialog,
              child: Center(
                  child: Text(
                    'Chưa có ${widget.label.toLowerCase()} nào được chọn',
                    style: TextStyle(color: context.theme.mutedForeground),
                  )
              )
          )
              : SingleChildScrollView(
            child: Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: sortedSelectedItems
                  .map((item) => Chip(
                label: Text(widget.itemName(item)),
                backgroundColor: context.theme.primary.withOpacity(0.15),
                labelStyle: TextStyle(color: context.theme.primary, fontWeight: FontWeight.w500),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                deleteIcon: Icon(Icons.close, size: 16, color: context.theme.destructive.withOpacity(0.7)),
                onDeleted: widget.isReadOnly
                    ? null
                    : () {
                  setState(() {
                    _selectedItems.removeWhere((i) => (i as dynamic).id == (item as dynamic).id);
                    widget.onSelectionChanged(_selectedItems);
                  });
                },
              ))
                  .toList(),
            ),
          ),
        ),

        if (!widget.isReadOnly) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
              icon: Icon(_selectedItems.isEmpty ? Icons.add : Icons.edit_outlined, size: 18,),
              label: Text(_selectedItems.isEmpty
                  ? 'Thêm ${widget.label.toLowerCase()}'
                  : 'Chỉnh sửa lựa chọn'),
              onPressed: _showMultiSelectDialog,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                foregroundColor: context.theme.primary,
                side: BorderSide(color: context.theme.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(
                foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return context.theme.mutedForeground;
                      }
                      return context.theme.primary;
                    }),
                side: MaterialStateProperty.resolveWith<BorderSide?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return BorderSide(color: context.theme.border);
                      }
                      return BorderSide(color: context.theme.primary.withOpacity(0.5));
                    }),
              )
          )
        ]
      ],
    );
  }
}