import 'dart:async';
import 'package:flutter/material.dart';

/// Countdown timer widget that displays remaining time until deadline
class CountdownTimer extends StatefulWidget {
  final DateTime deadline;
  final TextStyle? style;
  final bool showIcon;
  final VoidCallback? onExpired;

  const CountdownTimer({
    super.key,
    required this.deadline,
    this.style,
    this.showIcon = true,
    this.onExpired,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _hasExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _calculateRemaining();
    }
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    if (widget.deadline.isAfter(now)) {
      _remaining = widget.deadline.difference(now);
      _hasExpired = false;
    } else {
      _remaining = Duration.zero;
      _hasExpired = true;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _calculateRemaining();
        if (_hasExpired && widget.onExpired != null) {
          widget.onExpired!();
        }
      });
    });
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return 'Expired';

    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Color _getColor(BuildContext context) {
    if (_hasExpired) return Colors.red;

    // Critical: less than 1 hour
    if (_remaining.inHours < 1) return Colors.red;

    // Warning: less than 6 hours
    if (_remaining.inHours < 6) return Colors.orange;

    // Normal
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              _hasExpired ? Icons.warning : Icons.timer,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _formatDuration(_remaining),
            style: widget.style?.copyWith(color: color) ??
                TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

/// Compact version for use in cards
class CountdownChip extends StatelessWidget {
  final DateTime deadline;

  const CountdownChip({super.key, required this.deadline});

  @override
  Widget build(BuildContext context) {
    return CountdownTimer(
      deadline: deadline,
      showIcon: true,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}
