import 'package:sugar_tracker/api/models.dart';
import 'package:sugar_tracker/api/sugar_api.dart';
import 'package:sugar_tracker/format.dart';

class FakeSugarApi implements SugarApi {
  FakeSugarApi({this.startLoggedIn = false});

  bool startLoggedIn;
  bool failDashboard = false;
  String? analyzeError;
  double limit = 15;
  int currentStreak = 0;
  int bestStreak = 0;
  String email = 'demo@sugar.app';
  String password = 'demo1234';

  final List<Meal> meals = [];
  int logCalls = 0;
  LoggedMeal? lastLog;
  String? lastHint;
  List<int>? lastImage;
  String? _token;

  double get consumedSugar => round2(meals.fold(0, (sum, meal) => sum + meal.sugarG));

  double get consumedKcal => round2(meals.fold(0, (sum, meal) => sum + meal.kcal));

  UserProfile get profile => UserProfile(
        id: 1,
        email: email,
        dailySugarLimitG: limit,
        timezone: 'UTC',
        currentStreak: currentStreak,
        bestStreak: bestStreak,
      );

  @override
  Future<UserProfile?> restore() async {
    if (!startLoggedIn && _token == null) return null;
    _token ??= 'demo-token';
    return profile;
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    if (email != this.email || password != this.password) {
      throw ApiException('Those credentials did not match.', statusCode: 401);
    }
    _token = 'demo-token';
    startLoggedIn = true;
    return profile;
  }

  @override
  Future<void> logout() async {
    _token = null;
    startLoggedIn = false;
  }

  @override
  Future<UserProfile> me() async => profile;

  @override
  Future<UserProfile> updateLimit(double dailySugarLimitG) async {
    limit = dailySugarLimitG;
    return profile;
  }

  @override
  Future<Dashboard> dashboard() async {
    if (failDashboard) throw ApiException("Can't reach the server.");
    return Dashboard(
      date: '2026-09-22',
      limitG: limit,
      consumedG: consumedSugar,
      remainingG: round2(limit - consumedSugar),
      consumedKcal: consumedKcal,
      meals: List.of(meals),
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }

  @override
  Future<AnalyzeResult> analyze({String? hint, List<int>? image, String? imageName}) async {
    lastHint = hint;
    lastImage = image;
    if (analyzeError != null) throw ApiException(analyzeError!);
    final food = _foodFor(hint, image);
    final remaining = round2(limit - consumedSugar);
    return AnalyzeResult(
      sugarG: food.sugarG,
      kcal: food.kcal,
      label: food.label,
      confidence: food.confidence,
      remainingBudgetG: remaining,
      wouldExceed: wouldExceed(sugarG: food.sugarG, remainingG: remaining, kcal: food.kcal),
      fractionSugarG: {
        '1/3': round2(food.sugarG / 3),
        '1/2': round2(food.sugarG / 2),
      },
      fractionKcal: {
        '1/3': round2(food.kcal / 3),
        '1/2': round2(food.kcal / 2),
      },
      alternatives: food.label == 'grilled chicken'
          ? const [
              FoodAlternative(label: 'cucumber', sugarG: 1.7, kcal: 16),
              FoodAlternative(label: 'celery sticks', sugarG: 1.2, kcal: 14),
            ]
          : const [
              FoodAlternative(label: 'grilled chicken', sugarG: 0, kcal: 165),
              FoodAlternative(label: 'cucumber', sugarG: 1.7, kcal: 16),
            ],
    );
  }

  @override
  Future<Meal> logMeal({
    required String label,
    required double sugarG,
    required double kcal,
    String? photoRef,
  }) async {
    logCalls += 1;
    lastLog = LoggedMeal(label: label, sugarG: sugarG, kcal: kcal, photoRef: photoRef);
    final meal = Meal(
      id: meals.length + 1,
      label: label,
      sugarG: sugarG,
      kcal: kcal,
      localDate: '2026-09-22',
      status: 'logged',
    );
    meals.add(meal);
    return meal;
  }

  _Food _foodFor(String? hint, List<int>? image) {
    final text = (hint ?? '').toLowerCase();
    if (text.contains('chicken')) return _Food.chicken;
    if (text.contains('cookie')) return _Food.cookie;
    if (image != null && image.isNotEmpty) return _Food.cookie;
    return _Food.snack;
  }
}

class _Food {
  const _Food(this.label, this.sugarG, this.kcal, this.confidence);

  final String label;
  final double sugarG;
  final double kcal;
  final double confidence;

  static const cookie = _Food('chocolate chip cookie', 12, 160, 0.81);
  static const chicken = _Food('grilled chicken', 0, 165, 0.92);
  static const snack = _Food('mixed snack', 18, 210, 0.5);
}
