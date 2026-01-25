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
    try {
      if (attachment.type != AttachmentType.collaborativeList || 
          attachment.metadata == null) {
        debugPrint('[CollaborativeListView] Hidden. Type=${attachment.type}');
        return const SizedBox.shrink();
      }

      final list = CollaborativeList.fromJson(attachment.metadata!);
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    list.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${list.entries.length} entries',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showListDetails(context, list),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.indigo),
                  foregroundColor: Colors.indigo,
                ),
                child: const Text('View List'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[CollaborativeListView] Error: $e');
      return const SizedBox.shrink();
    }
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
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _currentList = widget.list;
  }

  void _addNewEntry() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddEntryDialog(
        columns: _currentList.columns,
      ),
    );

    if (result != null && result.isNotEmpty) {
      widget.onAddEntry(result);
      
      final newEntry = ListEntry(
        userId: widget.currentUserId,
        userName: widget.currentUserName,
        data: result,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _currentList = CollaborativeList(
            title: _currentList.title,
            columns: _currentList.columns,
            entries: [..._currentList.entries, newEntry],
          );
        });
      }
    }
  }

  Future<void> _exportToCsv() async {
    if (_isExporting) return;
    
    setState(() => _isExporting = true);
    
    try {
      final buffer = StringBuffer();

      // Header with proper CSV escaping
      buffer.writeln(
        _currentList.columns
            .map((col) => _escapeCsvField(col))
            .join(','),
      );

      // Rows with proper CSV escaping
      for (final entry in _currentList.entries) {
        final row = _currentList.columns
            .map((col) => _escapeCsvField(entry.data[col] ?? ''))
            .join(',');
        buffer.writeln(row);
      }

      final csvContent = buffer.toString();
      final fileName = _currentList.title
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_');

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$fileName.csv';
      final file = File(path);
      
      await file.writeAsString(csvContent);

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Exported List: ${_currentList.title}',
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final dialogWidth = isMobile ? size.width * 0.95 : 900.0;
    final dialogHeight = size.height * 0.9;

    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _currentList.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: 'Export CSV',
                        onPressed: _isExporting ? null : _exportToCsv,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Table Content - Fully scrollable
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.withValues(alpha: 0.02),
                ),
                child: _currentList.entries.isEmpty
                    ? Center(
                        child: Text(
                          'No entries yet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildResponsiveTable(),
                      ),
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _addNewEntry,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Your Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveTable() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final columnWidth = 140.0;
    final totalTableWidth = columnWidth * _currentList.columns.length;

    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) => notification.depth == 1,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: totalTableWidth,
              child: Table(
                border: TableBorder(
                  top: BorderSide(color: colorScheme.outlineVariant),
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                  horizontalInside: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                  verticalInside: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                columnWidths: {
                  for (int i = 0; i < _currentList.columns.length; i++)
                    i: FixedColumnWidth(columnWidth),
                },
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    ),
                    children: _currentList.columns
                        .map((col) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: Text(
                                col,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                              ),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                  ),
                  // Data rows
                  ..._currentList.entries.asMap().entries.map((rowEntry) {
                    final rowIndex = rowEntry.key;
                    final entry = rowEntry.value;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: rowIndex % 2 == 0
                            ? colorScheme.surfaceContainerHighest.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      children: _currentList.columns
                          .map((col) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Text(
                                  entry.data[col] ?? '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                  softWrap: true,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                    );
                  }).toList(),
                ],
              ),
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
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final data = <String, String>{};
    for (var entry in _controllers.entries) {
      data[entry.key] = entry.value.text.trim();
    }
    
    if (data.values.every((v) => v.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill at least one field')),
      );
      return;
    }
    
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 500;
    final dialogWidth = isMobile ? size.width * 0.9 : 450.0;
    final screenHeight = size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: screenHeight * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Add Entry',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            // Form Fields
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.columns
                        .map((col) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextField(
                                controller: _controllers[col],
                                decoration: InputDecoration(
                                  labelText: col,
                                  hintText: 'Enter $col',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}