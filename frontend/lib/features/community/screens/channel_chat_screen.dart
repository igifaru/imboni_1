import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:imboni/shared/theme/colors.dart';
import 'package:imboni/shared/models/models.dart';
import '../providers/community_provider.dart';
import '../models/community_models.dart';
import '../widgets/message_actions_widget.dart';
import '../widgets/chat_message_bubble.dart';
import '../utils/community_utils.dart';


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
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                           backgroundColor: getAvatarColor(member.name ?? 'U'),
                           backgroundImage: member.profilePicture != null 
                              ? NetworkImage(member.profilePicture!) 
                              : null,
                           child: member.profilePicture == null 
                              ? Text(member.initials, style: const TextStyle(fontSize: 10, color: Colors.white))
                              : null,
                         ),
                         title: Text(
                             member.displayName,
                             style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                         ),
                         onTap: () => _insertMention(member),
                         hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
        '@${user.displayName} '
      );
      
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: mentionIndex + user.displayName.length + 2),
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
                        return ChatMessageBubble(
                          key: ValueKey('${message.id}_${message.reactions.length}_${message.reactions.fold(0, (p, e) => p + e.emoji.hashCode)}'),
                          message: message,
                          channelId: widget.channel.id,
                          onAction: (action) => _handleMessageAction(action, message),
                          onReplyTap: (replyId) => _scrollToMessage(replyId),
                        );
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
                    color: isDark ? colorScheme.onSurface.withValues(alpha: 0.7) : Colors.grey,
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
      case MessageAction.edit:
        _showEditMessageDialog(message);
        break;
      case MessageAction.delete:
        _showDeleteMessageDialog(message);
        break;
      default:
        break;
    }
  }

  void _showEditMessageDialog(ChannelMessage message) {
    final editController = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth > 650 ? 600.0 : screenWidth * 0.9;
        
        return AlertDialog(
        title: const Text('Edit Message'),
        content: SizedBox(
          width: dialogWidth,
          child: TextField(
            controller: editController,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter message...',
            ),
            minLines: 5,
            maxLines: 5, // Fixed height to prevent jumping
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
               final newContent = editController.text.trim();
               if (newContent.isNotEmpty && newContent != message.content) {
                  context.read<CommunityProvider>().editMessage(widget.channel.id, message.id, newContent);
               }
               Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      );
     },
    );
  }

  void _showDeleteMessageDialog(ChannelMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
               context.read<CommunityProvider>().deleteMessage(widget.channel.id, message.id);
               Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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



}
