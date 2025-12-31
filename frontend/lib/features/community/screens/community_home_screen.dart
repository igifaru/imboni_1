import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imboni/shared/theme/colors.dart';
import '../providers/community_provider.dart';
import '../models/community_models.dart';
import 'channel_chat_screen.dart';

import 'unit_topic_selection_screen.dart';

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch channels on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchChannels();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Civic Connect'),
          centerTitle: false,
          bottom: const TabBar(
            labelColor: ImboniColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: ImboniColors.primary,
            tabs: [
              Tab(text: 'My Units'), // Renamed from My Channels
              Tab(text: 'Discover'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _MyChannelsTab(),
            _DiscoverTab(),
          ],
        ),
      ),
    );
  }
}

class _MyChannelsTab extends StatelessWidget {
  const _MyChannelsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingChannels && provider.channels.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text('Error loading channels: ${provider.error}'),
                TextButton(
                  onPressed: () => provider.fetchChannels(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        Widget content;
        if (provider.channels.isEmpty) {
          content = SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
               height: MediaQuery.of(context).size.height * 0.7,
               child: _buildEmptyState(context, provider)
            ),
          );
        } else {
          // Filter only GENERAL channels for the main list
          final generalChannels = provider.channels.where((c) => c.category == null).toList();

          // Sort
          generalChannels.sort((a, b) {
             const levelOrder = {
              'VILLAGE': 0,
              'CELL': 1,
              'SECTOR': 2,
              'DISTRICT': 3,
              'PROVINCE': 4,
              'NATIONAL': 5,
            };
            final levelA = levelOrder[a.unit?.level] ?? 99;
            final levelB = levelOrder[b.unit?.level] ?? 99;
            return levelA.compareTo(levelB);
          });

          content = ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: generalChannels.length,
            itemBuilder: (context, index) {
              final channel = generalChannels[index];
              return _buildUnitCard(context, channel);
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchChannels(),
          child: content,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, CommunityProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ImboniColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_outlined, size: 64, color: ImboniColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'No channels yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect with your local community. Join channels based on your location to start discussing issues.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                provider.fetchChannels();
              },
              icon: const Icon(Icons.explore),
              label: const Text('Discover Local Channels'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ImboniColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, CommunityChannel channel) {
    final level = channel.unit?.level ?? 'UNIT'; 
    String levelTitle = 'Unit';
    IconData icon = Icons.public;
    
    switch (level) {
      case 'VILLAGE':
        levelTitle = 'Umudugudu Wanjye';
        icon = Icons.home;
        break;
      case 'CELL':
        levelTitle = 'Akagari Kanjye';
        icon = Icons.groups;
        break;
      case 'SECTOR':
        levelTitle = 'Umurenge Wanjye';
        icon = Icons.apartment;
        break;
      case 'DISTRICT':
        levelTitle = 'Akarere Kanjye';
        icon = Icons.location_city;
        break;
      case 'PROVINCE':
        levelTitle = 'Intara Yanjye';
        icon = Icons.map;
        break;
      case 'NATIONAL':
        levelTitle = "Urwego rw'Igihugu";
        icon = Icons.flag;
        break;
    }

    final displayName = channel.name.split(' - ').first;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ImboniColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: ImboniColors.primary),
        ),
        title: Text(
          levelTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          displayName,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          if (level == 'VILLAGE') {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChannelChatScreen(channel: channel),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UnitTopicSelectionScreen(generalChannel: channel),
              ),
            );
          }
        },
      ),
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Coming Soon: Browse channels by interest'),
    );
  }
}


