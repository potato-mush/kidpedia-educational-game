import 'package:flutter/material.dart';
import 'package:kidpedia/core/theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.getCategoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? categoryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: categoryColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 20,
              color: isSelected ? Colors.white : categoryColor,
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : categoryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'animals':
        return Icons.pets;
      case 'space':
        return Icons.rocket_launch;
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'geography':
        return Icons.public;
      default:
        return Icons.category;
    }
  }
}
