import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:imboni/shared/theme/colors.dart';
import '../../../shared/localization/app_localizations.dart';
import '../providers/community_provider.dart';
import '../models/community_models.dart';
import '../utils/community_utils.dart';
import '../widgets/message_actions_widget.dart';
import '../widgets/reaction_details_dialog.dart';
import '../widgets/attachments/message_attachment_list.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChannelMessage message;
  final String channelId;
  final Function(MessageAction) onAction;
  final Function(String) onReplyTap;
  
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.channelId,
    required this.onAction,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get current user ID
    final currentUserId = context.read<CommunityProvider>().getCurrentUserId();
    final isOwnMessage = message.authorId == currentUserId;
    final isOfficial = message.isOfficial;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for others' messages (left side)
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isOfficial 
                  ? ImboniColors.primary 
                  : getAvatarColor(message.author?.name ?? 'U'),
              child: message.author?.profilePicture != null 
                  ? null 
                  : Text(
                      message.author?.initials ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble wrapped in Actions Widget
          Flexible(
            child: MessageActionsWidget(
              message: message,
              isOwnMessage: isOwnMessage,
              onAction: onAction,
              onReact: (emoji) => context.read<CommunityProvider>()
                  .toggleReaction(channelId, message.id, emoji),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: isOwnMessage 
                      ? CrossAxisAlignment.end 
                      : CrossAxisAlignment.start,
                  children: [
                    // Author name for group messages (only for others)
                    if (!isOwnMessage)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.author?.displayName ?? AppLocalizations.of(context).unknown,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isOfficial 
                                    ? ImboniColors.primary 
                                    : getAvatarColor(message.author?.name ?? 'U'),
                              ),
                            ),
                            if (isOfficial) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 12, color: ImboniColors.primary),
                            ],
                          ],
                        ),
                      ),

                    // Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isOwnMessage 
                            ? ImboniColors.primary
                            : colorScheme.brightness == Brightness.dark
                                ? colorScheme.surfaceContainerHigh
                                : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
                          bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: isOfficial && !isOwnMessage
                            ? Border.all(color: ImboniColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Shrink to children vertically
                          children: [
                              // Reply Preview Section
                              if (message.replyTo != null)
                                GestureDetector(
                                  onTap: () => onReplyTap(message.replyTo!.id),
                                  child: Container(
                                    // Removed width: double.infinity
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(
                                        left: BorderSide(
                                          color: getAvatarColor(message.replyTo!.authorName), 
                                          width: 4.5
                                        ), 
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.replyTo!.authorName, 
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: getAvatarColor(message.replyTo!.authorName),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          message.replyTo!.content,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isOwnMessage 
                                                ? Colors.white.withValues(alpha: 0.9) 
                                                : colorScheme.onSurface.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                            // Pinned Indicator
                            if (message.isPinned)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.push_pin, size: 12, color: isOwnMessage ? Colors.white70 : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(AppLocalizations.of(context).pinned, style: TextStyle(fontSize: 10, color: isOwnMessage ? Colors.white70 : Colors.grey, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),

                            _buildRichMessage(context, message.content, isOwnMessage),
                            
                            if (message.attachments.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: MessageAttachmentList(
                                  attachments: message.attachments,
                                  isOwnMessage: isOwnMessage,
                                  channelId: channelId,
                                  messageId: message.id,
                                  currentUserId: currentUserId ?? 'unknown',
                                  currentUserName: context.read<CommunityProvider>().getCurrentUserName() ?? AppLocalizations.of(context).user,
                                ),
                              ),

                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(message.createdAt),
                                  style: TextStyle(
                                    color: isOwnMessage 
                                        ? Colors.white.withValues(alpha: 0.7) 
                                        : Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                ),
                                if (isOwnMessage) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                    ),
                    
                    // Reactions Display
                    if (message.reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: () {
                            // Group reactions by emoji
                            final Map<String, int> counts = {};
                            final Set<String> myReactions = {};
                            
                            for (var r in message.reactions) {
                              counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
                              if (r.userId == currentUserId) {
                                myReactions.add(r.emoji);
                              }
                            }
                            
                            return counts.entries.map((entry) {
                              final emoji = entry.key;
                              final count = entry.value;
                              final isMe = myReactions.contains(emoji);
                              
                              return GestureDetector(
                                onTapDown: (details) => _showReactionDetails(
                                  context, 
                                  details.globalPosition, 
                                  message
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isMe 
                                        ? ImboniColors.primary.withValues(alpha: 0.2) 
                                        : Colors.grey[200],
                                    border: isMe 
                                        ? Border.all(color: ImboniColors.primary.withValues(alpha: 0.5)) 
                                        : Border.all(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        emoji, 
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamilyFallback: ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji', 'EmojiOne Color'],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        count.toString(), 
                                        style: TextStyle(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold,
                                          color: isMe ? ImboniColors.primary : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList();
                          }(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Spacing for own messages (no avatar on right)
          if (isOwnMessage)
            const SizedBox(width: 4),
        ],
      ),
    );
  }

  // Render message with clickable mentions
  Widget _buildRichMessage(BuildContext context, String content, bool isOwnMessage) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseStyle = TextStyle(
      fontSize: 15,
      color: isOwnMessage ? Colors.white : colorScheme.onSurface,
      height: 1.4,
    );
    final mentionStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: isOwnMessage ? Colors.white : ImboniColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: isOwnMessage ? Colors.white : ImboniColors.primary,
    );

    final List<InlineSpan> spans = [];
    final RegExp mentionRegex = RegExp(r'@(\w+(?: \w+)?)'); // Matches @Name or @Name Name

    int start = 0;
    for (final match in mentionRegex.allMatches(content)) {
      if (match.start > start) {
        spans.add(TextSpan(text: content.substring(start, match.start), style: baseStyle));
      }
      
      final mentionText = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () async {
               final name = mentionText.replaceAll('@', '').trim();
               final user = await context.read<CommunityProvider>().findMemberByName(channelId, name);
               
               if (context.mounted) {
                   if (user != null) {
                       showDialog(context: context, builder: (context) => AlertDialog(
                           title: Row(children: [
                               CircleAvatar(
                                 backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
                                 child: user.profilePicture == null ? Text(user.initials) : null,
                               ),
                               const SizedBox(width: 12),
                               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                   Text(user.displayName, style: Theme.of(context).textTheme.titleMedium),
                                   Text(user.role.toString().split('.').last, style: Theme.of(context).textTheme.bodySmall)
                               ])
                           ]),
                           content: Column(
                               mainAxisSize: MainAxisSize.min,
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                   if (user.email != null) ListTile(
                                       leading: const Icon(Icons.email, size: 20),
                                       title: Text(user.email!, style: const TextStyle(fontSize: 14)),
                                       contentPadding: EdgeInsets.zero,
                                       dense: true,
                                   ),
                               ],
                           ),
                           actions: [
                               TextButton(
                                   onPressed: () => Navigator.pop(context),
                                   child: Text(AppLocalizations.of(context).close),
                               )
                           ],
                       ));
                   } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('User "$name" not found')),
                       );
                   }
               }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isOwnMessage 
                    ? Colors.white.withValues(alpha: 0.2) 
                    : ImboniColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(mentionText, style: mentionStyle),
            ),
          ),
        ),
      );
      
      start = match.end;
    }

    if (start < content.length) {
      spans.add(TextSpan(text: content.substring(start), style: baseStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }



  void _showReactionDetails(BuildContext context, Offset tapPosition, ChannelMessage message) {
    final screenSize = MediaQuery.of(context).size;
    const dialogWidth = 360.0;
    const dialogHeight = 400.0; // Approximate

    // Calculate Left position (centered horizontally on tap, clamped to screen edges)
    double left = tapPosition.dx - (dialogWidth / 2);
    if (left < 10) left = 10;
    if (left + dialogWidth > screenSize.width - 10) left = screenSize.width - dialogWidth - 10;

    // Calculate Top position (below the tap)
    double top = tapPosition.dy + 20;
    if (top + 200 > screenSize.height) {
       top = tapPosition.dy - dialogHeight - 10; // Show above if really tight
    }

    final currentUserId = context.read<CommunityProvider>().getCurrentUserId();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              top: top,
              left: left,
              child: Material(
                color: Colors.transparent,
                child: ReactionDetailsDialog(
                  message: message,
                  channelId: channelId,
                  currentUserId: currentUserId ?? '',
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            alignment: Alignment (
                ((tapPosition.dx / screenSize.width) * 2) - 1, // Align scale origin to tap X
                -1.0 // Top
            ),
            child: child,
          ),
        );
      },
    );
  }
}
