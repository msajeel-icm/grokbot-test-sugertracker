import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../auth/session_controller.dart';
import '../widgets/common.dart';
import 'limit_editor.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _timezone;
  bool _savingTimezone = false;
  String? _timezoneError;

  @override
  void initState() {
    super.initState();
    _timezone = TextEditingController(
      text: widget.session.user?.timezone ?? 'UTC',
    );
  }

  @override
  void dispose() {
    _timezone.dispose();
    super.dispose();
  }

  Future<void> _saveLimit(double grams) async {
    await widget.session.saveLimit(grams);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Daily limit saved')));
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
      await widget.session.updateTimezone(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Timezone saved')));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _timezoneError = error.message);
    } finally {
      if (mounted) setState(() => _savingTimezone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = widget.session.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: CenteredPanel(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(user?.email ?? '', style: text.titleMedium),
            const SizedBox(height: 20),
            Text('Daily sugar limit', style: text.titleMedium),
            const SizedBox(height: 8),
            LimitEditor(
              initialGrams: user?.dailySugarLimitG ?? 15,
              onSave: _saveLimit,
            ),
            const SizedBox(height: 28),
            Text('Timezone', style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Today’s dashboard uses this IANA timezone.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('timezone-field'),
              controller: _timezone,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                hintText: 'UTC',
              ),
            ),
            const SizedBox(height: 12),
            ErrorNote(message: _timezoneError),
            if (_timezoneError != null) const SizedBox(height: 12),
            BusyButton(
              key: const Key('save-timezone'),
              label: 'Save timezone',
              busy: _savingTimezone,
              outlined: true,
              onPressed: _saveTimezone,
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              key: const Key('logout'),
              onPressed: widget.session.logout,
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
