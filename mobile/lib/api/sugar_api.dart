import 'models.dart';

abstract class SugarApi {
  Future<UserProfile?> restore();

  Future<UserProfile> login(String email, String password);

  Future<UserProfile> register(String email, String password);

  Future<void> logout();

  Future<UserProfile> me();

  Future<UserProfile> updateLimit(double dailySugarLimitG);

  Future<UserProfile> updateTimezone(String timezone);

  Future<Dashboard> dashboard();

  Future<AnalyzeResult> analyze({String? hint, List<int>? image, String? imageName});

  Future<Meal> logMeal({
    required String label,
    required double sugarG,
    required double kcal,
    String? photoRef,
  });
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
