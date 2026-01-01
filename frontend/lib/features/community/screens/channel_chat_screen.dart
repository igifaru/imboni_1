import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imboni/shared/theme/colors.dart';
import '../providers/community_provider.dart';
import '../models/community_models.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchMessages(widget.channel.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final success = await context.read<CommunityProvider>().sendMessage(
      widget.channel.id, 
      content
    );

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline), 
              onPressed: () {}, // Attachments
              color: Colors.grey,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                minLines: 1,
                maxLines: 4,
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
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChannelMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get current user ID from shared preferences or auth service
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

          // Message bubble
          Flexible(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            color: isOwnMessage ? Colors.white : colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                ],
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
}
