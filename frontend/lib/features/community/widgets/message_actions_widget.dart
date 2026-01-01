import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imboni/shared/theme/colors.dart';
import '../models/community_models.dart';
import 'professional_emoji_picker.dart';

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
    final RelativeRect menuPosition = _calculateMenuPosition(position);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    showMenu<dynamic>( 
      context: context,
      position: menuPosition,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      surfaceTintColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        // Professional Reaction Bar
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHigh : Colors.grey[50],
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isDark ? colorScheme.outline.withValues(alpha: 0.2) : Colors.grey[200]!
              ),
            ),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 _buildDesktopEmojiBtn('👍'),
                 _buildDesktopEmojiBtn('❤️'),
                 _buildDesktopEmojiBtn('😂'),
                 _buildDesktopEmojiBtn('😮'),
                 _buildDesktopEmojiBtn('😢'),
                 _buildDesktopEmojiBtn('😡'),
                 // Add Button for Full Picker
                 InkWell(
                   onTap: () {
                     Navigator.pop(context); // Close menu
                     _showFullEmojiPicker(); 
                   },
                   borderRadius: BorderRadius.circular(20),
                   child: Container(
                     padding: const EdgeInsets.all(6),
                     decoration: BoxDecoration(
                       color: isDark ? Colors.grey[800] : Colors.grey[200],
                       shape: BoxShape.circle,
                     ),
                     child: Icon(Icons.add, size: 18, color: isDark ? Colors.white : Colors.black),
                   ),
                 ),
               ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        _buildPopupMenuItem(Icons.content_copy, 'Copy', MessageAction.copy),
        _buildPopupMenuItem(Icons.reply, 'Reply', MessageAction.reply),
        _buildPopupMenuItem(Icons.push_pin_outlined, 'Pin', MessageAction.pin),
        _buildPopupMenuItem(Icons.info_outline, 'Info', MessageAction.info),
      ],
    ).then((value) {
      if (value != null && value is MessageAction) {
        widget.onAction(value);
      }
      setState(() => _isHovering = false);
    });
  }
  
  void _showFullEmojiPicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ProfessionalEmojiPicker(
          onEmojiSelected: (emoji) {
            Navigator.pop(context);
            widget.onReact(emoji);
          },
        ),
      ),
    );
  }
  
  RelativeRect _calculateMenuPosition(Offset? position) {
      if (position != null) {
        return RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1);
      }
      
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);

      // Width of the menu is approximately 340px (icons + padding + add button)
      const menuWidth = 340.0;
      
      final dx = widget.isOwnMessage 
          ? offset.dx - menuWidth - 8 
          : offset.dx + size.width + 8;
          
      final dy = offset.dy; 

      return RelativeRect.fromLTRB(
        dx,
        dy,
        dx + menuWidth,
        dy + 240, 
      );
  }

  // ... existing code ...

  Widget _buildDesktopEmojiBtn(String emoji) {
    return HoverableEmoji(
      emoji: emoji, 
      onTap: () {
        Navigator.pop(context);
        widget.onReact(emoji);
      }
    );
  }

  PopupMenuItem<MessageAction> _buildPopupMenuItem(IconData icon, String label, MessageAction action) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuItem<MessageAction>(
      value: action,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.7)),
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

// Helper widget for hover effect on emojis (Yellow Faces)
class HoverableEmoji extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const HoverableEmoji({super.key, required this.emoji, required this.onTap});

  @override
  State<HoverableEmoji> createState() => _HoverableEmojiState();
}

class _HoverableEmojiState extends State<HoverableEmoji> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          transform: _isHovering 
            ? Matrix4.diagonal3Values(1.3, 1.3, 1.0) 
            : Matrix4.identity(),
          child: Text(
            widget.emoji, 
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).colorScheme.onSurface, // Enforce solid color to prevent "cloudy" look
              fontFamilyFallback: const ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji', 'EmojiOne Color'],
            )
          ),
        ),
      ),
    );
  }
}
