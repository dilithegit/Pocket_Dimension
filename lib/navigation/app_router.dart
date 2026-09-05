import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );

          final goldFlickerAnimation = TweenSequence<double>([
            TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.20), weight: 40),
            TweenSequenceItem(tween: Tween<double>(begin: 0.20, end: 0.0), weight: 60),
          ]).animate(animation);

          return Stack(
            children: [
              FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
              AnimatedBuilder(
                animation: goldFlickerAnimation,
                builder: (context, _) {
                  if (goldFlickerAnimation.value <= 0.005) return const SizedBox.shrink();
                  return IgnorePointer(
                    child: Container(
                      color: AppColors.accent.withValues(alpha: goldFlickerAnimation.value),
                    ),
                  );
                },
              ),
            ],
          );
        },
        child: activeScreen,
      ),
    );
  }
}
