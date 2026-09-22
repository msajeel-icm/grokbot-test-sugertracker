import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_tracker/format.dart';

void main() {
  test('sugar gates the budget and kcal does not', () {
    expect(wouldExceed(sugarG: 12, remainingG: 15, kcal: 160), isFalse);
    expect(wouldExceed(sugarG: 12, remainingG: 5, kcal: 0), isTrue);
    expect(wouldExceed(sugarG: 5, remainingG: 5, kcal: 999), isFalse);
    expect(wouldExceed(sugarG: 0, remainingG: 0, kcal: 165), isFalse);
    expect(wouldExceed(sugarG: 0.01, remainingG: 0, kcal: 1), isTrue);
  });

  test('tone follows sugar consumed against the limit', () {
    expect(toneFor(consumed: 10, limit: 15), BudgetTone.under);
    expect(toneFor(consumed: 15, limit: 15), BudgetTone.atLimit);
    expect(toneFor(consumed: 16, limit: 15), BudgetTone.over);
    expect(toneFor(consumed: 0, limit: 15), BudgetTone.under);
  });

  test('amounts stay readable and portions use two decimals', () {
    expect(formatAmount(12), '12');
    expect(formatAmount(1.7), '1.7');
    expect(formatAmount(53.33), '53.33');
    expect(formatAmount(8.5), '8.5');
    expect(formatSugar(4), '4 g');
    expect(formatKcal(160), '160 kcal');
    expect(remainingLine(5), '5 g left');
    expect(remainingLine(0), 'At the sugar limit');
    expect(remainingLine(-4), '4 g over');
    expect(formatDay('2026-09-22'), 'Tuesday, Sep 22');
  });
}
