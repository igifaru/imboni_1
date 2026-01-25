import 'package:flutter/material.dart';

import 'package:imboni/features/community/data/emoji_data.dart';
import '../../../shared/localization/app_localizations.dart';

class ProfessionalEmojiPicker extends StatefulWidget {
  final Function(String) onEmojiSelected;

  const ProfessionalEmojiPicker({super.key, required this.onEmojiSelected});

  @override
  State<ProfessionalEmojiPicker> createState() => _ProfessionalEmojiPickerState();
}

class _ProfessionalEmojiPickerState extends State<ProfessionalEmojiPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, List<String>> _filteredCategories = {};

  @override
  void initState() {
    super.initState();
    _filteredCategories = Map.from(EmojiData.categories);
    _tabController = TabController(length: EmojiData.categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmojis(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCategories = Map.from(EmojiData.categories);
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final Map<String, List<String>> temp = {};

    EmojiData.categories.forEach((category, emojis) {
       final List<String> matches = [];
       for (final emoji in emojis) {
         // Check if emoji itself matches (rare) or if keywords match
         final keywords = EmojiData.keywords[emoji] ?? '';
         if (keywords.contains(lowerQuery) || emoji == query) {
           matches.add(emoji);
         }
       }
       
       if (matches.isNotEmpty) {
         temp[category] = matches;
       }
    });

    setState(() {
      _filteredCategories = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final categories = EmojiData.categories.keys.toList();

    return Container(
      width: 350,
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar (Visual only for now until we have emoji dictionary)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchEmoji,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              onChanged: _filterEmojis,
            ),
          ),
          
          // Category Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.zero,
            indicatorColor: isDark ? Colors.white : theme.primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: const [
              Tab(icon: Icon(Icons.access_time, size: 20)), // Recent
              Tab(icon: Icon(Icons.emoji_emotions_outlined, size: 20)), // Smileys
              Tab(icon: Icon(Icons.pets, size: 20)), // Nature
              Tab(icon: Icon(Icons.fastfood, size: 20)), // Food
              Tab(icon: Icon(Icons.sports_soccer, size: 20)), // Activities
              Tab(icon: Icon(Icons.lightbulb_outline, size: 20)), // Objects
            ],
          ),
          
          const Divider(height: 1, thickness: 0.5),

          // Emoji Grid
          Expanded(
             child: TabBarView(
               controller: _tabController,
               children: categories.map((category) {
                 final emojis = _filteredCategories[category] ?? [];
                 
                 if (emojis.isEmpty) {
                   return Center(child: Text(AppLocalizations.of(context).noEmojisFound, style: TextStyle(color: Colors.grey)));
                 }

                 return GridView.builder(
                   padding: const EdgeInsets.all(8),
                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                     crossAxisCount: 8,
                     crossAxisSpacing: 4,
                     mainAxisSpacing: 4,
                   ),
                   itemCount: emojis.length,
                   itemBuilder: (context, index) {
                     final emoji = emojis[index];
                     return InkWell(
                       onTap: () => widget.onEmojiSelected(emoji),
                       borderRadius: BorderRadius.circular(4),
                       hoverColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                       child: Center(
                         child: Text(
                           emoji,
                           style: const TextStyle(
                             fontSize: 24,
                             fontFamilyFallback: ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji', 'EmojiOne Color'],
                           ), 
                         ),
                       ),
                     );
                   },
                 );
               }).toList(),
             ),
          ),
        ],
      ),
    );
  }
}
