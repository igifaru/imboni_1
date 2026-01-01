import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imboni/shared/theme/colors.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import 'channel_chat_screen.dart';

class UnitTopicSelectionScreen extends StatefulWidget {
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
  State<UnitTopicSelectionScreen> createState() => _UnitTopicSelectionScreenState();
}

class _UnitTopicSelectionScreenState extends State<UnitTopicSelectionScreen> {
  String? _loadingCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unitName = widget.generalChannel.unit?.name ?? widget.generalChannel.name.split(' - ').first;
    final level = widget.generalChannel.unit?.level ?? 'UNIT';

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
        if (widget.embedded)
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

        // Topic Grid - Responsive layout
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive columns: 4 on wide, 3 on medium, 2 on mobile
              int crossAxisCount = 2;
              double aspectRatio = 1.2;
              if (constraints.maxWidth > 600) {
                crossAxisCount = 4;
                aspectRatio = 1.4;
              } else if (constraints.maxWidth > 400) {
                crossAxisCount = 3;
                aspectRatio = 1.3;
              }

              return SingleChildScrollView(
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
                    const SizedBox(height: 12),
                    Consumer<CommunityProvider>(
                      builder: (context, provider, _) {
                        final unitId = widget.generalChannel.administrativeUnitId;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: aspectRatio,
                          children: [
                            _buildTopicCard(context, 'Ubuzima', 'HEALTH', Icons.medical_services_outlined, Colors.red, provider.getTopicMessageCount(unitId, 'HEALTH')),
                            _buildTopicCard(context, 'Ubutaka', 'LAND', Icons.landscape_outlined, Colors.brown, provider.getTopicMessageCount(unitId, 'LAND')),
                            _buildTopicCard(context, 'Ibikorwaremezo', 'INFRASTRUCTURE', Icons.add_road, Colors.blueGrey, provider.getTopicMessageCount(unitId, 'INFRASTRUCTURE')),
                            _buildTopicCard(context, 'Umutekano', 'SECURITY', Icons.security, Colors.blue, provider.getTopicMessageCount(unitId, 'SECURITY')),
                            _buildTopicCard(context, 'Ubutabera', 'JUSTICE', Icons.balance, Colors.indigo, provider.getTopicMessageCount(unitId, 'JUSTICE')),
                            _buildTopicCard(context, 'Imibereho', 'SOCIAL', Icons.people_outline, Colors.teal, provider.getTopicMessageCount(unitId, 'SOCIAL')),
                            _buildTopicCard(context, 'Uburezi', 'EDUCATION', Icons.school_outlined, Colors.orange, provider.getTopicMessageCount(unitId, 'EDUCATION')),
                            _buildTopicCard(context, 'Ibindi', 'OTHER', Icons.more_horiz, Colors.purple, provider.getTopicMessageCount(unitId, 'OTHER')),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) {
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

  Widget _buildTopicCard(BuildContext context, String label, String category, IconData icon, Color color, int messageCount) {
    final isLoading = _loadingCategory == category;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: _loadingCategory != null ? null : () { // Disable if any category is loading
          debugPrint('Topic tapped: $category');
          _handleTopicTap(context, category);
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Center(
                child: isLoading 
                    ? SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: color)
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
            ),
            // Badge for message count
            if (messageCount > 0 && !isLoading)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    messageCount > 99 ? '99+' : messageCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTopicTap(BuildContext context, String category) async {
    setState(() {
      _loadingCategory = category;
    });

    try {
      final provider = context.read<CommunityProvider>();
      final unitId = widget.generalChannel.administrativeUnitId;

      // Add a timeout to prevent infinite hanging
      final channel = await provider.joinCategoryChannel(unitId, category).timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );

      if (mounted) {
        setState(() {
          _loadingCategory = null;
        });

        if (channel != null) {
          // If embedded and callback provided, use callback instead of navigation
          if (widget.embedded && widget.onChannelSelected != null) {
            widget.onChannelSelected!(channel);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel)),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to join channel. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCategory = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
