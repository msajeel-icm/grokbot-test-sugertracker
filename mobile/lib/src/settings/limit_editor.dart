import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_exception.dart';
import '../format.dart';
import '../widgets/common.dart';

enum LimitChoice { g12, g15, custom }

class LimitEditor extends StatefulWidget {
  const LimitEditor({
    super.key,
    required this.initialGrams,
    required this.onSave,
    this.submitLabel = 'Save limit',
  });

  final double initialGrams;
  final Future<void> Function(double grams) onSave;
  final String submitLabel;

  @override
  State<LimitEditor> createState() => _LimitEditorState();
}

class _LimitEditorState extends State<LimitEditor> {
  late LimitChoice _choice;
  final _custom = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialGrams;
    if ((initial - 12).abs() < 0.001) {
      _choice = LimitChoice.g12;
    } else if ((initial - 15).abs() < 0.001) {
      _choice = LimitChoice.g15;
    } else {
      _choice = LimitChoice.custom;
      _custom.text = formatGrams(initial);
    }
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  double? _grams() {
    switch (_choice) {
      case LimitChoice.g12:
        return 12;
      case LimitChoice.g15:
        return 15;
      case LimitChoice.custom:
        final parsed = double.tryParse(
          _custom.text.trim().replaceAll(',', '.'),
        );
        if (parsed == null || parsed < 0 || parsed > 1000) return null;
        return parsed;
    }
  }

  Future<void> _submit() async {
    final grams = _grams();
    if (grams == null) {
      setState(() => _error = 'Enter a limit between 0 and 1000 grams.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(grams);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not save your limit.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const Key('preset-12'),
              label: const Text('12 g'),
              selected: _choice == LimitChoice.g12,
              onSelected: _saving
                  ? null
                  : (_) => setState(() => _choice = LimitChoice.g12),
            ),
            ChoiceChip(
              key: const Key('preset-15'),
              label: const Text('15 g'),
              selected: _choice == LimitChoice.g15,
              onSelected: _saving
                  ? null
                  : (_) => setState(() => _choice = LimitChoice.g15),
            ),
            ChoiceChip(
              key: const Key('preset-custom'),
              label: const Text('Custom'),
              selected: _choice == LimitChoice.custom,
              onSelected: _saving
                  ? null
                  : (_) => setState(() => _choice = LimitChoice.custom),
            ),
          ],
        ),
        if (_choice == LimitChoice.custom) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('custom-limit'),
            controller: _custom,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Grams per day',
              suffixText: 'g',
            ),
          ),
        ],
        const SizedBox(height: 16),
        ErrorNote(message: _error),
        if (_error != null) const SizedBox(height: 16),
        BusyButton(
          key: const Key('save-limit'),
          label: widget.submitLabel,
          busy: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}
