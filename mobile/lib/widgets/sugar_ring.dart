import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/tokens.dart';

/// Primary sugar-left card. The bar shows sugar remaining, never calories.
class SugarRing extends StatelessWidget {
  const SugarRing({
    super.key,
    required this.consumed,
    required this.limit,
    required this.remaining,
  });

  final double consumed;
  final double limit;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final theme = Theme.of(context);
    final tone = toneFor(consumed: consumed, limit: limit);
    final over = tone != BudgetTone.under;
    final ratio = over
        ? 1.0
        : limit <= 0
            ? 0.0
            : (remaining / limit).clamp(0.0, 1.0);
    final bar = over ? palette.tone(tone) : palette.lime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.water_drop_rounded, color: palette.under, size: 18),
            const SizedBox(width: 6),
            Text(
              'Sugar left',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Semantics(
          label:
              '${formatSugar(consumed)} of ${formatSugar(limit)} sugar, ${remainingLine(remaining)}',
          child: SizedBox(
            key: const Key('sugar-ring'),
            height: 18,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: ColoredBox(
                color: palette.dark ? palette.border : const Color(0xFFE7F3E4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    heightFactor: 1,
                    child: ColoredBox(color: bar),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                remainingLine(remaining),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: over ? palette.tone(tone) : palette.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatAmount(consumed),
                  key: const Key('sugar-consumed'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text('of ${formatSugar(limit)}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
