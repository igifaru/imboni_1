import 'package:flutter/material.dart';
import '../models/community_models.dart';

/// Generate a consistent color based on the user's name
Color getAvatarColor(String? name) {
  if (name == null || name.isEmpty) return Colors.grey;
  
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

/// Group reactions by emoji, ensuring 'All' is first and others are sorted by count
Map<String, List<MessageReaction>> groupReactionsProcess(List<MessageReaction> reactions) {
  final Map<String, List<MessageReaction>> grouped = {};
  
  // Group "All"
  grouped['All'] = reactions;

  // Group by Emoji
  for (var r in reactions) {
    if (!grouped.containsKey(r.emoji)) {
      grouped[r.emoji] = [];
    }
    grouped[r.emoji]!.add(r);
  }
  return grouped;
}

List<String> getSortedReactionTabs(Map<String, List<MessageReaction>> grouped) {
  final tabs = grouped.keys.toList();
  // Sort tabs: All first, then by count descending
  tabs.sort((a, b) {
    if (a == 'All') return -1;
    if (b == 'All') return 1;
    return grouped[b]!.length.compareTo(grouped[a]!.length);
  });
  return tabs;
}
