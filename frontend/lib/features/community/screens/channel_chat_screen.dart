import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imboni/shared/theme/colors.dart';
import '../providers/community_provider.dart';
import '../models/community_models.dart';
import 'package:intl/intl.dart';

class ChannelChatScreen extends StatefulWidget {
  final CommunityChannel channel;

  const ChannelChatScreen({super.key, required this.channel});

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
      // Scroll to bottom (actually top since list is reversed usually, but here I implemented prepend...)
      // Standard chat usually fills from bottom. 
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.channel.name, style: const TextStyle(fontSize: 16)),
            Text(
              '${widget.channel.memberCount} members', 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<CommunityProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessages(widget.channel.id);
                final isLoading = provider.isLoadingMessages(widget.channel.id);

                if (isLoading && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Reverse: true for chat feel
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, 
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    // Since it's reversed, index 0 is latest.
                    // But messages list is [Latest, ..., Oldest] if I prepend.
                    // So index 0 is indeed latest.
                    return _buildMessageBubble(context, message);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
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
    // Current user check (Normally from AuthProvider)
    // Assuming for now hardcoded check or we need current user ID in provider
    // Let's assume right-aligned for "Self" logic is pending.
    // For MVP, just left align all with author name.
    
    final isOfficial = message.isOfficial;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isOfficial ? ImboniColors.primary : Colors.grey[300],
            child: Text(
              message.author?.initials ?? 'U',
              style: TextStyle(
                color: isOfficial ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.author?.displayName ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isOfficial ? ImboniColors.primary : Colors.black87
                      ),
                    ),
                    if (isOfficial) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 14, color: ImboniColors.primary),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(message.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOfficial ? ImboniColors.primary.withValues(alpha: 0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: isOfficial ? Border.all(color: ImboniColors.primary.withValues(alpha: 0.2)) : null,
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
