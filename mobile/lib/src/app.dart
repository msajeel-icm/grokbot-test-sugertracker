import 'package:flutter/material.dart';

import 'auth/login_screen.dart';
import 'auth/session_controller.dart';
import 'dashboard/dashboard_screen.dart';
import 'settings/onboarding_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

class SugarTrackerApp extends StatefulWidget {
  const SugarTrackerApp({
    super.key,
    required this.session,
    required this.apiBaseUrl,
  });

  final SessionController session;
  final String apiBaseUrl;

  @override
  State<SugarTrackerApp> createState() => _SugarTrackerAppState();
}

class _SugarTrackerAppState extends State<SugarTrackerApp> {
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
    widget.session.bootstrap();
  }

  @override
  void didUpdateWidget(covariant SugarTrackerApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session == widget.session) return;
    oldWidget.session.removeListener(_onSession);
    widget.session.addListener(_onSession);
    widget.session.bootstrap();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  String _shellKey(SessionController session) {
    return switch (session.phase) {
      SessionPhase.loading => 'loading',
      SessionPhase.failure => 'failure',
      SessionPhase.signedOut => 'signed-out',
      SessionPhase.signedIn when session.needsOnboarding => 'onboarding',
      SessionPhase.signedIn => 'home',
    };
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return MaterialApp(
      key: ValueKey(_shellKey(session)),
      title: 'Sugar Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildSugarTheme(),
      home: switch (session.phase) {
        SessionPhase.loading => const _Splash(),
        SessionPhase.failure => _Failure(
          message: session.errorMessage ?? 'Could not restore your session.',
          onRetry: session.bootstrap,
        ),
        SessionPhase.signedOut => _AuthFlow(
          session: session,
          apiBaseUrl: widget.apiBaseUrl,
        ),
        SessionPhase.signedIn when session.needsOnboarding => OnboardingScreen(
          session: session,
        ),
        SessionPhase.signedIn => _HomeFlow(session: session),
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop, color: sugarGreen, size: 40),
            SizedBox(height: 12),
            Text('Sugar Tracker'),
            SizedBox(height: 16),
            CircularProgressIndicator(key: Key('splash')),
          ],
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ErrorNote(message: message),
              const SizedBox(height: 16),
              BusyButton(
                key: const Key('bootstrap-retry'),
                label: 'Try again',
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthFlow extends StatelessWidget {
  const _AuthFlow({required this.session, required this.apiBaseUrl});

  final SessionController session;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => LoginScreen(session: session, apiBaseUrl: apiBaseUrl),
        );
      },
    );
  }
}

class _HomeFlow extends StatelessWidget {
  const _HomeFlow({required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => DashboardScreen(session: session),
        );
      },
    );
  }
}
