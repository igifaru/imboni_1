import 'package:flutter/material.dart';
import '../../models/community_models.dart';

class PollCreatorDialog extends StatefulWidget {
  const PollCreatorDialog({super.key});

  @override
  State<PollCreatorDialog> createState() => _PollCreatorDialogState();
}

class _PollCreatorDialogState extends State<PollCreatorDialog> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  bool _allowMultiple = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 options
    _addOption();
    _addOption();
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    _optionControllers.add(TextEditingController());
    setState(() {});
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    _optionControllers[index].dispose();
    _optionControllers.removeAt(index);
    setState(() {});
  }

  void _createPoll() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least 2 options')),
      );
      return;
    }

    final pollData = {
      'question': question,
      'options': options.map((opt) => {'text': opt}).toList(),
      'allowMultiple': _allowMultiple,
    };

    final attachment = CommunityAttachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AttachmentType.poll,
      path: '',
      name: 'Poll',
      size: 0,
      metadata: pollData,
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
        width: 400, // Explicit fixed width to prevent layout errors
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Don't stretch indiscriminately
            children: [
              Text(
                'Create Poll',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Ask something...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Option ${index + 1}',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                          onPressed: () => _removeOption(index),
                        ),
                    ],
                  ),
                );
              }),
              if (_optionControllers.length < 10)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                  style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Allow multiple answers'),
                value: _allowMultiple,
                onChanged: (val) => setState(() => _allowMultiple = val),
                contentPadding: EdgeInsets.zero,
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
                    height: 48,
                    width: 120, // Explicit width to prevent any infinite expansion issues
                    child: ElevatedButton(
                      onPressed: _createPoll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0, // Simplify shadow to reduce RenderPhysicalShape complexity
                      ),
                      child: const Text('Create Poll'),
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
