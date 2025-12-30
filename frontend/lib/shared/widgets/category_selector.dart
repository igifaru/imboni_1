import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Category Selector Widget
class CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySelector({super.key, this.selectedCategory, required this.onCategorySelected});

  static const List<_CategoryItem> categories = [
    _CategoryItem('JUSTICE', 'Ubutabera', Icons.gavel, ImboniColors.categoryJustice),
    _CategoryItem('HEALTH', 'Ubuzima', Icons.local_hospital, ImboniColors.categoryHealth),
    _CategoryItem('LAND', 'Ubutaka', Icons.landscape, ImboniColors.categoryLand),
    _CategoryItem('INFRASTRUCTURE', 'Ibikorwa remezo', Icons.construction, ImboniColors.categoryInfrastructure),
    _CategoryItem('SECURITY', 'Umutekano', Icons.security, ImboniColors.categorySecurity),
    _CategoryItem('SOCIAL', 'Imibereho', Icons.people, ImboniColors.categorySocial),
    _CategoryItem('EDUCATION', 'Uburezi', Icons.school, ImboniColors.categoryEducation),
    _CategoryItem('OTHER', 'Ibindi', Icons.help_outline, ImboniColors.categoryOther),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140, // Limits card width, adding more columns on desktop
        childAspectRatio: 1.25, // Rectangular compact shape
        crossAxisSpacing: 12, 
        mainAxisSpacing: 12
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = selectedCategory == cat.id;
        return _CategoryTile(category: cat, isSelected: isSelected, onTap: () => onCategorySelected(cat.id));
      },
    );
  }
}

class _CategoryItem {
  final String id, label;
  final IconData icon;
  final Color color;
  const _CategoryItem(this.id, this.label, this.icon, this.color);
}

class _CategoryTile extends StatelessWidget {
  final _CategoryItem category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected 
                ? category.color.withOpacity(0.15) 
                : (isDark ? const Color(0xFF1E2330) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? category.color 
                  : theme.dividerColor.withOpacity(0.1), 
              width: isSelected ? 2 : 1
            ),
            boxShadow: isSelected 
                ? [BoxShadow(color: category.color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? category.color.withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, size: 24, color: category.color),
              ),
              const SizedBox(height: 12),
              Text(
                category.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? category.color : theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.check_circle, size: 14, color: category.color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
