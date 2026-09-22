import 'models.dart';

/// Sugar tracker HTTP API.
///
/// JSON names match the FastAPI models (`daily_sugar_limit_g`, `sugar_g`,
/// `would_exceed`, `fraction_sugar_g`, and the rest).
abstract class SugarApi {
  String? get token;
  set token(String? value);

  /// `POST /api/v1/auth/login`
  Future<AuthSession> login({required String email, required String password});

  /// `POST /api/v1/auth/register`
  Future<AuthSession> register({
    required String email,
    required String password,
  });

  /// `GET /api/v1/me`
  Future<UserProfile> getMe();

  /// `PATCH /api/v1/me`
  Future<UserProfile> updateMe({double? dailySugarLimitG, String? timezone});

  /// `POST /api/v1/meals/analyze`. Does not create a meal.
  Future<AnalyzeResult> analyzeMeal({String? hint, MealPhoto? photo});

  /// `POST /api/v1/meals`. Confirm a portion. Cancel must not call this.
  Future<Meal> logMeal({
    required double sugarG,
    required String label,
    String? localDate,
    String? photoRef,
    String? notes,
  });

  /// `GET /api/v1/meals?date=YYYY-MM-DD`
  Future<List<Meal>> mealsOn(String date);

  /// `GET /api/v1/dashboard`
  Future<DashboardData> dashboard();
}
