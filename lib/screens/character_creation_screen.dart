import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../models/character.dart';
import '../models/state_delta.dart';
import '../network/gemini_client.dart';
import '../state/game_state_manager.dart';
import '../widgets/custom_ui_components.dart';

/// Character Creation Screen — God-Mode setup collecting character name, physical/conceptual guise (origin),
/// and starting inventory items. Zero HP, zero Mana, and zero traditional failure metrics.
class CharacterCreationScreen extends StatefulWidget {
  final VoidCallback onCharacterCreated;

  const CharacterCreationScreen({
    super.key,
    required this.onCharacterCreated,
  });

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: 'The Omnipotent Architect');
  final TextEditingController _originController =
      TextEditingController(text: 'Disguised as an itinerant memory scholar');
  final TextEditingController _itemController = TextEditingController();

  final List<InventoryItem> _startingItems = [
    const InventoryItem(id: 'item_1', name: 'Chronicle of Lost Songs', qty: 1),
    const InventoryItem(id: 'item_2', name: 'Aether-Infused Ring', qty: 1),
  ];

  bool _isGeneratingBriefing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _addItem() {
    String text = _itemController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _startingItems.add(InventoryItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        name: text,
        qty: 1,
      ));
      _itemController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _startingItems.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_isGeneratingBriefing) return;

    String name = _nameController.text.trim();
    String origin = _originController.text.trim();

    if (name.isEmpty) name = 'Nameless Deity';
    if (origin.isEmpty) origin = 'Unmapped Guise';

    setState(() {
      _isGeneratingBriefing = true;
    });

    final manager = context.read<GameStateManager>();

    // Update GameState character model with god-mode parameters while preserving WorldData
    Character newChar = Character(
      name: name,
      origin: origin,
      inventory: _startingItems,
    );

    manager.updateCharacter(newChar);

    // Generate Opening World Briefing via Gemini Client
    final client = GeminiClient();
    String briefing = await client.generateOpeningBriefing(
      world: manager.state.world,
      character: newChar,
    );

    // Store opening briefing as first entry in NarrativeMemory.recentTurns
    manager.applyDelta(
      StateDelta(narration: briefing),
    );

    if (mounted) {
      setState(() {
        _isGeneratingBriefing = false;
      });
      widget.onCharacterCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IlluminatedHeaderBar(
        title: 'Manifestation',
        subtitle: 'Mortal Guise Setup',
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: AppSpacing.borderRadiusFull,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
                ),
                const SizedBox(width: 6),
                Text(
                  'Gathering lore...',
                  style: AppTypography.uiCaption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Mortal Guise',
              style: AppTypography.narrationDisplay,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'As an omnipotent deity, your physical or magical intent never fails. Stakes come from mortal reactions, suspicion, and societal consequences.',
              style: AppTypography.narrationBody,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Character Name Input
            TextField(
              controller: _nameController,
              style: AppTypography.uiBody,
              decoration: const InputDecoration(
                labelText: 'Mortal Name / Title',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Origin / Physical Guise Input
            TextField(
              controller: _originController,
              style: AppTypography.uiBody,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Physical / Conceptual Guise (Origin)',
                hintText: 'e.g. Disguised as a disgraced memory weaver from the western coast',
                prefixIcon: Icon(Icons.masks_outlined, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Starting Inventory Section
            const Text(
              'Starting Relics & Inventory',
              style: AppTypography.loreTitle,
            ),
            const SizedBox(height: AppSpacing.xs),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    style: AppTypography.uiBody,
                    decoration: const InputDecoration(
                      hintText: 'Add starting relic or item name...',
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GoldIconButton(
                  icon: Icons.add,
                  onPressed: _addItem,
                  tooltip: 'Add Relic',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // List of Starting Items
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: List.generate(_startingItems.length, (index) {
                InventoryItem item = _startingItems[index];
                return Chip(
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                  label: Text(item.name, style: AppTypography.uiBody.copyWith(fontSize: 13)),
                  deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.suspicionHigh),
                  onDeleted: () => _removeItem(index),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: IlluminatedButton(
                label: _isGeneratingBriefing ? 'Weaving Opening World Briefing...' : 'Enter Realm as Deity',
                icon: Icons.play_arrow_rounded,
                isLoading: _isGeneratingBriefing,
                onPressed: _isGeneratingBriefing ? null : _handleSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
