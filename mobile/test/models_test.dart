import 'package:flutter_test/flutter_test.dart';
import 'package:sugar_tracker/src/api/models.dart';

void main() {
  test('parses auth, analyze, and dashboard payloads', () {
    final session = AuthSession.fromJson({
      'access_token': 'abc',
      'token_type': 'bearer',
      'user': {
        'id': 7,
        'email': 'demo@sugar.app',
        'daily_sugar_limit_g': 15,
        'timezone': 'UTC',
        'created_at': '2026-09-01T00:00:00Z',
        'current_streak': 2,
        'best_streak': 4,
      },
    });
    expect(session.accessToken, 'abc');
    expect(session.user.dailySugarLimitG, 15);
    expect(session.user.currentStreak, 2);
    expect(session.user.bestStreak, 4);

    final analyzed = AnalyzeResult.fromJson({
      'sugar_g': 12,
      'label': 'chocolate chip cookie',
      'confidence': 0.81,
      'remaining_budget_g': 15,
      'would_exceed': false,
      'suggestion': {
        'fractions': ['1/3', '1/2'],
        'fraction_sugar_g': {'1/3': 4, '1/2': 6},
        'alternatives': [
          {'label': 'grilled chicken', 'sugar_g': 0},
          {'label': 'cucumber', 'sugar_g': 1.7},
        ],
      },
    });
    expect(analyzed.label, 'chocolate chip cookie');
    expect(analyzed.suggestion.fractions, ['1/3', '1/2']);
    expect(analyzed.suggestion.fractionSugarG['1/3'], 4);
    expect(analyzed.suggestion.fractionSugarG['1/2'], 6);
    expect(analyzed.suggestion.alternatives.first.sugarG, 0);
    expect(analyzed.wouldExceed, isFalse);

    final dashboard = DashboardData.fromJson({
      'date': '2026-09-22',
      'limit_g': 15,
      'consumed_g': 8.5,
      'remaining_g': 6.5,
      'current_streak': 1,
      'best_streak': 1,
      'meals': [
        {
          'id': 1,
          'label': 'oatmeal',
          'sugar_g': 1,
          'logged_at': '2026-09-22T08:00:00Z',
          'local_date': '2026-09-22',
          'status': 'logged',
          'notes': 'breakfast',
          'photo_path_or_url': null,
        },
      ],
    });
    expect(dashboard.date, '2026-09-22');
    expect(dashboard.consumedG, 8.5);
    expect(dashboard.remainingG, 6.5);
    expect(dashboard.meals.single.notes, 'breakfast');
    expect(dashboard.meals.single.localDate, '2026-09-22');
  });
}
