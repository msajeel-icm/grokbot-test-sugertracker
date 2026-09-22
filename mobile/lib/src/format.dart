const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Grams for display. Whole numbers stay whole; other values keep up to 2 decimals.
String formatGrams(double value) {
  final rounded = (value.abs() * 100).round() / 100;
  if (rounded == 0) return '0';
  final String text;
  if (rounded == rounded.roundToDouble()) {
    text = rounded.toStringAsFixed(0);
  } else {
    var fixed = rounded.toStringAsFixed(2);
    if (fixed.endsWith('0')) {
      fixed = fixed.substring(0, fixed.length - 1);
    }
    text = fixed;
  }
  return value.isNegative ? '-$text' : text;
}

String formatConfidence(double value) {
  final percent = (value * 100).round().clamp(0, 100);
  return '$percent%';
}

/// Calendar date from a `YYYY-MM-DD` string, without shifting it through local time.
String formatDay(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null ||
      month == null ||
      day == null ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31) {
    return isoDate;
  }
  final date = DateTime.utc(year, month, day);
  final weekday = _weekdays[date.weekday - 1];
  return '$weekday, ${_months[month - 1]} $day';
}

String formatClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String remainingLabel(double remainingG) {
  if (remainingG < 0) return '${formatGrams(remainingG.abs())} g over';
  return '${formatGrams(remainingG)} g left';
}
