import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/localization/app_localizations.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../utils/community_utils.dart'; // Import utils

class ReactionDetailsDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        // Get live message to verify reactions
        final liveMessageList = provider.getMessages(channelId);
        final liveMessage = liveMessageList.firstWhere(
            (m) => m.id == message.id,
            orElse: () => message, // Fallback to initial if not found (e.g. deleted)
        );
        
        if (liveMessage.reactions.isEmpty) {
             return const SizedBox.shrink(); 
        }

        // Processing Logic (Re-run on every build/update)
        final groupedReactions = groupReactionsProcess(liveMessage.reactions);
        final tabs = getSortedReactionTabs(groupedReactions);

        // Calculate Dynamic Height
        final allCount = groupedReactions['All']?.length ?? 0;
        final visibleItems = allCount > 6 ? 6 : allCount;
        final calcItems = visibleItems < 1 ? 1 : visibleItems;
        
        const double itemHeight = 64.0;
        const double headerHeight = 60.0;
        const double paddingHeight = 20.0;
        
        final double contentHeight = (calcItems * itemHeight);
        final double totalHeight = headerHeight + contentHeight + paddingHeight;

        // Key based on visible tabs to force rebuild of controller when categories change/disappear
        final controllerKey = ValueKey(tabs.join(','));

        return Container(
          width: 360,
          height: totalHeight,
          constraints: const BoxConstraints(maxHeight: 500, minHeight: 150),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DefaultTabController(
            key: controllerKey, // Critical: Rebuild controller if tabs change
            length: tabs.length,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Tabs
                Container(
                   height: 48,
                   decoration: BoxDecoration(
                     border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                   ),
                   child: TabBar(
                     isScrollable: true,
                     indicatorColor: const Color(0xFF00C853),
                     indicatorWeight: 3,
                     labelColor: isDark ? Colors.white : Colors.black,
                     unselectedLabelColor: Colors.grey,
                     dividerColor: Colors.transparent,
                     tabAlignment: TabAlignment.start,
                     padding: EdgeInsets.zero,
                     labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                     tabs: tabs.map((key) {
                       final count = groupedReactions[key]!.length;
                       final label = key == 'All' ? AppLocalizations.of(context).all : key; 
                       
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
                Expanded(
                  child: TabBarView(
                    children: tabs.map((key) {
                      final reactions = groupedReactions[key]!;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: reactions.length,
                        itemBuilder: (context, index) {
                          final reaction = reactions[index];
                          final isMe = reaction.userId == currentUserId;
                          final user = reaction.user;
                          
                          return InkWell(
                            onTap: isMe ? () {
                               debugPrint('Removing reaction: ${reaction.emoji}');
                               provider.toggleReaction(channelId, message.id, reaction.emoji);
                            } : null,
                            child: Container(
                              height: 60,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: user?.profilePicture != null 
                                        ? NetworkImage(user!.profilePicture!) 
                                        : null,
                                    backgroundColor: getAvatarColor(user?.name), // Use shared util
                                    child: user?.profilePicture == null 
                                        ? Text(
                                            (user?.name ?? '?')[0].toUpperCase(),
                                            style: const TextStyle(color: Colors.white),
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
                                          isMe ? AppLocalizations.of(context).you : (user?.name ?? AppLocalizations.of(context).unknown),
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isMe)
                                          Row(
                                            children: [
                                               Text(
                                                AppLocalizations.of(context).clickToRemove,
                                                style: TextStyle(
                                                  fontSize: 11, 
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600]
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.close, size: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Emoji Icon
                                  Text(
                                    reaction.emoji, 
                                    style: const TextStyle(
                                      fontSize: 22,
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
          ),
        );
      }
    );
  }
}
