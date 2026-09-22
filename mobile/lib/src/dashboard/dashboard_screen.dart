import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/models.dart';
import '../auth/session_controller.dart';
import '../format.dart';
import '../meals/log_meal_screen.dart';
import '../settings/settings_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final keep = _data;
    if (keep != null || !_loading) {
      setState(() {
        _loading = keep == null;
        if (keep == null) _error = null;
      });
    }
    try {
      final data = await widget.session.api.dashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        await widget.session.logout();
        return;
      }
      setState(() {
        _loading = false;
        if (_data == null) {
          _error = error.message;
        }
      });
      if (_data != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _openLog() async {
    final logged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LogMealScreen(session: widget.session)),
    );
    if (logged == true && mounted) await _reload();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(session: widget.session),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            key: const Key('settings'),
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: CenteredPanel(child: _body()),
      bottomNavigationBar: _data == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: BusyButton(
                  key: const Key('log-meal'),
                  label: 'Log meal',
                  onPressed: _openLog,
                ),
              ),
            ),
    );
  }

  Widget _body() {
    if (_loading && _data == null) {
      return const Center(
        child: CircularProgressIndicator(key: Key('dashboard-loading')),
      );
    }
    final data = _data;
    if (data == null) {
      return _LoadError(
        message: _error ?? 'Could not load today.',
        onRetry: _reload,
      );
    }
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final over = data.remainingG < 0;
    final ratio = data.limitG <= 0
        ? (data.consumedG > 0 ? 1.0 : 0.0)
        : (data.consumedG / data.limitG).clamp(0.0, 1.0);
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Text(formatDay(data.date), style: text.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatGrams(data.consumedG),
                        key: const Key('consumed-value'),
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(' / ', style: text.titleLarge),
                      Text(
                        formatGrams(data.limitG),
                        key: const Key('limit-value'),
                        style: text.titleLarge,
                      ),
                      Text(' g', style: text.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label:
                        '${formatGrams(data.consumedG)} of ${formatGrams(data.limitG)} grams',
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(99),
                      backgroundColor: sugarLine,
                      color: over ? colors.error : colors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    remainingLabel(data.remainingG),
                    key: const Key('remaining-value'),
                    style: text.titleMedium?.copyWith(
                      color: over ? colors.error : sugarGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StreakCard(
                  label: 'Current streak',
                  valueKey: const Key('streak-current'),
                  value: data.currentStreak,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StreakCard(
                  label: 'Best streak',
                  valueKey: const Key('streak-best'),
                  value: data.bestStreak,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Today’s meals', style: text.titleMedium),
          const SizedBox(height: 8),
          if (data.meals.isEmpty)
            const Padding(
              key: Key('meals-empty'),
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No meals logged today.'),
            )
          else
            for (final meal in data.meals) _MealTile(meal: meal),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.label,
    required this.valueKey,
    required this.value,
  });

  final String label;
  final Key valueKey;
  final int value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '$value',
              key: valueKey,
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(value == 1 ? 'day' : 'days', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final notes = meal.notes;
    final subtitle = (notes == null || notes.isEmpty)
        ? formatClock(meal.loggedAt)
        : '${formatClock(meal.loggedAt)} · $notes';
    return Card(
      child: ListTile(
        title: Text(meal.label),
        subtitle: Text(subtitle),
        trailing: Text(
          '${formatGrams(meal.sugarG)} g',
          style: text.titleMedium,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorNote(message: message),
            const SizedBox(height: 16),
            BusyButton(
              key: const Key('dashboard-retry'),
              label: 'Try again',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
