import 'package:flutter/material.dart';
import '../screens/save_slots_screen.dart';
import '../screens/world_weaver_screen.dart';
import '../screens/character_creation_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/settings_screen.dart';

enum AppScreenRoute {
  saveSlots,
  worldWeaver,
  characterCreation,
  chatScreen,
  settings,
}

/// AppRouter manages explicit state-based navigation across the dedicated screens.
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  AppScreenRoute _currentRoute = AppScreenRoute.saveSlots;

  void _navigateTo(AppScreenRoute route) {
    setState(() {
      _currentRoute = route;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;
    switch (_currentRoute) {
      case AppScreenRoute.saveSlots:
        activeScreen = SaveSlotsScreen(
          key: const ValueKey('saveSlots'),
          onNewAdventure: () => _navigateTo(AppScreenRoute.worldWeaver),
          onSlotLoaded: () => _navigateTo(AppScreenRoute.chatScreen),
          onOpenSettings: () => _navigateTo(AppScreenRoute.settings),
        );
        break;

      case AppScreenRoute.worldWeaver:
        activeScreen = WorldWeaverScreen(
          key: const ValueKey('worldWeaver'),
          onWorldAccepted: () => _navigateTo(AppScreenRoute.characterCreation),
        );
        break;

      case AppScreenRoute.characterCreation:
        activeScreen = CharacterCreationScreen(
          key: const ValueKey('characterCreation'),
          onCharacterCreated: () => _navigateTo(AppScreenRoute.chatScreen),
        );
        break;

      case AppScreenRoute.chatScreen:
        activeScreen = ChatScreen(
          key: const ValueKey('chatScreen'),
          onReturnToSaves: () => _navigateTo(AppScreenRoute.saveSlots),
        );
        break;

      case AppScreenRoute.settings:
        activeScreen = SettingsScreen(
          key: const ValueKey('settings'),
          onBack: () => _navigateTo(AppScreenRoute.saveSlots),
        );
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.04, 0.0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: activeScreen,
    );
  }
}
