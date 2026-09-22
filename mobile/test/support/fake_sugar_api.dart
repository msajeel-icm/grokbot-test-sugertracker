import 'package:sugar_tracker/src/api/api_exception.dart';
import 'package:sugar_tracker/src/api/models.dart';
import 'package:sugar_tracker/src/api/sugar_api.dart';

class FakeSugarApi implements SugarApi {
  FakeSugarApi({this.limitG = 15});

  double limitG;
  String timezone = 'UTC';
  double consumedG = 0;
  int currentStreak = 2;
  int bestStreak = 4;
  String email = 'demo@sugar.app';
  bool unauthorized = false;
  bool offline = false;
  int registerCalls = 0;
  int logCalls = 0;
  double? lastLoggedSugar;
  String? lastLoggedLabel;
  String? lastPhotoFilename;
  String? lastHint;

  final List<Meal> meals = [];

  @override
  String? token;

  UserProfile _profile() {
    return UserProfile(
      id: 1,
      email: email,
      dailySugarLimitG: limitG,
      timezone: timezone,
      createdAt: DateTime.utc(2026, 9, 1),
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }

  AuthSession _session() {
    token = 'token';
    return AuthSession(
      accessToken: 'token',
      tokenType: 'bearer',
      user: _profile(),
    );
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (password == 'wrong') {
      throw ApiException(statusCode: 401, message: 'Invalid email or password');
    }
    this.email = email;
    return _session();
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    registerCalls += 1;
    this.email = email;
    limitG = 15;
    return _session();
  }

  @override
  Future<UserProfile> getMe() async {
    if (offline) {
      throw ApiException(
        message:
            'Cannot reach the API. Start the backend and check the API URL.',
      );
    }
    if (unauthorized) {
      throw ApiException(statusCode: 401, message: 'Invalid or expired token');
    }
    return _profile();
  }

  @override
  Future<UserProfile> updateMe({
    double? dailySugarLimitG,
    String? timezone,
  }) async {
    if (timezone == 'Not/AZone') {
      throw ApiException(statusCode: 422, message: 'Unknown IANA timezone');
    }
    if (dailySugarLimitG != null) limitG = dailySugarLimitG;
    if (timezone != null) this.timezone = timezone;
    return _profile();
  }

  @override
  Future<AnalyzeResult> analyzeMeal({String? hint, MealPhoto? photo}) async {
    lastHint = hint;
    lastPhotoFilename = photo?.filename;
    const sugar = 12.0;
    final remaining = limitG - consumedG;
    return AnalyzeResult(
      sugarG: sugar,
      label: 'chocolate chip cookie',
      confidence: 0.81,
      remainingBudgetG: remaining,
      wouldExceed: sugar > remaining,
      suggestion: const Suggestion(
        fractions: ['1/3', '1/2'],
        fractionSugarG: {'1/3': 4.01, '1/2': 6},
        alternatives: [
          FoodAlternative(label: 'grilled chicken', sugarG: 0),
          FoodAlternative(label: 'cucumber', sugarG: 1.7),
        ],
      ),
    );
  }

  @override
  Future<Meal> logMeal({
    required double sugarG,
    required String label,
    String? localDate,
    String? photoRef,
    String? notes,
  }) async {
    logCalls += 1;
    lastLoggedSugar = sugarG;
    lastLoggedLabel = label;
    consumedG += sugarG;
    if (consumedG < limitG) currentStreak = 3;
    final meal = Meal(
      id: meals.length + 1,
      label: label,
      sugarG: sugarG,
      loggedAt: DateTime.utc(2026, 9, 22, 15, 30),
      localDate: localDate ?? '2026-09-22',
      status: 'logged',
      notes: notes,
      photoPathOrUrl: photoRef,
    );
    meals.add(meal);
    return meal;
  }

  @override
  Future<List<Meal>> mealsOn(String date) async {
    return [
      for (final meal in meals)
        if (meal.localDate == date) meal,
    ];
  }

  @override
  Future<DashboardData> dashboard() async {
    return DashboardData(
      date: '2026-09-22',
      limitG: limitG,
      consumedG: consumedG,
      remainingG: limitG - consumedG,
      meals: List<Meal>.from(meals),
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }
}
