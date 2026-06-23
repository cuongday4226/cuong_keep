import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/notes_view_model.dart';

class EditLabelsDialog extends StatefulWidget {
  const EditLabelsDialog({super.key});

  @override
  State<EditLabelsDialog> createState() => _EditLabelsDialogState();
}

class _EditLabelsDialogState extends State<EditLabelsDialog> {
  final _newLabelController = TextEditingController();
  final _focusNode = FocusNode();
  String? _editingLabel;
  final _editController = TextEditingController();
  final _editFocusNode = FocusNode();

  @override
  void dispose() {
    _newLabelController.dispose();
    _focusNode.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _submitNewLabel() {
    final text = _newLabelController.text.trim();
    if (text.isNotEmpty) {
      context.read<NotesViewModel>().addGlobalLabel(text);
      _newLabelController.clear();
      _focusNode.requestFocus();
    }
  }

  void _submitEdit() {
    if (_editingLabel != null) {
      final newText = _editController.text.trim();
      if (newText.isNotEmpty && newText != _editingLabel) {
        context.read<NotesViewModel>().renameGlobalLabel(_editingLabel!, newText);
      }
      setState(() {
        _editingLabel = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotesViewModel>();
    final tags = viewModel.allTags;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Chỉnh sửa nhãn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            // Ô nhập nhãn mới
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _newLabelController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Tạo nhãn mới',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _submitNewLabel(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _submitNewLabel,
                  ),
                ],
              ),
            ),
            const Divider(),
            // Danh sách các nhãn hiện có
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final isEditing = _editingLabel == tag;

                  if (isEditing) {
                    return ListTile(
                      leading: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          viewModel.deleteGlobalLabel(tag);
                          setState(() => _editingLabel = null);
                        },
                      ),
                      title: TextField(
                        controller: _editController,
                        focusNode: _editFocusNode,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _submitEdit(),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _submitEdit,
                      ),
                    );
                  }

                  return ListTile(
                    leading: const Icon(Icons.label_outline, color: Colors.grey),
                    title: Text(tag),
                    trailing: const Icon(Icons.edit, color: Colors.grey, size: 20),
                    onTap: () {
                      setState(() {
                        _editingLabel = tag;
                        _editController.text = tag;
                      });
                      // Cần đợi build xong mới request focus
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _editFocusNode.requestFocus();
                      });
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Xong'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
