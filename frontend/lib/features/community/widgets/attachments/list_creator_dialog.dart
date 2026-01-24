import 'package:flutter/material.dart';
import '../../models/community_models.dart';

class ListCreatorDialog extends StatefulWidget {
  const ListCreatorDialog({super.key});

  @override
  State<ListCreatorDialog> createState() => _ListCreatorDialogState();
}

class _ListCreatorDialogState extends State<ListCreatorDialog> {
  final TextEditingController _titleController = TextEditingController();
  final List<TextEditingController> _columnControllers = [];
  
  @override
  void initState() {
    super.initState();
    // Default columns
    _addColumn('Name');
    _addColumn('Phone');
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var c in _columnControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addColumn([String? initialText]) {
    _columnControllers.add(TextEditingController(text: initialText ?? ''));
    setState(() {});
  }

  void _removeColumn(int index) {
    if (_columnControllers.length <= 1) return;
    _columnControllers[index].dispose();
    _columnControllers.removeAt(index);
    setState(() {});
  }

  void _createList() {
    final title = _titleController.text.trim();
    final columns = _columnControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a list title')),
      );
      return;
    }

    if (columns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least one column')),
      );
      return;
    }

    final listData = {
      'title': title,
      'columns': columns,
      'entries': [], // Empty initially
    };

    final attachment = CommunityAttachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AttachmentType.collaborativeList,
      path: '',
      name: 'List: $title',
      size: 0,
      metadata: listData,
    );

    Navigator.pop(context, attachment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400, 
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Collaborative List',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'List Title',
                  hintText: 'e.g., Event Signup',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Columns', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_columnControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _columnControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Column ${index + 1}',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      if (_columnControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                          onPressed: () => _removeColumn(index),
                        ),
                    ],
                  ),
                );
              }),
              if (_columnControllers.length < 10)
                TextButton.icon(
                  onPressed: () => _addColumn(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Column'),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120, // Explicit width for safety
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _createList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                      ),
                      child: const Text('Create List'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
