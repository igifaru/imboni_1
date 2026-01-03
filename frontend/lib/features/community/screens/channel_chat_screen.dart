import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'package:imboni/shared/models/models.dart';
import '../providers/community_provider.dart';
import '../models/community_models.dart';
import '../widgets/message_actions_widget.dart';
import '../widgets/reaction_details_dialog.dart';
import 'package:intl/intl.dart';

class ChannelChatScreen extends StatefulWidget {
  final CommunityChannel channel;
  final bool embedded;
  final VoidCallback? onBack;

  const ChannelChatScreen({
    super.key,
    required this.channel,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _mentionOverlay;
  String? _mentionQuery;
  ChannelMessage? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchMessages(widget.channel.id);
    });
  }

  @override
  void dispose() {
    _hideMentionOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (selection.baseOffset < 0) return;

    // specific logic to find @mention
    // We look for the last @ before the cursor
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final mentionIndex = textBeforeCursor.lastIndexOf('@');

    if (mentionIndex != -1) {
      // Check if it's a valid start of mention (start of line or preceded by space)
      bool isValidStart = mentionIndex == 0 || textBeforeCursor[mentionIndex - 1] == ' ';
      
      if (isValidStart) {
        final query = textBeforeCursor.substring(mentionIndex + 1);
        // Trigger if query is empty (just @) or contains no spaces yet
        if (query.isEmpty || !query.contains(' ')) {
          _showMentionOverlay(query);
          return;
        }
      }
    }
    
    _hideMentionOverlay();
  }

  void _showMentionOverlay(String query) {
    _mentionQuery = query;
    // Trigger async search
    context.read<CommunityProvider>().searchMembers(widget.channel.id, query);
    
    if (_mentionOverlay == null) {
      _mentionOverlay = _buildMentionOverlayEntry();
      Overlay.of(context).insert(_mentionOverlay!);
    } else {
      _mentionOverlay!.markNeedsBuild();
    }
  }

  void _hideMentionOverlay() {
    _mentionOverlay?.remove();
    _mentionOverlay = null;
    _mentionQuery = null;
  }

  OverlayEntry _buildMentionOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 300, 
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -8), // Small gap above input
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainer, // Theme-aware color
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Consumer<CommunityProvider>(
                  builder: (context, provider, child) {
                   final members = provider.memberSearchResults;
                   
                   if (provider.isSearchingMembers) {
                     return const Padding(
                       padding: EdgeInsets.all(16.0),
                       child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                     );
                   }

                   if (members.isEmpty) {
                      if ((_mentionQuery ?? '').length < 2) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No members found',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      );
                   }
                   
                   return ListView.builder(
                     padding: EdgeInsets.zero,
                     shrinkWrap: true,
                     itemCount: members.length,
                     itemBuilder: (context, index) {
                       final member = members[index];
                       return ListTile(
                         leading: CircleAvatar(
                           radius: 14,
                           backgroundColor: _getAvatarColor(member.name ?? 'U'),
                           backgroundImage: member.profilePicture != null 
                              ? NetworkImage(member.profilePicture!) 
                              : null,
                           child: member.profilePicture == null 
                              ? Text(member.initials ?? 'U', style: const TextStyle(fontSize: 10, color: Colors.white))
                              : null,
                         ),
                         title: Text(
                             member.displayName ?? member.name ?? 'Unknown',
                             style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                         ),
                         onTap: () => _insertMention(member),
                         hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                       );
                     },
                   );
                  }
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _insertMention(UserModel user) {
    if (_mentionQuery == null) return;
    
    final text = _controller.text;
    final selection = _controller.selection;
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final mentionIndex = textBeforeCursor.lastIndexOf('@');
    
    if (mentionIndex != -1) {
      final newText = text.replaceRange(
        mentionIndex, 
        selection.baseOffset, 
        '@${user.displayName ?? user.name} '
      );
      
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: mentionIndex + (user.displayName ?? user.name ?? '').length + 2),
      );
    }
    _hideMentionOverlay();
  }

  void _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final success = await context.read<CommunityProvider>().sendMessage(
      widget.channel.id, 
      content,
      replyToId: _replyingToMessage?.id,
    );
    
    setState(() {
      _replyingToMessage = null;
    });

    if (success) {
      _controller.clear();
      // Scroll to bottom to show newest message
      if (_scrollController.hasClients) {
        // Use a small delay to ensure the new message is rendered
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  /// Build breadcrumb: Unit > Category (clickable to go back)
  Widget _buildBreadcrumb(ThemeData theme) {
    final unitName = widget.channel.unit?.name ?? 'Unit';
    final category = widget.channel.category;
    
    // Map category to Kinyarwanda
    String categoryLabel = category ?? '';
    switch (category) {
      case 'HEALTH': categoryLabel = 'Ubuzima'; break;
      case 'LAND': categoryLabel = 'Ubutaka'; break;
      case 'INFRASTRUCTURE': categoryLabel = 'Ibikorwaremezo'; break;
      case 'SECURITY': categoryLabel = 'Umutekano'; break;
      case 'JUSTICE': categoryLabel = 'Ubutabera'; break;
      case 'SOCIAL': categoryLabel = 'Imibereho'; break;
      case 'EDUCATION': categoryLabel = 'Uburezi'; break;
      case 'OTHER': categoryLabel = 'Ibindi'; break;
    }

    if (category == null) {
      // No category, just show the channel name
      return Text(
        widget.channel.name,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      );
    }

    return Row(
      children: [
        // Clickable unit name to go back to topics
        if (widget.onBack != null)
          InkWell(
            onTap: widget.onBack,
            child: Text(
              unitName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ImboniColors.primary,
              ),
            ),
          )
        else
          Text(
            unitName,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          categoryLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final body = Column(
      children: [
        // Header for embedded mode with breadcrumb navigation
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
                const Icon(Icons.forum, color: ImboniColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb: Unit > Category
                      _buildBreadcrumb(theme),
                      Text(
                        '${widget.channel.memberCount} abanyamuryango',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Consumer<CommunityProvider>(
            builder: (context, provider, child) {
              final messages = provider.getMessages(widget.channel.id);
              final isLoading = provider.isLoadingMessages(widget.channel.id);

              if (isLoading && messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Nta butumwa burahari',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to start a conversation',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              // Use a reversed list to show newest messages at bottom like chat apps
              // But wrap in Align to start from top when few messages
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: false, // Start from top
                      itemCount: messages.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      itemBuilder: (context, index) {
                        // Messages are already sorted newest first from API, 
                        // so reverse the index to show oldest first (top)
                        final message = messages[messages.length - 1 - index];
                        return _buildMessageBubble(context, message);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _buildInputArea(),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.channel.name, style: const TextStyle(fontSize: 16)),
            Text(
              '${widget.channel.memberCount} members',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${_replyingToMessage!.author?.name ?? 'Unknown'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _replyingToMessage!.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _replyingToMessage = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline), 
                    onPressed: () {}, // Attachments
                    color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey,
                  ),
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark ? colorScheme.surfaceContainerHigh : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: ImboniColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Helper handling methods for message actions
  void _handleMessageAction(MessageAction action, ChannelMessage message) {

     
    switch (action) {
      case MessageAction.copy:
        Clipboard.setData(ClipboardData(text: message.content));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message copied to clipboard')),
        );
        break;
      case MessageAction.reply:
        setState(() {
          _replyingToMessage = message;
        });
        _focusNode.requestFocus();
        break;
      case MessageAction.pin:
        context.read<CommunityProvider>().togglePin(widget.channel.id, message.id);
        break;
      // Other cases...
      default:
        break;
    }
  }


  // Scroll to a specific message
  void _scrollToMessage(String messageId) {
    final messages = context.read<CommunityProvider>().getMessages(widget.channel.id);
    final index = messages.indexWhere((m) => m.id == messageId);
    
    if (index != -1) {
      // Calculate render index (reversed logic matches ListView builder)
      final renderIndex = messages.length - 1 - index;
      
      // Estimate position (assuming ~70px per message on average)
      // This is a heuristic since we don't have exact heights
      final double offset = renderIndex * 70.0; 
      
      // Clamp to extents
      final double target = offset.clamp(
          _scrollController.position.minScrollExtent, 
          _scrollController.position.maxScrollExtent
      );

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message not found (might be older)')),
      );
    }
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
               final user = await context.read<CommunityProvider>().findMemberByName(widget.channel.id, name);
               
               if (context.mounted) {
                   if (user != null) {
                       showDialog(context: context, builder: (context) => AlertDialog(
                           title: Row(children: [
                               CircleAvatar(
                                 backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
                                 child: user.profilePicture == null ? Text(user.initials ?? 'U') : null,
                               ),
                               const SizedBox(width: 12),
                               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                   Text(user.displayName ?? user.name ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium),
                                   Text(user.role?.toString().split('.').last ?? 'Member', style: Theme.of(context).textTheme.bodySmall)
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
                                   child: const Text('Close'),
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

  Widget _buildMessageBubble(BuildContext context, ChannelMessage message) {
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
                  : _getAvatarColor(message.author?.name ?? 'U'),
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
              onAction: (action) => _handleMessageAction(action, message),
              onReact: (emoji) => context.read<CommunityProvider>()
                  .toggleReaction(widget.channel.id, message.id, emoji),
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
                              message.author?.displayName ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isOfficial 
                                    ? ImboniColors.primary 
                                    : _getAvatarColor(message.author?.name ?? 'U'),
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
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              // Reply Preview Section
                              if (message.replyTo != null)
                                GestureDetector(
                                  onTap: () => _scrollToMessage(message.replyTo!.id),
                                  child: Container(
                                    // Removed width: double.infinity
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(
                                        left: BorderSide(
                                          color: _getAvatarColor(message.replyTo!.authorName), 
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
                                            color: _getAvatarColor(message.replyTo!.authorName),
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
                                      Text('Pinned', style: TextStyle(fontSize: 10, color: isOwnMessage ? Colors.white70 : Colors.grey, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),

                            _buildRichMessage(context, message.content, isOwnMessage),
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

  /// Generate a consistent color based on the user's name
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber[700]!,
      Colors.cyan,
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
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
    // If it goes off screen bottom, show above instead? 
    // For now, user asked for "under", so we prioritize that unless it's completely unusable.
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
                  channelId: widget.channel.id,
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
