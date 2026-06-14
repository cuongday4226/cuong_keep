import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/database.dart';

class ChecklistItemWidget extends StatefulWidget {
  final ChecklistItem item;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggle;
  final VoidCallback onSubmitted;
  final VoidCallback onDeleted;
  final VoidCallback? onDrag;
  final bool autofocus;

  const ChecklistItemWidget({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onToggle,
    required this.onSubmitted,
    required this.onDeleted,
    this.onDrag,
    this.autofocus = false,
  });

  @override
  State<ChecklistItemWidget> createState() => _ChecklistItemWidgetState();
}

class _ChecklistItemWidgetState extends State<ChecklistItemWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
    _focusNode = FocusNode();
    if (widget.autofocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant ChecklistItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.text != widget.item.text && _controller.text != widget.item.text) {
      _controller.text = widget.item.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Nút kéo thả (chỉ hiện khi chưa hoàn thành)
        if (!widget.item.isCompleted)
          GestureDetector(
            onPanDown: (_) => widget.onDrag?.call(),
            child: const Padding(
              padding: EdgeInsets.only(right: 8.0, left: 0),
              child: Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
            ),
          )
        else
          const SizedBox(width: 28), // Bù khoảng trống để thẳng hàng với ô trên
          
        // Checkbox
        Checkbox(
          value: widget.item.isCompleted,
          onChanged: (value) => widget.onToggle(),
          activeColor: Colors.grey,
        ),
        
        // Ô gõ chữ
        Expanded(
          child: Focus(
            onKeyEvent: (node, event) {
              // Nếu gõ phím Backspace khi ô đang trống rỗng -> Xóa ô này đi
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _controller.text.isEmpty) {
                widget.onDeleted();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(
                decoration: widget.item.isCompleted ? TextDecoration.lineThrough : null,
                color: widget.item.isCompleted ? Colors.grey : null,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSubmitted(),
              textInputAction: TextInputAction.next,
            ),
          ),
        ),
        
        // Nút xóa (Dấu X)
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey, size: 20),
          onPressed: widget.onDeleted,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
