import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = ImboniColors.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.replaceAll('_', ' '), 
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class UrgencyChip extends StatelessWidget {
  final String urgency;
  
  const UrgencyChip({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    final color = ImboniColors.getUrgencyColor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
      child: Text(
        urgency, 
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
