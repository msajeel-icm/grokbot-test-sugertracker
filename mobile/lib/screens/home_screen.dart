import 'package:flutter/material.dart';

import '../api/models.dart';
import '../format.dart';
import '../state/app_model.dart';
import '../theme/tokens.dart';
import '../widgets/meal_tile.dart';
import '../widgets/sugar_ring.dart';
import '../widgets/surface_card.dart';
import 'log_meal_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.model, this.pickPhoto});

  final AppModel model;
  final Future<MealPhoto?> Function()? pickPhoto;

  Future<void> _logMeal(BuildContext context) async {
    final logged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LogMealScreen(api: model.api, pickPhoto: pickPhoto),
      ),
    );
    if (logged == true) await model.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final dashboard = model.dashboard;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugar'),
        actions: [
          IconButton(
            key: const Key('open-settings'),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsScreen(model: model)),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: dashboard == null
          ? _DashboardPlaceholder(model: model)
          : RefreshIndicator(
              color: palette.under,
              onRefresh: model.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text(formatDay(dashboard.date), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                    child: SugarRing(
                      consumed: dashboard.consumedG,
                      limit: dashboard.limitG,
                      remaining: dashboard.remainingG,
                      kcal: dashboard.consumedKcal,
                    ),
                  ),
                  if (model.dashboardError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      model.dashboardError!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: palette.over),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StreakCard(
                          label: 'Current',
                          value: dashboard.currentStreak,
                          valueKey: const Key('streak-current'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StreakCard(
                          label: 'Best',
                          value: dashboard.bestStreak,
                          valueKey: const Key('streak-best'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A day counts when logged sugar stays under the limit.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  const SectionLabel('Today'),
                  const SizedBox(height: 8),
                  if (dashboard.meals.isEmpty)
                    const SurfaceCard(
                      child: Text(
                        'No meals logged today.',
                        key: Key('meals-empty'),
                      ),
                    )
                  else
                    SurfaceCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < dashboard.meals.length; i++) ...[
                            if (i > 0) Divider(height: 1, color: palette.border),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: MealTile(meal: dashboard.meals[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.background,
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: FilledButton(
              key: const Key('open-log'),
              onPressed: dashboard == null ? null : () => _logMeal(context),
              child: const Text('Log meal'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.label, required this.value, required this.valueKey});

  final String label;
  final int value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            '$value',
            key: valueKey,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder({required this.model});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final theme = Theme.of(context);
    if (model.dashboardLoading && model.dashboardError == null) {
      return const Center(child: Text('Loading today…'));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load today.", style: theme.textTheme.titleMedium),
            if (model.dashboardError != null) ...[
              const SizedBox(height: 8),
              Text(
                model.dashboardError!,
                key: const Key('dashboard-error'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('retry'),
              onPressed: model.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
