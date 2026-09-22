import 'dart:typed_data';

/// Photo bytes sent to `POST /api/v1/meals/analyze` as multipart field `image`.
class MealPhoto {
  const MealPhoto({required this.bytes, required this.filename, this.path});

  final Uint8List bytes;
  final String filename;

  /// Device path stored as `photo_ref` when the meal is confirmed. The server
  /// does not keep the image file.
  final String? path;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.dailySugarLimitG,
    required this.timezone,
    required this.createdAt,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int id;
  final String email;
  final double dailySugarLimitG;
  final String timezone;
  final DateTime createdAt;
  final int currentStreak;
  final int bestStreak;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _asInt(json['id'], 'id'),
      email: _asString(json['email'], 'email'),
      dailySugarLimitG: _asDouble(
        json['daily_sugar_limit_g'],
        'daily_sugar_limit_g',
      ),
      timezone: _asString(json['timezone'], 'timezone'),
      createdAt: DateTime.parse(_asString(json['created_at'], 'created_at')),
      currentStreak: _asInt(json['current_streak'], 'current_streak'),
      bestStreak: _asInt(json['best_streak'], 'best_streak'),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final UserProfile user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: _asString(json['access_token'], 'access_token'),
      tokenType: json['token_type'] == null
          ? 'bearer'
          : _asString(json['token_type'], 'token_type'),
      user: UserProfile.fromJson(_asMap(json['user'], 'user')),
    );
  }
}

class Meal {
  const Meal({
    required this.id,
    required this.label,
    required this.sugarG,
    required this.loggedAt,
    required this.localDate,
    required this.status,
    this.notes,
    this.photoPathOrUrl,
  });

  final int id;
  final String label;
  final double sugarG;
  final DateTime loggedAt;
  final String localDate;
  final String status;
  final String? notes;
  final String? photoPathOrUrl;

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: _asInt(json['id'], 'id'),
      label: _asString(json['label'], 'label'),
      sugarG: _asDouble(json['sugar_g'], 'sugar_g'),
      loggedAt: DateTime.parse(_asString(json['logged_at'], 'logged_at')),
      localDate: _asString(json['local_date'], 'local_date'),
      status: _asString(json['status'], 'status'),
      notes: _asOptionalString(json['notes']),
      photoPathOrUrl: _asOptionalString(json['photo_path_or_url']),
    );
  }
}

class FoodAlternative {
  const FoodAlternative({required this.label, required this.sugarG});

  final String label;
  final double sugarG;

  factory FoodAlternative.fromJson(Map<String, dynamic> json) {
    return FoodAlternative(
      label: _asString(json['label'], 'label'),
      sugarG: _asDouble(json['sugar_g'], 'sugar_g'),
    );
  }
}

class Suggestion {
  const Suggestion({
    required this.fractions,
    required this.fractionSugarG,
    required this.alternatives,
  });

  final List<String> fractions;
  final Map<String, double> fractionSugarG;
  final List<FoodAlternative> alternatives;

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    final fractions = <String>[];
    final rawFractions = json['fractions'];
    if (rawFractions is List) {
      for (final item in rawFractions) {
        fractions.add(item.toString());
      }
    }
    final portionSugar = <String, double>{};
    final rawPortions = json['fraction_sugar_g'];
    if (rawPortions is Map) {
      rawPortions.forEach((key, value) {
        if (value is num) portionSugar[key.toString()] = value.toDouble();
      });
    }
    final alternatives = <FoodAlternative>[];
    final rawAlternatives = json['alternatives'];
    if (rawAlternatives is List) {
      for (final item in rawAlternatives) {
        alternatives.add(
          FoodAlternative.fromJson(_asMap(item, 'alternatives')),
        );
      }
    }
    return Suggestion(
      fractions: fractions,
      fractionSugarG: portionSugar,
      alternatives: alternatives,
    );
  }
}

class AnalyzeResult {
  const AnalyzeResult({
    required this.sugarG,
    required this.label,
    required this.confidence,
    required this.remainingBudgetG,
    required this.wouldExceed,
    required this.suggestion,
  });

  final double sugarG;
  final String label;
  final double confidence;
  final double remainingBudgetG;
  final bool wouldExceed;
  final Suggestion suggestion;

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) {
    return AnalyzeResult(
      sugarG: _asDouble(json['sugar_g'], 'sugar_g'),
      label: _asString(json['label'], 'label'),
      confidence: _asDouble(json['confidence'], 'confidence'),
      remainingBudgetG: _asDouble(
        json['remaining_budget_g'],
        'remaining_budget_g',
      ),
      wouldExceed: _asBool(json['would_exceed'], 'would_exceed'),
      suggestion: Suggestion.fromJson(_asMap(json['suggestion'], 'suggestion')),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.date,
    required this.limitG,
    required this.consumedG,
    required this.remainingG,
    required this.meals,
    required this.currentStreak,
    required this.bestStreak,
  });

  final String date;
  final double limitG;
  final double consumedG;
  final double remainingG;
  final List<Meal> meals;
  final int currentStreak;
  final int bestStreak;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'];
    if (rawMeals is! List) {
      throw const FormatException('Expected list for meals');
    }
    return DashboardData(
      date: _asString(json['date'], 'date'),
      limitG: _asDouble(json['limit_g'], 'limit_g'),
      consumedG: _asDouble(json['consumed_g'], 'consumed_g'),
      remainingG: _asDouble(json['remaining_g'], 'remaining_g'),
      meals: [
        for (final item in rawMeals) Meal.fromJson(_asMap(item, 'meals')),
      ],
      currentStreak: _asInt(json['current_streak'], 'current_streak'),
      bestStreak: _asInt(json['best_streak'], 'best_streak'),
    );
  }
}

double _asDouble(Object? value, String field) {
  if (value is num) return value.toDouble();
  throw FormatException('Expected number for $field');
}

int _asInt(Object? value, String field) {
  if (value is num) return value.toInt();
  throw FormatException('Expected integer for $field');
}

bool _asBool(Object? value, String field) {
  if (value is bool) return value;
  throw FormatException('Expected boolean for $field');
}

String _asString(Object? value, String field) {
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Expected string for $field');
}

String? _asOptionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  throw const FormatException('Expected string');
}

Map<String, dynamic> _asMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Expected object for $field');
}
