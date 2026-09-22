import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/tokens.dart';

class SugarRing extends StatelessWidget {
  const SugarRing({
    super.key,
    required this.consumed,
    required this.limit,
    required this.remaining,
    required this.kcal,
  });

  final double consumed;
  final double limit;
  final double remaining;
  final double kcal;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final tone = toneFor(consumed: consumed, limit: limit);
    final color = palette.tone(tone);
    final progress = limit <= 0 ? (consumed > 0 ? 1.0 : 0.0) : (consumed / limit).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: 196,
          height: 196,
          child: Semantics(
            label:
                '${formatSugar(consumed)} of ${formatSugar(limit)} sugar, ${remainingLine(remaining)}, ${formatKcal(kcal)}',
            child: CustomPaint(
              key: const Key('sugar-ring'),
              painter: _RingPainter(progress: progress, color: color, track: palette.border),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatAmount(consumed),
                      key: const Key('sugar-consumed'),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${formatSugar(limit)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          remainingLine(remaining),
          key: const Key('sugar-remaining'),
          style: theme.textTheme.titleMedium?.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatKcal(kcal)} today',
          key: const Key('kcal-today'),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track});

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.track != track;
  }
}
