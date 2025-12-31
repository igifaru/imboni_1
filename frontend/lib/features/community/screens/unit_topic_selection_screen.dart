import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import 'channel_chat_screen.dart';

class UnitTopicSelectionScreen extends StatelessWidget {
  final CommunityChannel generalChannel;

  const UnitTopicSelectionScreen({super.key, required this.generalChannel});

  @override
  Widget build(BuildContext context) {
    final unitName = generalChannel.unit?.name ?? generalChannel.name.split(' - ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(unitName, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amatsinda y\'Ibyiciro (Topic Subgroups)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildTopicCard(context, 'Ubuzima', 'HEALTH', Icons.medical_services_outlined, Colors.red),
                _buildTopicCard(context, 'Ubutaka', 'LAND', Icons.landscape_outlined, Colors.brown),
                _buildTopicCard(context, 'Ibikorwaremezo', 'INFRASTRUCTURE', Icons.add_road, Colors.grey),
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
    );
  }

  Widget _buildTopicCard(BuildContext context, String label, String category, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _handleTopicTap(context, category),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTopicTap(BuildContext context, String category) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = context.read<CommunityProvider>();
      final unitId = generalChannel.administrativeUnitId;

      // Check if we already have this channel in our provider list? 
      // The provider.channels usually just has 'General' channels initially if we filtered that way,
      // But fetchChannels might return all. 
      // Ideally we check if we're already a member.
      
      // For now, always call join which handles "get or create"
      final channel = await provider.joinCategoryChannel(unitId, category);

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        if (channel != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel)),
          );
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
