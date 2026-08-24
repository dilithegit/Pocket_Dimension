import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../state/game_state_manager.dart';

/// SettingsScreen — Immersive Grimoire Configurations page.
class SettingsScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const SettingsScreen({
    super.key,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameStateManager>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Grimoire Configurations', style: AppTypography.uiHeader),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ethereal Configuration',
              style: AppTypography.narrationDisplay,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Manage your tether to the online AI DM Engine or activate local pre-woven mythology realms.',
              style: AppTypography.narrationBody,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Offline Mode: Pre-Woven Nigerian Realm Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline Mode: Pre-Woven Nigerian Realm',
                                style: AppTypography.loreTitle.copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                manager.isOfflineMode ? 'ACTIVE (Local Engine)' : 'INACTIVE (Online API)',
                                style: AppTypography.uiCaption.copyWith(
                                  color: manager.isOfflineMode ? AppColors.suspicionLow : AppColors.inkMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: manager.isOfflineMode,
                          activeThumbColor: AppColors.accent,
                          onChanged: (value) {
                            manager.setOfflineMode(value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'When active, World Weaver generation bypasses live Gemini network calls and loads the pre-configured Nigerian Mythology dataset (Mythical Surulere, Sacred Osogbo Grove, Olokun Spire, & Orisha Lore Keepers). Player inputs will trigger a local branching narrative engine.',
                      style: AppTypography.uiBody.copyWith(
                        fontSize: 13,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Network Credentials Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API Credentials & Key Hygiene', style: AppTypography.uiHeader),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'API keys are passed via compile-time --dart-define=GEMINI_API_KEY="...". Never commit raw API keys to source control.',
                      style: AppTypography.uiCaption,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
