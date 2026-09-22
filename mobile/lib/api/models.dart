class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.dailySugarLimitG,
    required this.timezone,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int id;
  final String email;
  final double dailySugarLimitG;
  final String timezone;
  final int currentStreak;
  final int bestStreak;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      dailySugarLimitG: (json['daily_sugar_limit_g'] as num).toDouble(),
      timezone: json['timezone'] as String? ?? 'UTC',
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class Meal {
  const Meal({
    required this.id,
    required this.label,
    required this.sugarG,
    required this.kcal,
    required this.localDate,
    required this.status,
    this.notes,
  });

  final int id;
  final String label;
  final double sugarG;
  final double kcal;
  final String localDate;
  final String status;
  final String? notes;

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String,
      sugarG: (json['sugar_g'] as num).toDouble(),
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
      localDate: json['local_date'] as String,
      status: json['status'] as String? ?? 'logged',
      notes: json['notes'] as String?,
    );
  }
}

class FoodAlternative {
  const FoodAlternative({
    required this.label,
    required this.sugarG,
    required this.kcal,
  });

  final String label;
  final double sugarG;
  final double kcal;

  factory FoodAlternative.fromJson(Map<String, dynamic> json) {
    return FoodAlternative(
      label: json['label'] as String,
      sugarG: (json['sugar_g'] as num).toDouble(),
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AnalyzeResult {
  const AnalyzeResult({
    required this.sugarG,
    required this.kcal,
    required this.label,
    required this.confidence,
    required this.remainingBudgetG,
    required this.wouldExceed,
    required this.fractionSugarG,
    required this.fractionKcal,
    required this.alternatives,
  });

  final double sugarG;
  final double kcal;
  final String label;
  final double confidence;
  final double remainingBudgetG;
  final bool wouldExceed;
  final Map<String, double> fractionSugarG;
  final Map<String, double> fractionKcal;
  final List<FoodAlternative> alternatives;

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) {
    final suggestion = json['suggestion'] as Map<String, dynamic>? ?? {};
    final alternatives = (suggestion['alternatives'] as List<dynamic>? ?? [])
        .map((item) => FoodAlternative.fromJson(item as Map<String, dynamic>))
        .toList();
    return AnalyzeResult(
      sugarG: (json['sugar_g'] as num).toDouble(),
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
      label: json['label'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      remainingBudgetG: (json['remaining_budget_g'] as num?)?.toDouble() ?? 0,
      wouldExceed: json['would_exceed'] as bool? ?? false,
      fractionSugarG: _numMap(suggestion['fraction_sugar_g']),
      fractionKcal: _numMap(suggestion['fraction_kcal']),
      alternatives: alternatives,
    );
  }
}

class Dashboard {
  const Dashboard({
    required this.date,
    required this.limitG,
    required this.consumedG,
    required this.remainingG,
    required this.consumedKcal,
    required this.meals,
    required this.currentStreak,
    required this.bestStreak,
  });

  final String date;
  final double limitG;
  final double consumedG;
  final double remainingG;
  final double consumedKcal;
  final List<Meal> meals;
  final int currentStreak;
  final int bestStreak;

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final meals = (json['meals'] as List<dynamic>? ?? [])
        .map((item) => Meal.fromJson(item as Map<String, dynamic>))
        .toList();
    return Dashboard(
      date: json['date'] as String,
      limitG: (json['limit_g'] as num).toDouble(),
      consumedG: (json['consumed_g'] as num).toDouble(),
      remainingG: (json['remaining_g'] as num).toDouble(),
      consumedKcal: (json['consumed_kcal'] as num?)?.toDouble() ?? 0,
      meals: meals,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
    );
  }
}

class MealPhoto {
  const MealPhoto({required this.bytes, required this.name, this.path});

  final List<int> bytes;
  final String name;

  /// Device path stored as `photo_ref` when it fits. Analyze still sends bytes.
  final String? path;
}

/// Confirm stores the device path only. A missing or oversized path is omitted.
String? photoRefForLog(MealPhoto? photo) {
  final path = photo?.path?.trim() ?? '';
  if (path.isEmpty || path.length > 1024) return null;
  return path;
}

class LoggedMeal {
  const LoggedMeal({
    required this.label,
    required this.sugarG,
    required this.kcal,
    this.photoRef,
  });

  final String label;
  final double sugarG;
  final double kcal;
  final String? photoRef;
}

Map<String, double> _numMap(Object? raw) {
  if (raw is! Map) return {};
  return raw.map((key, value) => MapEntry('$key', (value as num).toDouble()));
}
