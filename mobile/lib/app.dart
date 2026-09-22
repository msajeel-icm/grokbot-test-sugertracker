import 'package:flutter/material.dart';

import 'api/models.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'state/app_model.dart';
import 'theme/app_theme.dart';

class SugarTrackerApp extends StatefulWidget {
  const SugarTrackerApp({super.key, required this.model, this.pickPhoto});

  final AppModel model;
  final Future<MealPhoto?> Function()? pickPhoto;

  @override
  State<SugarTrackerApp> createState() => _SugarTrackerAppState();
}

class _SugarTrackerAppState extends State<SugarTrackerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return ListenableBuilder(
      listenable: model,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Sugar',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: model.themeMode,
          home: child,
        );
      },
      child: _Root(model: model, pickPhoto: widget.pickPhoto),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root({required this.model, this.pickPhoto});

  final AppModel model;
  final Future<MealPhoto?> Function()? pickPhoto;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        if (!model.ready) return const _BootScreen();
        if (model.user == null) return LoginScreen(model: model);
        return HomeScreen(model: model, pickPhoto: pickPhoto);
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Sugar')),
    );
  }
}
