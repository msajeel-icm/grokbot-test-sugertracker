import 'package:flutter/material.dart';

import '../api/sugar_api.dart';
import '../format.dart';
import '../state/app_model.dart';
import '../theme/tokens.dart';
import '../widgets/surface_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.model});

  final AppModel model;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  String? _error;

  static const _presets = <(double, String)>[
    (10, 'Tight'),
    (15, 'Default'),
    (25, 'WHO added sugar'),
    (36, 'Higher'),
    (50, 'Loose'),
  ];

  Future<void> _setLimit(double grams) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.model.setLimit(grams);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't update the limit.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final palette = Palette.of(context);
    final theme = Theme.of(context);
    final selected = model.user?.dailySugarLimitG;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const SectionLabel('Daily sugar limit'),
          const SizedBox(height: 8),
          for (final preset in _presets) ...[
            _LimitRow(
              grams: preset.$1,
              caption: preset.$2,
              selected: selected != null && round2(selected) == preset.$1,
              busy: _busy,
              onTap: () => _setLimit(preset.$1),
            ),
            const SizedBox(height: 8),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                key: const Key('settings-error'),
                style: theme.textTheme.bodyMedium?.copyWith(color: palette.over),
              ),
            ),
          const SizedBox(height: 16),
          const SectionLabel('Appearance'),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Row(
                children: [
                  _ThemeChoice(model: model, mode: ThemeMode.system, label: 'System', buttonKey: const Key('theme-system')),
                  _ThemeChoice(model: model, mode: ThemeMode.light, label: 'Light', buttonKey: const Key('theme-light')),
                  _ThemeChoice(model: model, mode: ThemeMode.dark, label: 'Dark', buttonKey: const Key('theme-dark')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionLabel('Account'),
          const SizedBox(height: 8),
          Text(model.user?.email ?? '', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('sign-out'),
            onPressed: () async {
              await model.logout();
              if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.grams,
    required this.caption,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final double grams;
  final String caption;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final theme = Theme.of(context);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: Key('preset-${grams.toInt()}'),
        borderRadius: BorderRadius.circular(10),
        onTap: busy ? null : onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? palette.text : palette.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatSugar(grams), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(caption, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check, size: 18, color: palette.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.model,
    required this.mode,
    required this.label,
    required this.buttonKey,
  });

  final AppModel model;
  final ThemeMode mode;
  final String label;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final selected = model.themeMode == mode;
    return Expanded(
      child: InkWell(
        key: buttonKey,
        onTap: () => model.setTheme(mode),
        child: ColoredBox(
          color: selected ? palette.text : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? palette.background : palette.text,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
