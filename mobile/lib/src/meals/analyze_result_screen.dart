import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/models.dart';
import '../auth/session_controller.dart';
import '../format.dart';
import '../widgets/common.dart';

class AnalyzeResultScreen extends StatefulWidget {
  const AnalyzeResultScreen({
    super.key,
    required this.session,
    required this.result,
    this.photoRef,
    this.notes,
  });

  final SessionController session;
  final AnalyzeResult result;
  final String? photoRef;
  final String? notes;

  @override
  State<AnalyzeResultScreen> createState() => _AnalyzeResultScreenState();
}

class _AnalyzeResultScreenState extends State<AnalyzeResultScreen> {
  bool _busy = false;
  String? _error;

  AnalyzeResult get result => widget.result;

  String _fitLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 200) return trimmed;
    return trimmed.substring(0, 200);
  }

  Future<void> _log({required double sugarG, required String label}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    var finished = false;
    try {
      await widget.session.api.logMeal(
        sugarG: sugarG,
        label: _fitLabel(label),
        photoRef: widget.photoRef,
        notes: widget.notes,
      );
      if (!mounted) return;
      finished = true;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted && !finished) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final third = result.suggestion.fractionSugarG['1/3'];
    final half = result.suggestion.fractionSugarG['1/2'];
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: CenteredPanel(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              result.label,
              key: const Key('review-label'),
              style: text.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${formatGrams(result.sugarG)} g',
              key: const Key('review-sugar'),
              style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatConfidence(result.confidence)} catalog match · ${remainingLabel(result.remainingBudgetG)} today',
              style: text.bodyMedium,
            ),
            if (result.wouldExceed) ...[
              const SizedBox(height: 16),
              Container(
                key: const Key('review-exceed'),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'The full portion is over today’s remaining sugar. A smaller portion may fit.',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ],
            const SizedBox(height: 20),
            BusyButton(
              key: const Key('log-full'),
              label: 'Log full · ${formatGrams(result.sugarG)} g',
              busy: _busy,
              onPressed: () => _log(sugarG: result.sugarG, label: result.label),
            ),
            const SizedBox(height: 8),
            BusyButton(
              key: const Key('log-third'),
              label: third == null
                  ? 'Log 1/3'
                  : 'Log 1/3 · ${formatGrams(third)} g',
              busy: _busy,
              outlined: true,
              onPressed: third == null
                  ? null
                  : () => _log(sugarG: third, label: '${result.label} (1/3)'),
            ),
            const SizedBox(height: 8),
            BusyButton(
              key: const Key('log-half'),
              label: half == null
                  ? 'Log 1/2'
                  : 'Log 1/2 · ${formatGrams(half)} g',
              busy: _busy,
              outlined: true,
              onPressed: half == null
                  ? null
                  : () => _log(sugarG: half, label: '${result.label} (1/2)'),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: const Key('cancel-log'),
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              ErrorNote(message: _error),
            ],
            if (result.suggestion.alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Lower-sugar ideas', style: text.titleMedium),
              const SizedBox(height: 8),
              for (final alternative in result.suggestion.alternatives)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(alternative.label)),
                      Text('${formatGrams(alternative.sugarG)} g'),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
