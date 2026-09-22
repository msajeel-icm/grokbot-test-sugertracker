import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/models.dart';
import '../auth/session_controller.dart';
import '../widgets/common.dart';
import 'analyze_result_screen.dart';
import 'photo_picker.dart';

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key, required this.session, this.pickPhoto});

  final SessionController session;

  /// When null, the gallery picker is used. Tests inject a fake.
  final Future<MealPhoto?> Function()? pickPhoto;

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final _hint = TextEditingController();
  MealPhoto? _photo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _hint.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    setState(() => _error = null);
    try {
      final picker = widget.pickPhoto ?? pickMealPhoto;
      final photo = await picker();
      if (!mounted) return;
      if (photo != null && photo.bytes.isEmpty) {
        setState(() => _error = 'That photo was empty.');
        return;
      }
      if (photo != null && photo.bytes.length > 8 * 1024 * 1024) {
        setState(() => _error = 'That photo is larger than 8 MB.');
        return;
      }
      setState(() => _photo = photo);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not open your photos.');
    }
  }

  String? _photoRef() {
    final path = _photo?.path?.trim();
    if (path == null || path.isEmpty || path.length > 1024) return null;
    return path;
  }

  Future<void> _estimate() async {
    final hint = _hint.text.trim();
    if (hint.isEmpty && _photo == null) {
      setState(() => _error = 'Add a photo or describe the meal.');
      return;
    }
    if (hint.length > 200) {
      setState(() => _error = 'Keep the description under 200 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    var left = false;
    try {
      final result = await widget.session.api.analyzeMeal(
        hint: hint.isEmpty ? null : hint,
        photo: _photo,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      final logged = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AnalyzeResultScreen(
            session: widget.session,
            result: result,
            photoRef: _photoRef(),
            notes: hint.isEmpty ? null : hint,
          ),
        ),
      );
      if (!mounted) return;
      if (logged == true) {
        left = true;
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted && !left) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Log meal')),
      body: CenteredPanel(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              'Add a photo, a short description, or both. This asks the server for an estimate and does not log anything yet.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('meal-hint'),
              controller: _hint,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'What did you eat?',
                hintText: 'chocolate chip cookie',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('pick-photo'),
              onPressed: _busy ? null : _choosePhoto,
              icon: const Icon(Icons.photo_outlined),
              label: Text(_photo == null ? 'Choose photo' : 'Replace photo'),
            ),
            if (_photo != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _photo!.bytes,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 80,
                    alignment: Alignment.center,
                    color: Colors.white,
                    child: const Text('Photo attached'),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(_photo!.filename, key: const Key('photo-name')),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('remove-photo'),
                  onPressed: _busy ? null : () => setState(() => _photo = null),
                  child: const Text('Remove photo'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ErrorNote(message: _error),
            if (_error != null) const SizedBox(height: 12),
            BusyButton(
              key: const Key('analyze'),
              label: 'Estimate sugar',
              busy: _busy,
              onPressed: _estimate,
            ),
          ],
        ),
      ),
    );
  }
}
