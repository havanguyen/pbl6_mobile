
import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

class DynamicListInput extends StatefulWidget {
  final String label;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final bool isReadOnly;

  const DynamicListInput(
      {super.key, required this.label,
        required this.items,
        required this.onChanged, required this.isReadOnly});

  @override
  DynamicListInputState createState() => DynamicListInputState();
}

class DynamicListInputState extends State<DynamicListInput> {
  final TextEditingController _textController = TextEditingController();

  void _addItem() {
    if (widget.isReadOnly || _textController.text.trim().isEmpty) return;

    setState(() {
      widget.items.add(_textController.text.trim());
      widget.onChanged(widget.items);
      _textController.clear();
    });
  }

  void _removeItem(int index) {
    if (widget.isReadOnly) return;
    setState(() {
      widget.items.removeAt(index);
      widget.onChanged(widget.items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.items.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 0,
                color: context.theme.input.withOpacity(0.7),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: context.theme.border.withOpacity(0.5))
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  title: Text(widget.items[index], style: TextStyle(color: context.theme.textColor)),
                  trailing: widget.isReadOnly ? null : IconButton(
                    icon: Icon(Icons.close, color: context.theme.destructive, size: 18,),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _removeItem(index),
                  ),
                ),
              );
            },
          ),
        if (!widget.isReadOnly)
          TextFormField(
            controller: _textController,
            style: TextStyle(color: context.theme.textColor),
            decoration: InputDecoration(
              hintText: 'Thêm ${widget.label.toLowerCase()}...',
              hintStyle: TextStyle(color: context.theme.mutedForeground),
              filled: true,
              fillColor: context.theme.input,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.theme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(Icons.add_circle_outline, color: context.theme.primary),
                onPressed: _addItem,
              ),
            ),
            onFieldSubmitted: (_) => _addItem(),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}