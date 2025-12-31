import 'package:flutter/material.dart';

class SelectionCard extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final int? count;
  final int? maxCount;
  final bool isDark;

  const SelectionCard({
    required this.label,
    required this.onTap,
    this.count,
    this.maxCount,
    this.isDark = false,
    super.key,
  });

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getHeatColor() {
    if (widget.count == null || widget.maxCount == null || widget.maxCount == 0) {
      return Colors.blue.shade600; // Default brand color
    }
    final ratio = widget.count! / widget.maxCount!;
    if (ratio < 0.33) return const Color(0xFF4CAF50); // Green
    if (ratio < 0.66) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  @override
  Widget build(BuildContext context) {
    final color = _getHeatColor();
    final baseColor = widget.count != null 
        ? color.withValues(alpha: widget.isDark ? 0.3 : 0.15) 
        : (widget.isDark ? Colors.grey.shade800 : Colors.white);
    
    final borderColor = widget.count != null ? color : Colors.transparent;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.95).animate(_controller),
        child: Card(
          elevation: 2,
          color: baseColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: widget.count == null ? LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.count == null ? Colors.white : (widget.isDark ? Colors.white : Colors.black87),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.count != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${widget.count}',
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cases',
                        style: TextStyle(
                          color: widget.isDark ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
