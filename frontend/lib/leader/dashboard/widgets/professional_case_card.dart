import 'package:flutter/material.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/theme/colors.dart';

import 'package:intl/intl.dart';

class ProfessionalCaseCard extends StatelessWidget {
  final CaseModel caseData;
  final VoidCallback onTap;

  const ProfessionalCaseCard({
    super.key,
    required this.caseData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = ImboniColors.getStatusColor(caseData.status);
    final categoryColor = ImboniColors.getCategoryColor(caseData.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12), // 0.05 opacity approx
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withAlpha(30)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Colored Strip
              Container(
                width: 6,
                color: statusColor,
              ),

              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16), // Reduced from 20
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Added
                    children: [
                      // Header: Title + Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              caseData.title,
                              style: const TextStyle(
                                fontSize: 16, // Reduced from 18
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(caseData.status, statusColor),
                        ],
                      ),
                      
                      const SizedBox(height: 16), // Reduced from 24

                      // Details Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Column 1: Case ID
                          Expanded(
                            flex: 2,
                            child: _buildDetailItem(
                              label: 'Case ID',
                              value: '#${caseData.caseReference}',
                              valueStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                          // Column 2: Category
                          Expanded(
                            flex: 3,
                            child: _buildDetailItem(
                              label: 'Category',
                              value: caseData.category,
                              icon: Icons.category_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12), // Reduced from 16
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Column 3: Location
                          Expanded(
                            flex: 2,
                            child: _buildDetailItem(
                              label: 'Location',
                              value: caseData.locationName ?? 'Unknown',
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                          // Column 4: Submitted
                          Expanded(
                            flex: 3,
                            child: _buildDetailItem(
                              label: 'Submitted',
                              value: _formatTimeAgo(caseData.createdAt),
                              icon: Icons.access_time,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Footer Actions
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36, // Fixed height for button
                              child: OutlinedButton(
                                onPressed: onTap,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: ImboniColors.primary.withAlpha(100)),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  foregroundColor: ImboniColors.primary,
                                ),
                                child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 36, width: 36,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.withAlpha(50)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    String label = status.replaceAll('_', ' ');
    // Handle translation if needed or formatting
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withAlpha(255), // Full opacity for text
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailItem({required String label, required String value, IconData? icon, TextStyle? valueStyle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value,
                style: valueStyle ?? TextStyle(
                  fontSize: 14,
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(date);
  }
}
