import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../models/save_slot.dart';
import '../models/game_state.dart';
import '../database/save_slot_repository.dart';
import '../state/game_state_manager.dart';

/// Step 9 Implementation — Save/Load Slot UI:
/// - True entry point of the application.
/// - Illustrated save slot cards showing World Name (serif), Character Name & Guise (sans),
///   neatly formatted timestamp, and a mood-color swatch derived from the world theme.
/// - Load (resume realm) and Delete CRUD actions.
/// - Beautiful empty state ("The void is empty. Awaken a new realm.") pointing to World Weaver.
class SaveSlotsScreen extends StatefulWidget {
  final VoidCallback onNewAdventure;
  final VoidCallback onSlotLoaded;
  final VoidCallback? onOpenSettings;

  const SaveSlotsScreen({
    super.key,
    required this.onNewAdventure,
    required this.onSlotLoaded,
    this.onOpenSettings,
  });

  @override
  State<SaveSlotsScreen> createState() => _SaveSlotsScreenState();
}

class _SaveSlotsScreenState extends State<SaveSlotsScreen> {
  final SaveSlotRepository _repository = SaveSlotRepository();
  List<SaveSlot> _slots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);
    try {
      List<SaveSlot> loaded = await _repository.getAllSaveSlots();
      setState(() {
        _slots = loaded;
      });
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLoadSlot(SaveSlot slot) async {
    final manager = context.read<GameStateManager>();
    manager.loadFromSlot(slot);
    widget.onSlotLoaded();
  }

  Future<void> _handleDeleteSlot(SaveSlot slot) async {
    if (slot.id == null) return;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Unweave Realm?', style: AppTypography.uiHeader),
        content: Text(
          'Are you sure you wish to delete "${slot.slotName}"? This action cannot be undone.',
          style: AppTypography.uiBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: AppTypography.uiBody),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.suspicionHigh),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: AppTypography.uiBody),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.deleteSaveSlot(slot.id!);
      await _loadSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pocket Dimension — Saved Realms', style: AppTypography.uiHeader),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.accent),
            onPressed: () {
              if (widget.onOpenSettings != null) {
                widget.onOpenSettings!();
              }
            },
            tooltip: 'Grimoire Configurations',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSlots,
            tooltip: 'Refresh Save Slots',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _slots.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _slots.length,
                  itemBuilder: (context, index) {
                    SaveSlot slot = _slots[index];
                    return _buildIllustratedSaveCard(slot);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        onPressed: widget.onNewAdventure,
        icon: const Icon(Icons.auto_awesome),
        label: Text(
          'Weave New World',
          style: AppTypography.uiHeader.copyWith(
            color: AppColors.background,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Empty state matching illustrated parchment design
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF2D1418), // Oxblood accent
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 56,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'The void is empty.',
              style: AppTypography.narrationDisplay,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Awaken a new realm as an unmanifested deity walking among mortals.',
              style: AppTypography.narrationBody.copyWith(color: AppColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
              onPressed: widget.onNewAdventure,
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                'Weave a New World',
                style: AppTypography.uiHeader.copyWith(
                  color: AppColors.background,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Illustrated Card for each Save Slot
  Widget _buildIllustratedSaveCard(SaveSlot slot) {
    GameState? state;
    try {
      state = slot.toGameState();
    } catch (_) {}

    String worldName = slot.slotName.replaceFirst('World: ', '');
    String charName = state?.character.name ?? 'Nameless Deity';
    String charGuise = state?.character.origin ?? 'Unmapped Guise';
    String location = slot.currentLocation;

    // Mood-color swatch derived from realm location / archetype
    Color moodColor = _getMoodColor(location);

    // Neatly formatted timestamp
    DateTime dt = slot.lastPlayed;
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String monthName = months[dt.month - 1];
    String formattedDate =
        '$monthName ${dt.day}, ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: moodColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Illustrated Banner with Mood Swatch Gradient
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    moodColor.withValues(alpha: 0.35),
                    AppColors.surfaceElevated,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: moodColor.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: moodColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: moodColor.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      worldName,
                      style: AppTypography.narrationDisplay.copyWith(
                        fontSize: 18,
                        color: AppColors.inkPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.suspicionHigh),
                    onPressed: () => _handleDeleteSlot(slot),
                    tooltip: 'Delete Save Slot',
                  ),
                ],
              ),
            ),

            // Card Body Details
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Character Name & Physical Guise (Sans Face)
                  Row(
                    children: [
                      const Icon(Icons.masks_outlined, size: 16, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '$charName — $charGuise',
                          style: AppTypography.uiBody.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Location Tag
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: AppColors.inkSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Location: $location',
                        style: AppTypography.uiCaption.copyWith(color: AppColors.inkSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Footer: Timestamp & Resume Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: AppTypography.uiCaption.copyWith(fontSize: 11),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: moodColor.withValues(alpha: 0.2),
                          foregroundColor: AppColors.accent,
                          side: BorderSide(color: moodColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        onPressed: () => _handleLoadSlot(slot),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Resume Realm', style: AppTypography.uiBody),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Derive mood-color swatch from location / world concept
  Color _getMoodColor(String location) {
    String loc = location.toLowerCase();
    if (loc.contains('sun') || loc.contains('kemet') || loc.contains('gold')) {
      return const Color(0xFFFFB74D); // Amber Gold
    } else if (loc.contains('sea') || loc.contains('coast') || loc.contains('haven')) {
      return const Color(0xFF26A69A); // Coastal Teal
    } else if (loc.contains('empire') || loc.contains('citadel') || loc.contains('ruin')) {
      return const Color(0xFFE57373); // Crimson Oxblood
    } else if (loc.contains('void') || loc.contains('nexus') || loc.contains('starlight')) {
      return const Color(0xFF7E57C2); // Deep Indigo
    }
    return AppColors.accent;
  }
}
