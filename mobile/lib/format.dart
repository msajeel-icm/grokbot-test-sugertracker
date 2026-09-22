/// Sugar is the only daily limit. Calories are display-only.
bool wouldExceed({
  required double sugarG,
  required double remainingG,
  double kcal = 0,
}) {
  if (kcal.isNaN) {
    throw ArgumentError.value(kcal, 'kcal');
  }
  return round2(sugarG) > round2(remainingG);
}

enum BudgetTone { under, atLimit, over }

BudgetTone toneFor({required double consumed, required double limit}) {
  if (round2(consumed) > round2(limit)) return BudgetTone.over;
  if (round2(limit) >= 0 && round2(consumed) == round2(limit) && round2(consumed) > 0) {
    return BudgetTone.atLimit;
  }
  return BudgetTone.under;
}

double round2(double value) => (value * 100).round() / 100;

String formatAmount(double value) {
  final rounded = round2(value);
  if (rounded == rounded.roundToDouble()) {
    return rounded.toInt().toString();
  }
  var text = rounded.toStringAsFixed(2);
  if (text.contains('.') && text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}

String formatSugar(double grams) => '${formatAmount(grams)} g';

String formatKcal(double kcal) => '${formatAmount(kcal)} kcal';

String remainingLine(double remaining) {
  if (round2(remaining) < 0) return '${formatAmount(-remaining)} g over';
  if (round2(remaining) == 0) return 'At the sugar limit';
  return '${formatAmount(remaining)} g left';
}

String formatDay(String isoDate) {
  final date = DateTime.parse(isoDate);
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}
