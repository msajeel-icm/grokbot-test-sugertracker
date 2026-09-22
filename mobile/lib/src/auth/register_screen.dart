import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../widgets/common.dart';
import 'session_controller.dart';
import 'validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.session,
    required this.apiBaseUrl,
  });

  final SessionController session;
  final String apiBaseUrl;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailError = validateEmail(_email.text);
    final passwordError = validateNewPassword(_password.text);
    if (emailError != null || passwordError != null) {
      setState(() => _error = emailError ?? passwordError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.register(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not save your session on this device.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: CenteredPanel(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Text(
              'A new account starts at 15 g. You’ll pick a limit next.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('register-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('register-password'),
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ErrorNote(message: _error),
            if (_error != null) const SizedBox(height: 16),
            BusyButton(
              key: const Key('register-submit'),
              label: 'Create account',
              busy: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('go-login'),
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Already have an account'),
            ),
            const SizedBox(height: 8),
            Text('API ${widget.apiBaseUrl}', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
