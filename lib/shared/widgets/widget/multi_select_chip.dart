import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

class MultiSelectChipField<T> extends StatefulWidget {
  final String label;
  final List<T> allItems;
  final List<T> initialSelectedItems;
  final String Function(T) itemName;
  final Function(List<T>) onSelectionChanged;
  final bool isReadOnly;

  const MultiSelectChipField({
    super.key,
    required this.label,
    required this.allItems,
    required this.initialSelectedItems,
    required this.itemName,
    required this.onSelectionChanged,
    this.isReadOnly = false,
  });

  @override
  State<MultiSelectChipField<T>> createState() => _MultiSelectChipFieldState<T>();
}

class _MultiSelectChipFieldState<T> extends State<MultiSelectChipField<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelectedItems);
  }

  @override
  void didUpdateWidget(covariant MultiSelectChipField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedItems != oldWidget.initialSelectedItems) {
      _selectedItems = List.from(widget.initialSelectedItems);
    }
  }

  void _showSelectionDialog() {
    if (widget.isReadOnly) return;

    final tempSelectedItems = List<T>.from(_selectedItems);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return AlertDialog(
              backgroundColor: context.theme.popover,
              title: Text('Chọn ${widget.label}', style: TextStyle(color: context.theme.textColor)),
              // --- ĐÂY LÀ PHẦN SỬA LỖI ---
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // Cung cấp một chiều cao cố định
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.allItems.length,
                  itemBuilder: (itemCtx, index) {
                    final item = widget.allItems[index];
                    final isSelected = tempSelectedItems.contains(item);
                    return CheckboxListTile(
                      title: Text(widget.itemName(item), style: TextStyle(color: context.theme.textColor)),
                      value: isSelected,
                      activeColor: context.theme.primary,
                      onChanged: (bool? selected) {
                        if (selected == true) {
                          dialogSetState(() => tempSelectedItems.add(item));
                        } else {
                          dialogSetState(() => tempSelectedItems.remove(item));
                        }
                      },
                    );
                  },
                ),
              ),
              // -----------------------------
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Hủy', style: TextStyle(color: context.theme.mutedForeground)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primary,
                    foregroundColor: context.theme.primaryForeground,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedItems = List.from(tempSelectedItems);
                    });
                    widget.onSelectionChanged(_selectedItems);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.theme.textColor,
              ),
            ),
            if (!widget.isReadOnly)
              TextButton.icon(
                icon: Icon(Icons.add_circle_outline, color: context.theme.primary, size: 18),
                label: Text('Thêm', style: TextStyle(color: context.theme.primary)),
                onPressed: _showSelectionDialog,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isReadOnly ? context.theme.muted.withOpacity(0.3) : context.theme.input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.theme.border),
          ),
          child: _selectedItems.isEmpty
              ? Text(
            'Chưa chọn ${widget.label.toLowerCase()}',
            style: TextStyle(color: context.theme.mutedForeground),
          )
              : Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _selectedItems.map((item) {
              return Chip(
                label: Text(widget.itemName(item)),
                backgroundColor: context.theme.primary.withOpacity(0.1),
                labelStyle: TextStyle(color: context.theme.primary, fontWeight: FontWeight.w500),
                onDeleted: widget.isReadOnly
                    ? null
                    : () {
                  setState(() {
                    _selectedItems.remove(item);
                  });
                  widget.onSelectionChanged(_selectedItems);
                },
                deleteIcon: widget.isReadOnly ? null : const Icon(Icons.cancel, size: 18),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}