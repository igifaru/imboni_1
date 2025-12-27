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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 12, mainAxisSpacing: 12),
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
    return Material(
      color: isSelected ? category.color.withOpacity(0.15) : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? category.color : Colors.transparent, width: 2)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: category.color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(category.icon, size: 20, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(category.label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? category.color : null), maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (isSelected) Icon(Icons.check_circle, size: 20, color: category.color),
          ]),
        ),
      ),
    );
  }
}
