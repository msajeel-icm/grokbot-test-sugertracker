import 'package:flutter/material.dart';

import '../api/sugar_api.dart';
import '../format.dart';
import '../state/app_model.dart';
import '../theme/tokens.dart';
import '../widgets/progress_ring.dart';
import '../widgets/surface_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.model});

  final AppModel model;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _timezone;
  bool _busy = false;
  bool _savingTimezone = false;
  String? _error;
  String? _timezoneError;

  @override
  void initState() {
    super.initState();
    _timezone =
        TextEditingController(text: widget.model.user?.timezone ?? 'UTC');
  }

  @override
  void dispose() {
    _timezone.dispose();
    super.dispose();
  }

  Future<void> _saveTimezone() async {
    final value = _timezone.text.trim();
    if (value.isEmpty) {
      setState(() => _timezoneError = 'Enter an IANA timezone, such as UTC.');
      return;
    }
    setState(() {
      _savingTimezone = true;
      _timezoneError = null;
    });
    try {
      await widget.model.setTimezone(value);
    } on ApiException catch (error) {
      if (mounted) setState(() => _timezoneError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _timezoneError = "Couldn't update the timezone.");
      }
    } finally {
      if (mounted) setState(() => _savingTimezone = false);
    }
  }

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
      appBar: AppBar(title: const Text('Adjust Goals')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sugar goal', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        selected == null ? '—' : formatSugar(selected),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'This limit gates the day. kcal does not.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ProgressRing(
                    value: selected == null ? 0 : 0.78,
                    color: palette.lime,
                    size: 68),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: palette.over),
              ),
            ),
          const SizedBox(height: 16),
          const SectionLabel('Appearance'),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Row(
                children: [
                  _ThemeChoice(
                      model: model,
                      mode: ThemeMode.system,
                      label: 'System',
                      buttonKey: const Key('theme-system')),
                  _ThemeChoice(
                      model: model,
                      mode: ThemeMode.light,
                      label: 'Light',
                      buttonKey: const Key('theme-light')),
                  _ThemeChoice(
                      model: model,
                      mode: ThemeMode.dark,
                      label: 'Dark',
                      buttonKey: const Key('theme-dark')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SectionLabel('Timezone'),
          const SizedBox(height: 8),
          Text(
            'Today’s dashboard uses this IANA timezone.',
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('timezone-field'),
            controller: _timezone,
            autocorrect: false,
            decoration:
                const InputDecoration(labelText: 'Timezone', hintText: 'UTC'),
          ),
          if (_timezoneError != null) ...[
            const SizedBox(height: 8),
            Text(
              _timezoneError!,
              key: const Key('timezone-error'),
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.over),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('save-timezone'),
            onPressed: _savingTimezone ? null : _saveTimezone,
            child: Text(_savingTimezone ? 'Saving…' : 'Save timezone'),
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
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
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
      color: selected ? palette.lime : palette.surface,
      borderRadius: BorderRadius.circular(22),
      elevation: selected ? 0 : 1,
      shadowColor: const Color(0x14000000),
      child: InkWell(
        key: Key('preset-${grams.toInt()}'),
        borderRadius: BorderRadius.circular(22),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatSugar(grams),
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(caption, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (selected)
                ProgressRing(
                    value: 0.78, color: palette.text, size: 36, stroke: 4)
              else
                Icon(Icons.chevron_right_rounded, color: palette.muted),
            ],
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
