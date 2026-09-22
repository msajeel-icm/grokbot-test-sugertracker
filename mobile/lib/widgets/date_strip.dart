import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Week strip around the dashboard date. It does not change the sugar budget.
class DateStrip extends StatelessWidget {
  const DateStrip({super.key, required this.isoDate});

  final String isoDate;

  static const _short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final selected = DateTime.parse(isoDate);
    final days = [
      for (var offset = -3; offset <= 3; offset++)
        selected.add(Duration(days: offset)),
    ];
    return SizedBox(
      height: 78,
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: _DayCell(
                label: _short[day.weekday - 1],
                day: day.day,
                selected: day.year == selected.year &&
                    day.month == selected.month &&
                    day.day == selected.day,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell(
      {required this.label, required this.day, required this.selected});

  final String label;
  final int day;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? palette.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: palette.dark
                      ? const Color(0x66000000)
                      : const Color(0x14000000),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? palette.text : palette.muted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? palette.lime : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? palette.text : palette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
