import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/localization/app_localizations.dart';
import '../../models/community_models.dart';

class CollaborativeListView extends StatelessWidget {
  final CommunityAttachment attachment;
  final Function(Map<String, String>) onAddEntry;
  final Function(int, Map<String, String>)? onEditEntry;
  final Function(String, List<String>)? onUpdateList;
  final String currentUserId;
  final String currentUserName;
  final bool isCreator;

  const CollaborativeListView({
    super.key,
    required this.attachment,
    required this.onAddEntry,
    this.onEditEntry,
    this.onUpdateList,
    required this.currentUserId,
    required this.currentUserName,
    this.isCreator = false,
  });

  @override
  Widget build(BuildContext context) {
    try {
      if (attachment.type != AttachmentType.collaborativeList || 
          attachment.metadata == null) {
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
              '${list.entries.length} ${AppLocalizations.of(context).entries}',
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
                child: Text(AppLocalizations.of(context).viewList),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  void _showListDetails(BuildContext context, CollaborativeList list) {
    showDialog(
      context: context,
      builder: (context) => _ListDetailDialog(
        list: list,
        onAddEntry: onAddEntry,
        onEditEntry: onEditEntry,
        onUpdateList: onUpdateList,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        isCreator: isCreator,
      ),
    );
  }
}

class _ListDetailDialog extends StatefulWidget {
  final CollaborativeList list;
  final Function(Map<String, String>) onAddEntry;
  final Function(int, Map<String, String>)? onEditEntry;
  final Function(String, List<String>)? onUpdateList;
  final String currentUserId;
  final String currentUserName;
  final bool isCreator;

  const _ListDetailDialog({
    required this.list,
    required this.onAddEntry,
    this.onEditEntry,
    this.onUpdateList,
    required this.currentUserId,
    required this.currentUserName,
    this.isCreator = false,
  });

  @override
  State<_ListDetailDialog> createState() => _ListDetailDialogState();
}

class _ListDetailDialogState extends State<_ListDetailDialog> {
  late CollaborativeList _currentList;
  bool _isExporting = false;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentList = widget.list;
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
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

  Future<void> _exportToExcel() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      List<CellValue> headerRow = _currentList.columns
          .map((c) => TextCellValue(c))
          .toList();
      sheetObject.appendRow(headerRow);

      for (var entry in _currentList.entries) {
        List<CellValue> row = _currentList.columns.map((col) {
          return TextCellValue(entry.data[col] ?? '');
        }).toList();
        sheetObject.appendRow(row);
      }

      var fileBytes = excel.save();
      final fileName = _currentList.title
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_');

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$fileName.xlsx';
      final file = File(path);

      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);

        if (!mounted) return;

        await Share.shareXFiles(
          [XFile(path)],
          text: 'Exported List: ${_currentList.title}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).excelExportFailed}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportToCsv() async {
    if (_isExporting) return;
    
    setState(() => _isExporting = true);
    
    try {
      final buffer = StringBuffer();

      buffer.writeln(
        _currentList.columns
            .map((col) => _escapeCsvField(col))
            .join(','),
      );

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
          content: Text('${AppLocalizations.of(context).exportFailed}: $e'),
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
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _currentList.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isCreator)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                            tooltip: 'Edit Title/Columns',
                            onPressed: _showUpdateListDialog,
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.download, size: 20),
                        tooltip: 'Export',
                        enabled: !_isExporting,
                        onSelected: (value) {
                          if (value == 'excel') _exportToExcel();
                          if (value == 'csv') _exportToCsv();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'excel',
                            child: Row(
                              children: [
                                const Icon(Icons.table_chart, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context).exportAsExcel),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'csv',
                            child: Row(
                              children: [
                                const Icon(Icons.description, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context).exportAsCsv),
                              ],
                            ),
                          ),
                        ],
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
                          AppLocalizations.of(context).noEntriesYet,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildResponsiveTable(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _addNewEntry,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(AppLocalizations.of(context).addYourEntry),
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

  void _showUpdateListDialog() async {
    final titleController = TextEditingController(text: _currentList.title);
    final columnsController = TextEditingController(text: _currentList.columns.join(', '));
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).editListStructure,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).listTitle,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: columnsController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).columnsCommaSeparated,
                      helperText: AppLocalizations.of(context).columnsDataWarning,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'title': titleController.text.trim(),
                          'columns': columnsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(AppLocalizations.of(context).save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null && widget.onUpdateList != null) {
      final newTitle = result['title'] as String;
      final newColumns = result['columns'] as List<String>;
      
      widget.onUpdateList!(newTitle, newColumns);
      
      if (mounted) {
        setState(() {
          _currentList = CollaborativeList(
            title: newTitle,
            columns: newColumns,
            entries: _currentList.entries,
          );
        });
      }
    }
  }

  void _editEntry(int index) async {
    final entry = _currentList.entries[index];
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddEntryDialog(
        columns: _currentList.columns,
        initialData: entry.data,
      ),
    );

    if (result != null && widget.onEditEntry != null) {
      widget.onEditEntry!(index, result);
      
      if (mounted) {
        setState(() {
          final newEntries = List<ListEntry>.from(_currentList.entries);
          newEntries[index] = ListEntry(
             userId: entry.userId,
             userName: entry.userName,
             timestamp: DateTime.now(),
             data: result,
          );
          
          _currentList = CollaborativeList(
            title: _currentList.title,
            columns: _currentList.columns,
            entries: newEntries,
          );
        });
      }
    }
  }

  Widget _buildResponsiveTable() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final columnWidth = 140.0;
    final totalTableWidth = columnWidth * _currentList.columns.length + 50;

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            controller: _verticalController,
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
                  _currentList.columns.length: const FixedColumnWidth(50),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    ),
                    children: [
                      ..._currentList.columns.map((col) => Container(
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
                              )),
                      const SizedBox(),
                    ],
                  ),
                  ..._currentList.entries.asMap().entries.map((rowEntry) {
                    final rowIndex = rowEntry.key;
                    final entry = rowEntry.value;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: rowIndex % 2 == 0
                            ? colorScheme.surfaceContainerHighest.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      children: [
                           ..._currentList.columns.map((col) => Container(
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
                              )),
                              if (entry.userId == widget.currentUserId)
                                Container(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                    onPressed: () => _editEntry(rowIndex),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                )
                              else 
                                const SizedBox(),
                        ],
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

class _AddEntryDialog extends StatelessWidget {
  final List<String> columns;
  final Map<String, String>? initialData;

  const _AddEntryDialog({
    required this.columns,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return _AddEntryDialogContent(
      columns: columns,
      initialData: initialData,
    );
  }
}

class _AddEntryDialogContent extends StatefulWidget {
  final List<String> columns;
  final Map<String, String>? initialData;

  const _AddEntryDialogContent({
    required this.columns,
    this.initialData,
  });

  @override
  State<_AddEntryDialogContent> createState() => _AddEntryDialogContentState();
}

class _AddEntryDialogContentState extends State<_AddEntryDialogContent> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var col in widget.columns) {
      _controllers[col] = TextEditingController(text: widget.initialData?[col] ?? '');
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
        SnackBar(content: Text(AppLocalizations.of(context).fillAtLeastOneField)),
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialData != null ? AppLocalizations.of(context).editEntry : AppLocalizations.of(context).addEntry,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...widget.columns
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.initialData != null ? AppLocalizations.of(context).saveChanges : AppLocalizations.of(context).addEntry,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).cancel,
                      style: const TextStyle(fontSize: 14),
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