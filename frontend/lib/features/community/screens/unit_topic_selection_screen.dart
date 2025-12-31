import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imboni/shared/theme/colors.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import 'channel_chat_screen.dart';

class UnitTopicSelectionScreen extends StatelessWidget {
  final CommunityChannel generalChannel;
  final bool embedded;
  final void Function(CommunityChannel)? onChannelSelected;

  const UnitTopicSelectionScreen({
    super.key,
    required this.generalChannel,
    this.embedded = false,
    this.onChannelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unitName = generalChannel.unit?.name ?? generalChannel.name.split(' - ').first;
    final level = generalChannel.unit?.level ?? 'UNIT';

    String levelTitle = 'Urwego';
    switch (level) {
      case 'CELL':
        levelTitle = 'Akagari';
        break;
      case 'SECTOR':
        levelTitle = 'Umurenge';
        break;
      case 'DISTRICT':
        levelTitle = 'Akarere';
        break;
      case 'PROVINCE':
        levelTitle = 'Intara';
        break;
      case 'NATIONAL':
        levelTitle = 'Igihugu';
        break;
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header for embedded mode
        if (embedded)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ImboniColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.topic, color: ImboniColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unitName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$levelTitle - Hitamo Ikiganiro',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Topic Grid
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Amatsinda y'Ibyiciro",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildTopicCard(context, 'Ubuzima', 'HEALTH', Icons.medical_services_outlined, Colors.red),
                    _buildTopicCard(context, 'Ubutaka', 'LAND', Icons.landscape_outlined, Colors.brown),
                    _buildTopicCard(context, 'Ibikorwaremezo', 'INFRASTRUCTURE', Icons.add_road, Colors.blueGrey),
                    _buildTopicCard(context, 'Umutekano', 'SECURITY', Icons.security, Colors.blue),
                    _buildTopicCard(context, 'Ubutabera', 'JUSTICE', Icons.balance, Colors.indigo),
                    _buildTopicCard(context, 'Imibereho', 'SOCIAL', Icons.people_outline, Colors.teal),
                    _buildTopicCard(context, 'Uburezi', 'EDUCATION', Icons.school_outlined, Colors.orange),
                    _buildTopicCard(context, 'Ibindi', 'OTHER', Icons.more_horiz, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(unitName, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: content,
    );
  }

  Widget _buildTopicCard(BuildContext context, String label, String category, IconData icon, Color color) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () {
          debugPrint('Topic tapped: $category');
          _handleTopicTap(context, category);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTopicTap(BuildContext context, String category) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = context.read<CommunityProvider>();
      final unitId = generalChannel.administrativeUnitId;

      final channel = await provider.joinCategoryChannel(unitId, category);

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        if (channel != null) {
          // If embedded and callback provided, use callback instead of navigation
          if (embedded && onChannelSelected != null) {
            onChannelSelected!(channel);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel)),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to join channel')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }
}
