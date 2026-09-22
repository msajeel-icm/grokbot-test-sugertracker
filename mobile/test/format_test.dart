import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_tracker/src/format.dart';

void main() {
  test('formats grams and dates', () {
    expect(formatGrams(0), '0');
    expect(formatGrams(15), '15');
    expect(formatGrams(1.7), '1.7');
    expect(formatGrams(4.01), '4.01');
    expect(formatGrams(8.5), '8.5');
    expect(formatGrams(-2.5), '-2.5');
    expect(formatConfidence(0.81), '81%');
    expect(formatDay('2026-09-22'), 'Tuesday, September 22');
    expect(remainingLabel(9), '9 g left');
    expect(remainingLabel(-5), '5 g over');
  });
}
