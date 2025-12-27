import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/case_service.dart';
import '../case_detail/case_detail_screen.dart';

/// Escalation Alerts Screen
class EscalationAlertsScreen extends StatefulWidget {
  const EscalationAlertsScreen({super.key});

  @override
  State<EscalationAlertsScreen> createState() => _EscalationAlertsScreenState();
}

class _EscalationAlertsScreenState extends State<EscalationAlertsScreen> {
  List<CaseModel> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final response = await caseService.getEscalationAlerts();
      if (mounted) {
        setState(() {
          _alerts = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Escalation Alerts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_alerts.isEmpty)
                   Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: ImboniColors.success.withAlpha(100)),
                          const SizedBox(height: 16),
                          Text('All Clear!', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('No cases require immediate attention.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ImboniColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ImboniColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: ImboniColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cases with approaching deadlines require immediate attention.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Approaching Deadline (${_alerts.length})', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ..._alerts.map((alert) => _AlertCard(caseModel: alert, hoursRemaining: _calculateHoursRemaining(alert))),
                ],
              ],
            ),
    );
  }

  int _calculateHoursRemaining(CaseModel c) {
    // Basic fallback logic if deadline isn't available in simplified model, 
    // assuming backend sorted them by urgency/deadline.
    // In real app, CaseModel would have 'deadlineAt'.
    // Here we simulate for display or use createdAt logic if deadline missing.
    return 24; 
  }
}

class _AlertCard extends StatelessWidget {
  final CaseModel caseModel;
  final int hoursRemaining;

  const _AlertCard({required this.caseModel, required this.hoursRemaining});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = caseModel.urgency == 'HIGH' || caseModel.urgency == 'EMERGENCY';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUrgent ? ImboniColors.error.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  caseModel.caseReference,
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hoursRemaining < 4 ? ImboniColors.error.withOpacity(0.1) : ImboniColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: hoursRemaining < 4 ? ImboniColors.error : ImboniColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${hoursRemaining}h',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hoursRemaining < 4 ? ImboniColors.error : ImboniColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(caseModel.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CaseDetailScreen(caseModel: caseModel)),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // For now, same as View Details, or maybe pass a flag to open action sheet immediately
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CaseDetailScreen(caseModel: caseModel)),
                      );
                    },
                    child: const Text('Take Action'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
