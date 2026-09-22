import 'package:flutter/material.dart';

import '../api/models.dart';
import '../format.dart';

class MealTile extends StatelessWidget {
  const MealTile({super.key, required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(meal.label, style: theme.textTheme.titleMedium),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatSugar(meal.sugarG),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(formatKcal(meal.kcal), style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
