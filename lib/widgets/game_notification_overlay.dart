import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Floating in-game notification item payload.
class GameNotification {
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;

  const GameNotification({
    required this.title,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.accentColor = AppColors.accent,
  });
}

/// Overlay controller allowing global trigger of non-blocking 3-second animated banners.
class GameNotificationOverlay extends StatefulWidget {
  final Widget child;

  const GameNotificationOverlay({
    super.key,
    required this.child,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    Color accentColor = AppColors.accent,
  }) {
    final state = context.findAncestorStateOfType<_GameNotificationOverlayState>();
    state?.triggerNotification(
      GameNotification(
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<GameNotificationOverlay> createState() => _GameNotificationOverlayState();
}

class _GameNotificationOverlayState extends State<GameNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  GameNotification? _currentNotification;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void triggerNotification(GameNotification notification) {
    _dismissTimer?.cancel();
    setState(() {
      _currentNotification = notification;
    });

    _animController.forward(from: 0.0);

    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                color: Colors.transparent,
                elevation: 6,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1418), // Oxblood parchment
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: _currentNotification!.accentColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: _currentNotification!.accentColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _currentNotification!.icon,
                          color: _currentNotification!.accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentNotification!.title,
                              style: AppTypography.loreTitle.copyWith(
                                fontSize: 14,
                                color: _currentNotification!.accentColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentNotification!.message,
                              style: AppTypography.uiBody.copyWith(
                                fontSize: 12,
                                color: AppColors.inkPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
