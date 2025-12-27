import 'package:flutter/material.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/case_service.dart';

class CaseDetailScreen extends StatefulWidget {
  final CaseModel caseModel;

  const CaseDetailScreen({super.key, required this.caseModel});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  bool _isLoading = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.caseModel.status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Case Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
            tooltip: 'Share Case',
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {},
            tooltip: 'Print Details',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, isDark),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDescriptionSection(theme, isDark),
                            const SizedBox(height: 24),
                            _buildLocationSection(theme, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildStatusCard(theme, isDark),
                            const SizedBox(height: 24),
                            _buildReporterCard(theme, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomActions(theme),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ImboniColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.folder_open, color: ImboniColors.primary, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.caseModel.caseReference,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.caseModel.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _buildPriorityBadge(isDark),
      ],
    );
  }

  Widget _buildPriorityBadge(bool isDark) {
    final color = ImboniColors.getUrgencyColor(widget.caseModel.urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            widget.caseModel.urgency,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.caseModel.description,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            if (widget.caseModel.audioUrl != null || widget.caseModel.imageUrl != null)
              _buildAttachments(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachments', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.caseModel.audioUrl != null)
              Chip(
                avatar: const Icon(Icons.audiotrack, size: 16),
                label: const Text('Voice Note'),
                backgroundColor: theme.colorScheme.secondaryContainer,
              ),
            if (widget.caseModel.imageUrl != null)
              Chip(
                avatar: const Icon(Icons.image, size: 16),
                label: const Text('Image Evidence'),
                backgroundColor: theme.colorScheme.secondaryContainer,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(theme, 'Province', 'Kigali City'), // Mock data, replace with real if available
             const SizedBox(height: 8),
            _buildInfoRow(theme, 'District', 'Gasabo'),
             const SizedBox(height: 8),
            _buildInfoRow(theme, 'Sector', widget.caseModel.currentLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    final statusColor = ImboniColors.getStatusColor(_status);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    _status.replaceAll('_', ' '),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Submitted on ${_formatDate(widget.caseModel.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReporterCard(ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reporter', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (widget.caseModel.citizenName != null && widget.caseModel.citizenName!.isNotEmpty) 
                        ? widget.caseModel.citizenName!.substring(0, 1).toUpperCase() 
                        : 'C',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.caseModel.citizenName ?? 'Citizen',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text('Citizen', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {
               // Implement escalation logic
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalation feature coming soon')));
            },
            icon: const Icon(Icons.arrow_upward),
            label: const Text('Escalate'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
               // Implement resolution logic
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resolution feature coming soon')));
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark Resolved'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ImboniColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
