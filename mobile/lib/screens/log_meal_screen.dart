import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/sugar_api.dart';
import '../format.dart';
import '../theme/tokens.dart';
import '../widgets/surface_card.dart';

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key, required this.api, this.pickPhoto});

  final SugarApi api;
  final Future<MealPhoto?> Function()? pickPhoto;

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final _hint = TextEditingController();
  MealPhoto? _photo;
  AnalyzeResult? _result;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _hint.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = widget.pickPhoto;
    if (picker == null) {
      setState(() => _error = 'Photo library is unavailable. Enter a hint instead.');
      return;
    }
    try {
      final photo = await picker();
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Photo library is unavailable. Enter a hint instead.');
    }
  }

  Future<void> _estimate() async {
    final hint = _hint.text.trim();
    if (hint.isEmpty && _photo == null) {
      setState(() => _error = 'Add a hint or a photo first.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.api.analyze(
        hint: hint.isEmpty ? null : hint,
        image: _photo?.bytes,
        imageName: _photo?.name,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't estimate that meal.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm({String? fraction}) async {
    final result = _result;
    if (result == null || _busy) return;
    final sugar = fraction == null ? result.sugarG : result.fractionSugarG[fraction];
    final kcal = fraction == null ? result.kcal : result.fractionKcal[fraction];
    if (sugar == null || kcal == null) {
      setState(() => _error = 'That portion is missing from the estimate.');
      return;
    }
    final label = fraction == null ? result.label : '$fraction ${result.label}';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.logMeal(
        label: label,
        sugarG: sugar,
        kcal: kcal,
        photoRef: _photo?.name,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't log that meal.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _cancel() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final theme = Theme.of(context);
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Log meal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            key: const Key('hint'),
            controller: _hint,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _estimate(),
            decoration: const InputDecoration(
              labelText: 'Hint',
              hintText: 'cookie, chicken, banana…',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('add-photo'),
            onPressed: _busy ? null : _pickPhoto,
            child: Text(_photo == null ? 'Add photo' : 'Replace photo'),
          ),
          if (_photo != null) ...[
            const SizedBox(height: 12),
            SurfaceCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      Uint8List.fromList(_photo!.bytes),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_photo!.name, key: const Key('photo-name')),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('estimate'),
            onPressed: _busy ? null : _estimate,
            child: Text(_busy && result == null ? 'Estimating…' : 'Estimate'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('log-error'),
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.over),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 24),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.label, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    formatAmount(result.sugarG),
                    key: const Key('sugar-estimate'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text('g sugar', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    formatKcal(result.kcal),
                    key: const Key('kcal-estimate'),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(result.confidence * 100).round()}% match · ${remainingLine(result.remainingBudgetG)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (result.wouldExceed)
              _Notice(
                key: const Key('over-budget'),
                color: palette.over,
                title: 'Over your sugar budget',
                body:
                    '${formatSugar(result.sugarG)} is more than the ${formatSugar(result.remainingBudgetG < 0 ? 0 : result.remainingBudgetG)} left. Calories do not change this limit.',
              )
            else
              _Notice(
                key: const Key('within-budget'),
                color: palette.under,
                title: 'Within your sugar budget',
                body: '${formatSugar(result.sugarG)} fits in the ${formatSugar(result.remainingBudgetG)} left.',
              ),
            if (result.wouldExceed && result.alternatives.isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionLabel('Lower sugar'),
              const SizedBox(height: 8),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < result.alternatives.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: palette.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(result.alternatives[i].label)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatSugar(result.alternatives[i].sugarG)),
                                Text(formatKcal(result.alternatives[i].kcal), style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            _PortionButton(
              buttonKey: const Key('log-full'),
              label: 'Log full',
              sugar: result.sugarG,
              kcal: result.kcal,
              exceeds: wouldExceed(
                sugarG: result.sugarG,
                remainingG: result.remainingBudgetG,
                kcal: result.kcal,
              ),
              filled: true,
              busy: _busy,
              onPressed: () => _confirm(),
            ),
            const SizedBox(height: 8),
            _PortionButton(
              buttonKey: const Key('log-third'),
              label: 'Log 1/3',
              sugar: result.fractionSugarG['1/3'] ?? 0,
              kcal: result.fractionKcal['1/3'] ?? 0,
              exceeds: wouldExceed(
                sugarG: result.fractionSugarG['1/3'] ?? 0,
                remainingG: result.remainingBudgetG,
                kcal: result.fractionKcal['1/3'] ?? 0,
              ),
              busy: _busy,
              onPressed: () => _confirm(fraction: '1/3'),
            ),
            const SizedBox(height: 8),
            _PortionButton(
              buttonKey: const Key('log-half'),
              label: 'Log 1/2',
              sugar: result.fractionSugarG['1/2'] ?? 0,
              kcal: result.fractionKcal['1/2'] ?? 0,
              exceeds: wouldExceed(
                sugarG: result.fractionSugarG['1/2'] ?? 0,
                remainingG: result.remainingBudgetG,
                kcal: result.fractionKcal['1/2'] ?? 0,
              ),
              busy: _busy,
              onPressed: () => _confirm(fraction: '1/2'),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: const Key('cancel-log'),
              onPressed: _busy ? null : _cancel,
              child: const Text('Cancel'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.color,
    required this.title,
    required this.body,
  });

  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PortionButton extends StatelessWidget {
  const _PortionButton({
    required this.buttonKey,
    required this.label,
    required this.sugar,
    required this.kcal,
    required this.exceeds,
    required this.busy,
    required this.onPressed,
    this.filled = false,
  });

  final Key buttonKey;
  final String label;
  final double sugar;
  final double kcal;
  final bool exceeds;
  final bool busy;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final text = '$label · ${formatSugar(sugar)} · ${formatKcal(kcal)}';
    final overStyle = OutlinedButton.styleFrom(
      foregroundColor: palette.over,
      side: BorderSide(color: palette.over),
    );
    if (filled && !exceeds) {
      return FilledButton(
        key: buttonKey,
        onPressed: busy ? null : onPressed,
        child: Text(text),
      );
    }
    return OutlinedButton(
      key: buttonKey,
      style: exceeds ? overStyle : null,
      onPressed: busy ? null : onPressed,
      child: Text(text),
    );
  }
}
