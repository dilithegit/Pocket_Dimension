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
  final List<AppScreenRoute> _screenStack = [AppScreenRoute.saveSlots];

  void _navigateTo(AppScreenRoute route) {
    setState(() {
      if (_screenStack.isEmpty || _screenStack.last != route) {
        _screenStack.add(route);
      }
    });
  }

  void _resetToSaves() {
    setState(() {
      _screenStack.clear();
      _screenStack.add(AppScreenRoute.saveSlots);
    });
  }

  void _handlePop() {
    if (_screenStack.length > 1) {
      setState(() {
        _screenStack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute =
        _screenStack.isNotEmpty ? _screenStack.last : AppScreenRoute.saveSlots;
    final bool canPop = _screenStack.length <= 1;

    Widget activeScreen;
    switch (currentRoute) {
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
          onReturnToSaves: _resetToSaves,
        );
        break;

      case AppScreenRoute.settings:
        activeScreen = SettingsScreen(
          key: const ValueKey('settings'),
          onBack: _handlePop,
        );
        break;
    }

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: AnimatedSwitcher(
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
      ),
    );
  }
}
