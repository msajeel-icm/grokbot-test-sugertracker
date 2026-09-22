import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../widgets/common.dart';
import 'register_screen.dart';
import 'session_controller.dart';
import 'validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.session,
    required this.apiBaseUrl,
  });

  final SessionController session;
  final String apiBaseUrl;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final passwordError = validateLoginPassword(_password.text);
    if (emailError != null || passwordError != null) {
      setState(() => _error = emailError ?? passwordError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.login(
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
      body: SafeArea(
        child: CenteredPanel(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              const Icon(Icons.water_drop, color: Color(0xFF1F6B4A), size: 36),
              const SizedBox(height: 16),
              Text('Sugar Tracker', style: text.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'See today’s sugar against your limit.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 28),
              TextField(
                key: const Key('login-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('login-password'),
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
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
                key: const Key('login-submit'),
                label: 'Sign in',
                busy: _busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('go-register'),
                onPressed: _busy
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RegisterScreen(
                              session: widget.session,
                              apiBaseUrl: widget.apiBaseUrl,
                            ),
                          ),
                        );
                      },
                child: const Text('Create an account'),
              ),
              const SizedBox(height: 12),
              Text('Demo: demo@sugar.app / demo1234', style: text.bodySmall),
              const SizedBox(height: 4),
              Text(
                'API ${widget.apiBaseUrl}',
                key: const Key('api-base-url'),
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
