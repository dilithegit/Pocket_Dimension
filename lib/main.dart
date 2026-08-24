import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/game_state_manager.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider<GameStateManager>(
      create: (_) => GameStateManager(),
      child: const PocketDimensionApp(),
    ),
  );
}

class PocketDimensionApp extends StatelessWidget {
  const PocketDimensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Dimension',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppRouter(),
    );
  }
}
