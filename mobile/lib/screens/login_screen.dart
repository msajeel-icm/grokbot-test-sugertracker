import 'package:flutter/material.dart';

import '../api/sugar_api.dart';
import '../auth/validators.dart';
import '../state/app_model.dart';
import '../theme/tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.model});

  final AppModel model;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (_creating) {
      final problem = validateEmail(email) ?? validateNewPassword(password);
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
    } else if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_creating) {
        await widget.model.register(email, password);
      } else {
        await widget.model.login(email, password);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = "Can't reach the server.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _creating = !_creating;
      _error = null;
    });
  }

  void _useDemo() {
    _email.text = 'demo@sugar.app';
    _password.text = 'demo1234';
    setState(() => _error = null);
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
                Text('Sugar', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'A daily sugar limit, with calories kept in the background.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 32),
                TextField(
                  key: Key(_creating ? 'register-email' : 'email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'demo@sugar.app',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: Key(_creating ? 'register-password' : 'password'),
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: Key(_creating ? 'register-submit' : 'sign-in'),
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy
                        ? (_creating ? 'Creating account…' : 'Signing in…')
                        : (_creating ? 'Create account' : 'Sign in'),
                  ),
                ),
                if (!_creating) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    key: const Key('use-demo'),
                    onPressed: _busy ? null : _useDemo,
                    child: const Text('Use demo account'),
                  ),
                ],
                const SizedBox(height: 4),
                TextButton(
                  key: Key(_creating ? 'go-sign-in' : 'go-register'),
                  onPressed: _busy ? null : _toggleMode,
                  child: Text(_creating ? 'Already have an account' : 'Create account'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    key: Key(_creating ? 'register-error' : 'login-error'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: palette.over),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  'Demo  demo@sugar.app  ·  demo1234',
                  style: theme.textTheme.bodySmall,
                ),
                if (widget.model.apiBaseUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.model.apiBaseUrl,
                    key: const Key('api-base-url'),
                    style: theme.textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
