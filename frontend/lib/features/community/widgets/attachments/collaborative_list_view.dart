import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/community_models.dart';

class CollaborativeListView extends StatelessWidget {
  final CommunityAttachment attachment;
  final Function(Map<String, String>) onAddEntry;
  final String currentUserId;
  final String currentUserName;

  const CollaborativeListView({
    super.key,
    required this.attachment,
    required this.onAddEntry,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    if (attachment.type != AttachmentType.collaborativeList || attachment.metadata == null) {
      return const SizedBox.shrink();
    }

    final list = CollaborativeList.fromJson(attachment.metadata!);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  list.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${list.entries.length} entries',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showListDetails(context, list),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.indigo),
                foregroundColor: Colors.indigo,
              ),
              child: const Text('View List'),
            ),
          ),
        ],
      ),
    );
  }

  void _showListDetails(BuildContext context, CollaborativeList list) {
    showDialog(
      context: context,
      builder: (context) => _ListDetailDialog(
        list: list,
        onAddEntry: onAddEntry,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      ),
    );
  }
}

class _ListDetailDialog extends StatefulWidget {
  final CollaborativeList list;
  final Function(Map<String, String>) onAddEntry;
  final String currentUserId;
  final String currentUserName;

  const _ListDetailDialog({
    required this.list,
    required this.onAddEntry,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<_ListDetailDialog> createState() => _ListDetailDialogState();
}

class _ListDetailDialogState extends State<_ListDetailDialog> {
  late CollaborativeList _currentList;

  @override
  void initState() {
    super.initState();
    _currentList = widget.list;
  }

  void _addNewEntry() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddEntryDialog(columns: _currentList.columns),
    );

    if (result != null) {
      widget.onAddEntry(result);
      // Optimistically update local view
      final newEntry = ListEntry(
        userId: widget.currentUserId, 
        userName: widget.currentUserName, 
        data: result,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _currentList = CollaborativeList(
          title: _currentList.title,
          columns: _currentList.columns,
          entries: [..._currentList.entries, newEntry],
        );
      });
    }
  }

  Future<void> _exportToCsv() async {
    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln(_currentList.columns.join(','));
      
      // Rows
      for (final entry in _currentList.entries) {
        final row = _currentList.columns.map((col) {
          final cell = entry.data[col] ?? '';
          // Escape logic could be added here
          return '"$cell"'; 
        }).join(',');
        buffer.writeln(row);
      }

      final csvContent = buffer.toString();
      
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${_currentList.title.replaceAll(' ', '_')}.csv';
      final file = File(path);
      await file.writeAsString(csvContent);

      await Share.shareXFiles([XFile(path)], text: 'Exported List: ${_currentList.title}');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: SizedBox(
          width: 600, // Enforce width to ensure horizontal scroll works
          height: 500, // Enforce height so Expanded works
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded( // Constrain title width
                      child: Text(
                        _currentList.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: 'Export CSV',
                          onPressed: _exportToCsv,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: _currentList.columns
                              .map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))))
                              .toList(),
                          rows: _currentList.entries.map((entry) {
                            return DataRow(
                              cells: _currentList.columns.map((col) {
                                return DataCell(Text(entry.data[col] ?? '-'));
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addNewEntry,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo, 
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddEntryDialog extends StatefulWidget {
  final List<String> columns;

  const _AddEntryDialog({required this.columns});

  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var col in widget.columns) {
      _controllers[col] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final data = <String, String>{};
    for (var entry in _controllers.entries) {
      data[entry.key] = entry.value.text.trim();
    }
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.columns.map((col) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[col],
                decoration: InputDecoration(
                  labelText: col,
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
