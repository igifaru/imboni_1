import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imboni/shared/models/models.dart';
import 'package:imboni/shared/theme/colors.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';

class ReactionDetailsDialog extends StatefulWidget {
  final ChannelMessage message;
  final String channelId;
  final String currentUserId;

  const ReactionDetailsDialog({
    super.key,
    required this.message,
    required this.channelId,
    required this.currentUserId,
  });

  @override
  State<ReactionDetailsDialog> createState() => _ReactionDetailsDialogState();
}

class _ReactionDetailsDialogState extends State<ReactionDetailsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, List<MessageReaction>> _groupedReactions;
  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    _processReactions();
  }

  void _processReactions() {
    _groupedReactions = {};
    
    // Group "All"
    _groupedReactions['All'] = widget.message.reactions;

    // Group by Emoji
    for (var r in widget.message.reactions) {
      if (!_groupedReactions.containsKey(r.emoji)) {
        _groupedReactions[r.emoji] = [];
      }
      _groupedReactions[r.emoji]!.add(r);
    }

    _tabs = _groupedReactions.keys.toList();
    
    // Sort tabs: All first, then by count descending
    _tabs.sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      return _groupedReactions[b]!.length.compareTo(_groupedReactions[a]!.length);
    });

    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // If no reactions, close (shouldn't happen but safe guard)
    if (widget.message.reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate Dynamic Height
    // Header ~ 60px, Item ~ 60px
    // We use the 'All' count to determine max needed height to avoid resizing on tab switch
    // Or we could use current tab if we listen to controller.
    final allCount = _groupedReactions['All']?.length ?? 0;
    
    // Max items to show before scrolling: 6
    final visibleItems = allCount > 6 ? 6 : allCount;
    // Min items: 1
    final calcItems = visibleItems < 1 ? 1 : visibleItems;
    
    const double itemHeight = 64.0;
    const double headerHeight = 60.0;
    const double paddingHeight = 20.0;
    
    final double contentHeight = (calcItems * itemHeight);
    final double totalHeight = headerHeight + contentHeight + paddingHeight;

    return Container(
      width: 360,
      height: totalHeight, // Dynamic height
      constraints: const BoxConstraints(maxHeight: 500, minHeight: 100),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
        borderRadius: BorderRadius.circular(16), // Fully rounded
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle/Drag Indicator (Optional, maybe remove for popover feel? User image didn't show it clearly, but kept it smaller)
           Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          
          // Tabs
          Container(
             height: 48,
             decoration: BoxDecoration(
               border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
             ),
             child: TabBar(
               controller: _tabController,
               isScrollable: true,
               indicatorColor: const Color(0xFF00C853), // WhatsApp-like Green or Custom
               indicatorWeight: 3,
               labelColor: isDark ? Colors.white : Colors.black,
               unselectedLabelColor: Colors.grey,
               dividerColor: Colors.transparent,
               tabAlignment: TabAlignment.start,
               padding: EdgeInsets.zero,
               labelPadding: const EdgeInsets.symmetric(horizontal: 16),
               tabs: _tabs.map((key) {
                 final count = _groupedReactions[key]!.length;
                 final label = key == 'All' ? 'All' : key; 
                 
                 return Tab(
                   child: Row(
                     children: [
                       Text(
                         label, 
                         style: TextStyle(
                           fontSize: key == 'All' ? 14 : 18,
                           fontWeight: key == 'All' ? FontWeight.bold : FontWeight.normal,
                           fontFamilyFallback: const ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji', 'EmojiOne Color'],
                         )
                       ),
                       const SizedBox(width: 6),
                       Text('$count', style: const TextStyle(fontSize: 12)),
                     ],
                   ),
                 );
               }).toList(),
             ),
          ),

          // Content
          Expanded( // Fill the remaining calculated height
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((key) {
                final reactions = _groupedReactions[key]!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: reactions.length,
                  itemBuilder: (context, index) {
                    final reaction = reactions[index];
                    final isMe = reaction.userId == widget.currentUserId;
                    final user = reaction.user;
                    
                    return InkWell(
                      onTap: isMe ? () {
                         context.read<CommunityProvider>()
                            .toggleReaction(widget.channelId, widget.message.id, reaction.emoji);
                         Navigator.pop(context);
                      } : null,
                      child: Container( // Wrapped in container for spacing
                        height: 60, // Fixed height for consistent calc
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: user?.profilePicture != null 
                                  ? NetworkImage(user!.profilePicture!) 
                                  : null,
                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: user?.profilePicture == null 
                                  ? Text(
                                      (user?.name ?? '?')[0].toUpperCase(),
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                    ) 
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Name & Subtitle
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMe ? 'You' : (user?.name ?? 'Unknown'),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isMe)
                                    Text(
                                      'Click to remove',
                                      style: TextStyle(
                                        fontSize: 11, 
                                        color: isDark ? Colors.grey[400] : Colors.grey[600]
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Emoji Icon
                            Text(
                              reaction.emoji, 
                              style: const TextStyle(
                                fontSize: 22, // Slightly smaller for professional look
                                fontFamilyFallback: ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji', 'EmojiOne Color'],
                              )
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
