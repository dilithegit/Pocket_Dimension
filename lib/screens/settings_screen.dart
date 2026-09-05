import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_ui_components.dart';
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
      appBar: IlluminatedHeaderBar(
        title: 'Grimoire Configurations',
        subtitle: 'Ethereal Tether & Realm Settings',
        leading: GoldIconButton(
          icon: Icons.arrow_back_rounded,
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

            // Offline / Online Mode Realm Picker Card
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
                                'Realm & Story Engine Mode',
                                style: AppTypography.loreTitle.copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                manager.isOfflineMode ? 'OFFLINE ENGINE ACTIVE' : 'ONLINE API ACTIVE',
                                style: AppTypography.uiCaption.copyWith(
                                  color: manager.isOfflineMode ? AppColors.suspicionLow : AppColors.memoryActive,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    const SizedBox(height: AppSpacing.xs),

                    RadioListTile<OfflineModeType>(
                      title: Text(
                        'Online AI DM Engine (Gemini 3.5 Flash-Lite)',
                        style: AppTypography.loreTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        'Live generative AI DM with SSE streaming and RAG grounding context.',
                        style: AppTypography.uiCaption,
                      ),
                      value: OfflineModeType.online,
                      groupValue: manager.offlineModeType,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        if (val != null) manager.setOfflineModeType(val);
                      },
                    ),
                    RadioListTile<OfflineModeType>(
                      title: Text(
                        'Offline: Pre-Woven Nigerian Sandbox',
                        style: AppTypography.loreTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        'Zero-network sandbox exploring Mythical Surulere, Osogbo Grove, and Olokun Spire.',
                        style: AppTypography.uiCaption,
                      ),
                      value: OfflineModeType.nigerianSandbox,
                      groupValue: manager.offlineModeType,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        if (val != null) manager.setOfflineModeType(val);
                      },
                    ),
                    RadioListTile<OfflineModeType>(
                      title: Text(
                        'Offline: Greek-African Mythic Tale',
                        style: AppTypography.loreTitle.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        'Zero-network authored story graph through Siwa-Amun, Alexandria-Nok, and Atlas-Olokun.',
                        style: AppTypography.uiCaption,
                      ),
                      value: OfflineModeType.greekAfricanFantasy,
                      groupValue: manager.offlineModeType,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        if (val != null) manager.setOfflineModeType(val);
                      },
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
