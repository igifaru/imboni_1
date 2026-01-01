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
  CommunityChannel? _selectedChannel;
  CommunityChannel? _parentChannel; // Track parent for topic channel back navigation

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchChannels();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Civic Connect'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (isWide) {
            return _buildWideLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  /// Wide screen layout with left panel (units) and right panel (content)
  Widget _buildWideLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Left Panel - Unit List
        Container(
          width: 320,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: Column(
            children: [
              // Header
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
                    const Icon(Icons.location_on, color: ImboniColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Aho Ntuye',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Unit List
              Expanded(child: _buildUnitList(context, isWide: true)),
            ],
          ),
        ),

        // Right Panel - Content
        Expanded(
          child: _selectedChannel == null
              ? _buildWelcomePanel(context)
              : _buildContentPanel(context),
        ),
      ],
    );
  }

  /// Mobile layout - just shows unit list (no tabs)
  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: ImboniColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Aho Ntuye',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        // Unit list
        Expanded(
          child: _buildUnitList(context, isWide: false),
        ),
      ],
    );
  }

  /// Build the unit list (used in both layouts)
  Widget _buildUnitList(BuildContext context, {required bool isWide}) {
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
                Text('Error: ${provider.error}', textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => provider.fetchChannels(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.channels.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchChannels(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: _buildEmptyState(context, provider),
              ),
            ),
          );
        }

        // Filter only GENERAL channels
        final generalChannels = provider.channels.where((c) => c.category == null).toList();

        // Sort by level
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

        return RefreshIndicator(
          onRefresh: () => provider.fetchChannels(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: generalChannels.length,
            itemBuilder: (context, index) {
              final channel = generalChannels[index];
              return _buildUnitCard(context, channel, isWide: isWide);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, CommunityProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ImboniColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_outlined, size: 48, color: ImboniColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No channels yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with your local community',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchChannels(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ImboniColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, CommunityChannel channel, {required bool isWide}) {
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
    final isSelected = _selectedChannel?.id == channel.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isSelected ? ImboniColors.primary.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? ImboniColors.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ImboniColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: ImboniColors.primary, size: 20),
        ),
        title: Text(
          levelTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected ? ImboniColors.primary : null,
          ),
        ),
        subtitle: Text(
          displayName,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isSelected ? ImboniColors.primary : Colors.grey,
          size: 20,
        ),
        onTap: () {
          if (isWide) {
            // Wide: Update selected channel, show in right panel
            setState(() {
              _selectedChannel = channel;
            });
          } else {
            // Mobile: Navigate to full-screen
            if (level == 'VILLAGE') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel)),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UnitTopicSelectionScreen(generalChannel: channel)),
              );
            }
          }
        },
      ),
    );
  }

  /// Welcome panel shown when no channel is selected
  Widget _buildWelcomePanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: ImboniColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined, size: 64, color: ImboniColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Hitamo Urwego',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a unit from the left to view discussions',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Content panel showing chat or topic selection
  Widget _buildContentPanel(BuildContext context) {
    if (_selectedChannel == null) return _buildWelcomePanel(context);

    final level = _selectedChannel!.unit?.level ?? 'UNIT';
    final hasCategory = _selectedChannel!.category != null;

    // If it's a topic channel (has category) OR a village, show the chat
    if (hasCategory || level == 'VILLAGE') {
      return ChannelChatScreen(
        channel: _selectedChannel!,
        embedded: true,
        onBack: hasCategory && _parentChannel != null
            ? () {
                // Navigate back to parent's topic selection
                setState(() {
                  _selectedChannel = _parentChannel;
                  _parentChannel = null;
                });
              }
            : null,
      );
    } else {
      // Show topic selection for higher-level units
      return UnitTopicSelectionScreen(
        generalChannel: _selectedChannel!,
        embedded: true,
        onChannelSelected: (channel) {
          setState(() {
            _parentChannel = _selectedChannel; // Save current as parent
            _selectedChannel = channel;
          });
        },
      );
    }
  }
}

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Birasohorera Vuba',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse channels by interest coming soon',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
