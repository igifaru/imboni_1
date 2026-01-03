import 'package:flutter/material.dart';
import '../models/community_models.dart';
import 'desktop_message_menu.dart';

enum MessageAction {
  copy,
  reply,
  pin,
  react,
  info,
  mention,
}

class MessageActionsWidget extends StatefulWidget {
  final Widget child;
  final ChannelMessage message;
  final bool isOwnMessage;
  final Function(MessageAction) onAction;
  final Function(String) onReact;

  const MessageActionsWidget({
    super.key,
    required this.child,
    required this.message,
    required this.isOwnMessage,
    required this.onAction,
    required this.onReact,
  });

  @override
  State<MessageActionsWidget> createState() => _MessageActionsWidgetState();
}

class _MessageActionsWidgetState extends State<MessageActionsWidget> {
  // ... existing state ...
  bool _isHovering = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && _overlayEntry == null) {
               setState(() => _isHovering = false);
            }
          });
        },
        child: GestureDetector(
          onLongPress: _showActionMenu,
          onSecondaryTapDown: (details) {
             if (!_isMobilePlatform()) _showDesktopMenu(position: details.globalPosition);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              if (_isHovering && !_isMobilePlatform())
                Positioned(
                  top: -8,
                  right: widget.isOwnMessage ? null : -8,
                  left: widget.isOwnMessage ? -8 : null,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHovering = true),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDesktopMenu(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isMobilePlatform() {
    return Theme.of(context).platform == TargetPlatform.android ||
           Theme.of(context).platform == TargetPlatform.iOS;
  }

  void _showActionMenu() {
    if (_isMobilePlatform()) {
      _showMobileActionSheet();
    } else {
      _showDesktopMenu();
    }
  }

  void _showMobileActionSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Emoji Quick Actions
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _buildEmojiOption('👍'),
                   _buildEmojiOption('❤️'),
                   _buildEmojiOption('😂'),
                   _buildEmojiOption('😮'),
                   _buildEmojiOption('😢'),
                   _buildEmojiOption('😡'),
                ],
              ),
            ),
            const Divider(),
            _buildActionItem(Icons.content_copy, 'Copy Text', MessageAction.copy, colorScheme.onSurface),
            _buildActionItem(Icons.reply, 'Reply', MessageAction.reply, colorScheme.onSurface),
            _buildActionItem(Icons.push_pin_outlined, 'Pin Message', MessageAction.pin, Colors.orange),
            _buildActionItem(Icons.info_outline, 'Info', MessageAction.info, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiOption(String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onReact(emoji);
      },
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }

  void _showDesktopMenu({Offset? position}) {
    DesktopMessageMenu.show(
      context: context,
      position: position,
      isOwnMessage: widget.isOwnMessage,
      onAction: widget.onAction,
      onReact: widget.onReact,
      onDismiss: () => setState(() => _isHovering = false),
    );
  }

  Widget _buildActionItem(IconData icon, String label, MessageAction action, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onAction(action);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
