import 'package:flutter/material.dart';

import '../api/sugar_api.dart';
import '../format.dart';
import '../state/app_model.dart';
import '../theme/tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.model});

  final AppModel model;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _presets = <double>[10, 15, 25, 36, 50];

  double _selected = 15;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = widget.model.user?.dailySugarLimitG;
    if (current != null && _presets.contains(round2(current))) {
      _selected = round2(current);
    }
  }

  Future<void> _continue() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.model.finishOnboarding(_selected);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't save the limit.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              children: [
                Text('Set your daily limit',
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Sugar is the only limit. 15 g matches the demo account. You can change this later.',
                  style:
                      theme.textTheme.bodyLarge?.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 28),
                for (final grams in _presets) ...[
                  _Preset(
                    grams: grams,
                    selected: _selected == grams,
                    busy: _busy,
                    onTap: () => setState(() => _selected = grams),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    key: const Key('onboarding-error'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: palette.over),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('onboarding-continue'),
                  onPressed: _busy ? null : _continue,
                  child: Text(_busy ? 'Saving…' : 'Continue'),
                ),
                TextButton(
                  key: const Key('onboarding-sign-out'),
                  onPressed: _busy ? null : widget.model.logout,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  const _Preset({
    required this.grams,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final double grams;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Material(
      color: selected ? palette.lime : palette.surface,
      borderRadius: BorderRadius.circular(22),
      elevation: 1,
      shadowColor: const Color(0x14000000),
      child: InkWell(
        key: Key('onboarding-${grams.toInt()}'),
        borderRadius: BorderRadius.circular(22),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(formatSugar(grams),
              style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}
