import 'package:flutter/material.dart';

import '../api/models.dart';
import '../format.dart';
import '../state/app_model.dart';
import '../theme/tokens.dart';
import '../widgets/date_strip.dart';
import '../widgets/meal_tile.dart';
import '../widgets/progress_ring.dart';
import '../widgets/sugar_ring.dart';
import '../widgets/surface_card.dart';
import 'log_meal_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.model, this.pickPhoto});

  final AppModel model;
  final Future<MealPhoto?> Function()? pickPhoto;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 0 home, 1 analytics stub, 2 chat stub. Profile opens settings.
  int _tab = 0;

  AppModel get model => widget.model;

  Future<void> _logMeal() async {
    final logged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            LogMealScreen(api: model.api, pickPhoto: widget.pickPhoto),
      ),
    );
    if (logged == true) await model.refresh();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SettingsScreen(model: model)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final dashboard = model.dashboard;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: dashboard == null
            ? _DashboardPlaceholder(model: model)
            : _tab == 1
                ? const _StubPane(
                    icon: Icons.bar_chart_rounded,
                    title: 'Analytics',
                    message:
                        'A longer look at your days is not in this version.',
                  )
                : _tab == 2
                    ? const _StubPane(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Chat',
                        message: 'Chat is not available yet.',
                      )
                    : RefreshIndicator(
                        color: palette.under,
                        onRefresh: model.refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            _Greeting(email: model.user?.email),
                            const SizedBox(height: 6),
                            Text(
                              formatDay(dashboard.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            DateStrip(isoDate: dashboard.date),
                            const SizedBox(height: 14),
                            SurfaceCard(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 16, 18, 16),
                              child: SugarRing(
                                consumed: dashboard.consumedG,
                                limit: dashboard.limitG,
                                remaining: dashboard.remainingG,
                              ),
                            ),
                            if (model.dashboardError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                model.dashboardError!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: palette.over,
                                    ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: _KcalCard(
                                        kcal: dashboard.consumedKcal)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StreakCard(
                                    current: dashboard.currentStreak,
                                    best: dashboard.bestStreak,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
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
                                    for (var i = 0;
                                        i < dashboard.meals.length;
                                        i++) ...[
                                      if (i > 0)
                                        Divider(
                                            height: 1, color: palette.border),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        child:
                                            MealTile(meal: dashboard.meals[i]),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
      ),
      bottomNavigationBar: _MintNav(
        tab: _tab,
        onHome: () => setState(() => _tab = 0),
        onAnalytics: () => setState(() => _tab = 1),
        onChat: () => setState(() => _tab = 2),
        onProfile: _openSettings,
        onAdd: dashboard == null ? null : _logMeal,
      ),
    );
  }
}

String _helloName(String? email) {
  final local = (email ?? '').split('@').first.trim();
  if (local.isEmpty) return 'there';
  return local[0].toUpperCase() + local.substring(1);
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = Palette.of(context);
    final name = _helloName(email);
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $name', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 2),
              Text('Keep Moving Today!', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        Material(
          color: palette.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notifications are not available yet.')),
              );
            },
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.notifications_none_rounded, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 22,
          backgroundColor: palette.lime.withValues(alpha: 0.35),
          child: Text(
            initial,
            style: TextStyle(fontWeight: FontWeight.w800, color: palette.text),
          ),
        ),
      ],
    );
  }
}

class _KcalCard extends StatelessWidget {
  const _KcalCard({required this.kcal});

  final double kcal;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final theme = Theme.of(context);
    // The arc is only a shape from the mockup. The label is today's real kcal
    // total and is not a budget.
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatKcal(kcal)} today',
            key: const Key('kcal-today'),
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'kcal',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              ProgressRing(
                value: kcal <= 0 ? 0 : 0.72,
                color: palette.amber,
                size: 54,
                stroke: 7,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.current, required this.best});

  final int current;
  final int best;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final theme = Theme.of(context);
    final ratio = best <= 0 ? 0.0 : (current / best).clamp(0.0, 1.0);
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Streak',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$current',
                      key: const Key('streak-current'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(current == 1 ? 'day' : 'days',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              ProgressRing(
                  value: ratio, color: palette.lime, size: 54, stroke: 7),
            ],
          ),
          const SizedBox(height: 8),
          Text('Best', style: theme.textTheme.bodySmall),
          Text(
            '$best',
            key: const Key('streak-best'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StubPane extends StatelessWidget {
  const _StubPane(
      {required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, 8)),
                ],
              ),
              child: Icon(icon, color: palette.under, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MintNav extends StatelessWidget {
  const _MintNav({
    required this.tab,
    required this.onHome,
    required this.onAnalytics,
    required this.onChat,
    required this.onProfile,
    required this.onAdd,
  });

  final int tab;
  final VoidCallback onHome;
  final VoidCallback onAnalytics;
  final VoidCallback onChat;
  final VoidCallback onProfile;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 108,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 78,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.surface,
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, -4)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          selected: tab == 0,
                          onTap: onHome,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.bar_chart_rounded,
                          label: 'Analytics',
                          selected: tab == 1,
                          onTap: onAnalytics,
                        ),
                      ),
                      const SizedBox(width: 72),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Chat',
                          selected: tab == 2,
                          onTap: onChat,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          key: const Key('open-settings'),
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          selected: false,
                          onTap: onProfile,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: _AddButton(onPressed: onAdd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final color = selected ? palette.text : palette.muted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Material(
      color: palette.text,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        key: const Key('open-log'),
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 66,
          height: 66,
          child: Center(
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: palette.lime, shape: BoxShape.circle),
              child: const SizedBox(
                width: 50,
                height: 50,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
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
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
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
