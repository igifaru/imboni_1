import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imboni/shared/theme/colors.dart';
import '../models/community_models.dart';

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

  const MessageActionsWidget({
    super.key,
    required this.child,
    required this.message,
    required this.isOwnMessage,
    required this.onAction,
  });

  @override
  State<MessageActionsWidget> createState() => _MessageActionsWidgetState();
}

class _MessageActionsWidgetState extends State<MessageActionsWidget> {
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
          // Add a small delay for smoother exit if moving to button
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
              // Only show hover button for mouse users
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
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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

  /// Show appropriate menu based on platform
  void _showActionMenu() {
    if (_isMobilePlatform()) {
      _showMobileActionSheet();
    } else {
      _showDesktopMenu();
    }
  }

  void _showMobileActionSheet() {
    showModalBottomSheet(
      // ... same implementation ...
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            _buildActionItem(Icons.content_copy, 'Copy Text', MessageAction.copy, Colors.black87),
            _buildActionItem(Icons.reply, 'Reply', MessageAction.reply, Colors.black87),
            _buildActionItem(Icons.add_reaction_outlined, 'React', MessageAction.react, Colors.blue),
            if (!widget.isOwnMessage)
              _buildActionItem(Icons.alternate_email, 'Mention', MessageAction.mention, Colors.purple),
            _buildActionItem(Icons.push_pin_outlined, 'Pin Message', MessageAction.pin, Colors.orange),
            _buildActionItem(Icons.info_outline, 'Info', MessageAction.info, Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showDesktopMenu({Offset? position}) {
    final RelativeRect menuPosition;

    if (position != null) {
      // Use cursor position
      menuPosition = RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      );
    } else {
      // Use calculated position relative to widget
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);

      menuPosition = RelativeRect.fromLTRB(
        widget.isOwnMessage ? offset.dx - 150 : offset.dx + size.width,
        offset.dy,
        widget.isOwnMessage ? offset.dx : offset.dx + size.width + 150,
        offset.dy + size.height,
      );
    }

    showMenu<MessageAction>(
      context: context,
      position: menuPosition,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        _buildPopupMenuItem(Icons.content_copy, 'Copy', MessageAction.copy),
        _buildPopupMenuItem(Icons.reply, 'Reply', MessageAction.reply),
        _buildPopupMenuItem(Icons.add_reaction_outlined, 'React', MessageAction.react),
        if (!widget.isOwnMessage)
          _buildPopupMenuItem(Icons.alternate_email, 'Mention', MessageAction.mention),
        _buildPopupMenuItem(Icons.push_pin_outlined, 'Pin', MessageAction.pin),
        _buildPopupMenuItem(Icons.info_outline, 'Info', MessageAction.info),
      ],
    ).then((value) {
      if (value != null) {
        widget.onAction(value);
      }
      setState(() => _isHovering = false);
    });
  }

  PopupMenuItem<MessageAction> _buildPopupMenuItem(IconData icon, String label, MessageAction action) {
    return PopupMenuItem<MessageAction>(
      value: action,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
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
                color: color.withOpacity(0.1),
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
