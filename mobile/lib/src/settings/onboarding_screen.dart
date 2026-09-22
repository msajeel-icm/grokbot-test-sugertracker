import 'package:flutter/material.dart';

import '../auth/session_controller.dart';
import '../widgets/common.dart';
import 'limit_editor.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final limit = session.user?.dailySugarLimitG ?? 15;
    return Scaffold(
      body: SafeArea(
        child: CenteredPanel(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Set your daily limit', style: text.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Choose a daily added-sugar budget. 15 g matches the demo account. You can change this later.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: 24),
              LimitEditor(
                initialGrams: limit,
                submitLabel: 'Continue',
                onSave: session.saveLimit,
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('onboarding-sign-out'),
                onPressed: session.logout,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
