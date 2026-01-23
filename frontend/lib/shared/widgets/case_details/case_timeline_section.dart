import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/localization/app_localizations.dart';
import 'package:imboni/shared/utils/case_helper.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'package:intl/intl.dart';

class CaseTimelineSection extends StatefulWidget {
  final CaseModel caseModel;
  final List<CaseAction> actions;

  const CaseTimelineSection({
    super.key,
    required this.caseModel,
    required this.actions,
  });

  @override
  State<CaseTimelineSection> createState() => _CaseTimelineSectionState();
}

class _CaseTimelineSectionState extends State<CaseTimelineSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark ? theme.colorScheme.surfaceContainer : Colors.white;
    final textColor = isDark ? theme.colorScheme.onSurface : Colors.black87;
    final subTextColor = isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[700]!;

    // Build timeline items logic
    final timelineItems = _buildTimelineItems(l10n, widget.actions, widget.caseModel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withAlpha(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 38 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.timeline,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Horizontal Timeline List
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: timelineItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast = index == timelineItems.length - 1;
                  
                      return _buildTimelineItemWidget(context, item, index, isLast, timelineItems, isDark, textColor, subTextColor);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItemWidget(BuildContext context, _TimelineData item, int index, bool isLast, List<_TimelineData> timelineItems, bool isDark, Color textColor, Color subTextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Item Card
        Column(
          children: [
            Container(
              width: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.isCurrent 
                    ? item.color.withValues(alpha: 0.1) 
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item.isCurrent 
                      ? item.color 
                      : (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2)),
                  width: item.isCurrent ? 2 : 1,
                ),
                boxShadow: item.isCurrent ? [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, size: 18, color: item.color),
                      ),
                      const SizedBox(width: 12),
                      if (item.isCurrent)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 2,
                              )
                            ]
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: item.isCurrent ? item.color : textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: subTextColor),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item.date),
                            style: TextStyle(fontSize: 11, color: subTextColor),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 12, color: subTextColor),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(item.date),
                            style: TextStyle(fontSize: 11, color: subTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.notes!,
                        style: TextStyle(
                          fontSize: 11, 
                          color: textColor.withValues(alpha: 0.8), 
                          fontStyle: FontStyle.italic
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        
        // Horizontal Connector
        if (!isLast)
           Container(
             height: 2,
             width: 40,
             margin: const EdgeInsets.only(top: 40, left: 4, right: 4),
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 colors: [
                   item.color.withValues(alpha: 0.5), 
                   timelineItems[index+1].color.withValues(alpha: 0.5)
                 ],
               ),
             ),
           ),
      ],
    );
  }

  List<_TimelineData> _buildTimelineItems(AppLocalizations l10n, List<CaseAction> actions, CaseModel caseModel) {
    // 1. Start with Creation
    final List<_TimelineData> timelineItems = [
      _TimelineData(
        title: l10n.caseCreated,
        date: caseModel.createdAt,
        color: ImboniColors.primary,
        icon: Icons.add_circle_outline,
      )
    ];

    // 2. Add Actions (Oldest to Newest)
    if (actions.isNotEmpty) {
      final sortedActions = List<CaseAction>.from(actions);
      sortedActions.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final action in sortedActions) {
        if (action.actionType == 'CREATED' && 
            action.createdAt.difference(caseModel.createdAt).inMinutes.abs() < 1) {
          continue;
        }
        
        String? displayNotes = action.notes;
        if (displayNotes != null && displayNotes.isNotEmpty) {
           displayNotes = _formatActionNotes(l10n, displayNotes);
        }

        timelineItems.add(_TimelineData(
          title: _getActionTitle(l10n, action.actionType),
          date: action.createdAt,
          color: _getActionColor(action.actionType),
          icon: _getActionIcon(action.actionType),
          notes: displayNotes,
        ));
      }
    } else {
       if (caseModel.status != 'OPEN') {
          timelineItems.add(_TimelineData(
             title: l10n.caseAccepted,
             date: caseModel.createdAt.add(const Duration(minutes: 5)),
             color: ImboniColors.statusInProgress,
             icon: Icons.assignment_ind, 
          ));
       }
    }

    // 3. Synthesize Current Status Node
    final lastItem = timelineItems.last;
    final status = caseModel.status;
    
    bool needsStatusNode = true;
    if (_getActionTitle(l10n, status).toLowerCase() == lastItem.title.toLowerCase()) {
      needsStatusNode = false;
    }
    
    if (status == 'PENDING_CONFIRMATION') {
       needsStatusNode = true;
    }

    if (needsStatusNode) {
       Color statusColor = ImboniColors.primary;
       IconData statusIcon = Icons.circle;
       String statusTitle = CaseHelper.getStatusLabel(l10n, status);
       
       switch(status) {
         case 'PENDING_CONFIRMATION':
           statusColor = ImboniColors.warning;
           statusIcon = Icons.hourglass_bottom;
           statusTitle = l10n.pendingConfirmation;
           break;
         case 'RESOLVED':
           statusColor = ImboniColors.success;
           statusIcon = Icons.check_circle;
           break;
         case 'ESCALATED':
           statusColor = Colors.red;
           statusIcon = Icons.trending_up;
           break;
         case 'IN_PROGRESS':
           statusColor = ImboniColors.statusInProgress;
           statusIcon = Icons.pending;
           break;
       }
       
       if (statusTitle != lastItem.title && status != 'OPEN') {
          timelineItems.add(_TimelineData(
            title: statusTitle,
            date: DateTime.now(),
            color: statusColor,
            icon: statusIcon,
            isCurrent: true,
          ));
       } else {
         timelineItems[timelineItems.length - 1] = _TimelineData(
            title: lastItem.title,
            date: lastItem.date,
            color: lastItem.color,
            icon: lastItem.icon,
            notes: lastItem.notes,
            isCurrent: true,
         );
       }
    } else {
       timelineItems[timelineItems.length - 1] = _TimelineData(
          title: lastItem.title,
          date: lastItem.date,
          color: lastItem.color,
          icon: lastItem.icon,
          notes: lastItem.notes,
          isCurrent: true,
       );
    }
    return timelineItems;
  }

  String _getActionTitle(AppLocalizations l10n, String type) {
    switch (type) {
      case 'CREATED': return l10n.caseCreated;
      case 'ESCALATED': return l10n.caseEscalated;
      case 'RESOLVED': return l10n.caseResolved;
      case 'VIEWED': return l10n.caseViewed;
      case 'ASSIGNED': return l10n.caseAssigned;
      case 'ASSIGNMENT': return l10n.caseAssignment;
      case 'ACCEPTED': return l10n.caseAccepted;
      case 'STATUS_UPDATE': return l10n.statusUpdate;
      case 'RESOLUTION': return l10n.resolution;
      case 'PENDING_CONFIRMATION': return l10n.pendingConfirmation;
      default: return type.replaceAll('_', ' ').toLowerCase().split(' ').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join(' ');
    }
  }

  String _formatActionNotes(AppLocalizations l10n, String note) {
    if (note.contains('Manually assigned to specific leader')) return l10n.noteManualAssignment;
    if (note.contains('Deadline extended by')) return l10n.noteDeadlineExtended;
    if (note.startsWith('Status changed to ')) {
      final statusPart = note.replaceFirst('Status changed to ', '');
      return '${l10n.statusChangedTo} ${CaseHelper.getStatusLabel(l10n, statusPart)}';
    }
    if (note.contains('Citizen confirmed resolution')) return l10n.caseResolved;
    return note;
  }

  Color _getActionColor(String type) {
    switch (type) {
      case 'CREATED': return ImboniColors.info;
      case 'ESCALATED': return ImboniColors.categoryJustice;
      case 'RESOLVED': return ImboniColors.success;
      case 'VIEWED': return Colors.grey;
      case 'ASSIGNED': return ImboniColors.secondary;
      case 'ASSIGNMENT': return ImboniColors.secondary;
      case 'ACCEPTED': return ImboniColors.primary;
      case 'STATUS_UPDATE': return ImboniColors.statusInProgress;
      case 'RESOLUTION': return ImboniColors.success;
      case 'PENDING_CONFIRMATION': return ImboniColors.warning;
      default: return Colors.grey;
    }
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'CREATED': return Icons.add_circle_outline;
      case 'ESCALATED': return Icons.arrow_upward;
      case 'RESOLVED': return Icons.check_circle_outline;
      case 'VIEWED': return Icons.visibility;
      case 'ASSIGNED': return Icons.person_add;
      case 'ASSIGNMENT': return Icons.assignment_ind;
      case 'ACCEPTED': return Icons.thumb_up_alt_outlined;
      case 'STATUS_UPDATE': return Icons.update;
      case 'RESOLUTION': return Icons.task_alt;
      case 'PENDING_CONFIRMATION': return Icons.hourglass_bottom;
      default: return Icons.info_outline;
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String _formatTime(DateTime date) => DateFormat('HH:mm').format(date);
}

class _TimelineData {
  final String title;
  final DateTime date;
  final Color color;
  final IconData icon;
  final String? notes;
  final bool isCurrent;

  _TimelineData({
    required this.title,
    required this.date,
    required this.color,
    required this.icon,
    this.notes,
    this.isCurrent = false,
  });
}
