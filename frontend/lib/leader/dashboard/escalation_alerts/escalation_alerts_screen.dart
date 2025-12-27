import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';

/// Escalation Alerts Screen
class EscalationAlertsScreen extends StatelessWidget {
  const EscalationAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Escalation Alerts')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ImboniColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: ImboniColors.warning.withOpacity(0.3))),
          child: Row(children: [const Icon(Icons.info_outline, color: ImboniColors.warning), const SizedBox(width: 12), Expanded(child: Text('Cases with approaching deadlines require immediate attention.', style: theme.textTheme.bodyMedium))]),
        ),
        const SizedBox(height: 24),
        Text('Approaching Deadline (3)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _AlertCard(caseReference: 'IMB-XYZ123-AB', title: 'Land dispute in Umurenge', hoursRemaining: 2, urgency: 'HIGH'),
        _AlertCard(caseReference: 'IMB-ABC456-CD', title: 'Health clinic access issue', hoursRemaining: 5, urgency: 'NORMAL'),
        _AlertCard(caseReference: 'IMB-DEF789-EF', title: 'Road infrastructure damage', hoursRemaining: 8, urgency: 'NORMAL'),
      ]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String caseReference, title, urgency;
  final int hoursRemaining;

  const _AlertCard({required this.caseReference, required this.title, required this.hoursRemaining, required this.urgency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = urgency == 'HIGH' || urgency == 'EMERGENCY';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUrgent ? ImboniColors.error.withOpacity(0.05) : null,
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(caseReference, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: hoursRemaining < 4 ? ImboniColors.error.withOpacity(0.1) : ImboniColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timer_outlined, size: 14, color: hoursRemaining < 4 ? ImboniColors.error : ImboniColors.warning),
              const SizedBox(width: 4),
              Text('${hoursRemaining}h', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hoursRemaining < 4 ? ImboniColors.error : ImboniColors.warning)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('View Details'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Take Action'))),
        ]),
      ])),
    );
  }
}
