import 'package:flutter/material.dart';
import 'message_actions_widget.dart'; // For MessageAction enum
import 'professional_emoji_picker.dart';

class DesktopMessageMenu {
  static void show({
    required BuildContext context,
    required Offset? position,
    required bool isOwnMessage,
    required Function(MessageAction) onAction,
    required Function(String) onReact,
    required VoidCallback onDismiss,
  }) {
    final RelativeRect menuPosition = _calculateMenuPosition(context, position, isOwnMessage);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    showMenu<dynamic>( 
      context: context,
      position: menuPosition,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
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
                 _buildDesktopEmojiBtn(context, '👍', onReact),
                 _buildDesktopEmojiBtn(context, '❤️', onReact),
                 _buildDesktopEmojiBtn(context, '😂', onReact),
                 _buildDesktopEmojiBtn(context, '😮', onReact),
                 _buildDesktopEmojiBtn(context, '😢', onReact),
                 _buildDesktopEmojiBtn(context, '😡', onReact),
                 // Add Button for Full Picker
                 InkWell(
                   onTap: () {
                     Navigator.pop(context); // Close menu
                     _showFullEmojiPicker(context, onReact); 
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
        _buildPopupMenuItem(context, Icons.content_copy, 'Copy', MessageAction.copy),
        _buildPopupMenuItem(context, Icons.reply, 'Reply', MessageAction.reply),
        _buildPopupMenuItem(context, Icons.push_pin_outlined, 'Pin', MessageAction.pin),
        _buildPopupMenuItem(context, Icons.info_outline, 'Info', MessageAction.info),
      ],
    ).then((value) {
      if (value != null && value is MessageAction) {
        onAction(value);
      }
      onDismiss();
    });
  }

  static RelativeRect _calculateMenuPosition(BuildContext context, Offset? position, bool isOwnMessage) {
      if (position != null) {
        return RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1);
      }
      
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);

      // Width of the menu is approximately 340px (icons + padding + add button)
      const menuWidth = 340.0;
      
      final dx = isOwnMessage 
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

  static Widget _buildDesktopEmojiBtn(BuildContext context, String emoji, Function(String) onReact) {
    return HoverableEmoji(
      emoji: emoji, 
      onTap: () {
        Navigator.pop(context);
        onReact(emoji);
      }
    );
  }

  static PopupMenuItem<MessageAction> _buildPopupMenuItem(BuildContext context, IconData icon, String label, MessageAction action) {
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

  static void _showFullEmojiPicker(BuildContext context, Function(String) onReact) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ProfessionalEmojiPicker(
          onEmojiSelected: (emoji) {
            Navigator.pop(context);
            onReact(emoji);
          },
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
