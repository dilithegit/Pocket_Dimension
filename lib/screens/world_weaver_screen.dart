import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../network/gemini_client.dart';
import '../models/world.dart';
import '../models/save_slot.dart';
import '../models/game_state.dart';
import '../models/state_delta.dart';
import '../database/save_slot_repository.dart';
import '../state/game_state_manager.dart';

/// World Weaver Setup Screen - Entry screen to generate grounded fantasy worlds before character creation.
class WorldWeaverScreen extends StatefulWidget {
  final VoidCallback? onWorldAccepted;

  const WorldWeaverScreen({
    super.key,
    this.onWorldAccepted,
  });

  @override
  State<WorldWeaverScreen> createState() => _WorldWeaverScreenState();
}

class _WorldWeaverScreenState extends State<WorldWeaverScreen> {
  final TextEditingController _conceptController =
      TextEditingController(text: 'African high fantasy');
  final GeminiClient _geminiClient = GeminiClient();
  final SaveSlotRepository _repository = SaveSlotRepository();

  bool _isGenerating = false;
  WorldData? _generatedWorld;
  String? _errorMessage;

  @override
  void dispose() {
    _conceptController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    String concept = _conceptController.text.trim();
    if (concept.isEmpty) return;

    final manager = context.read<GameStateManager>();

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    if (manager.isOfflineMode) {
      // Offline Mode: Bypass Gemini API call and load hardcoded Nigerian Mythology dataset instantly
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _generatedWorld = _getPreWovenNigerianWorld();
        _isGenerating = false;
      });
      return;
    }

    try {
      WorldData world =
          await _geminiClient.generateWorldBible(worldConceptPrompt: concept);
      setState(() {
        _generatedWorld = world;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to weave world: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  WorldData _getPreWovenNigerianWorld() {
    return WorldData.fromJson({
      'current_location': 'Mythical Surulere — Sun-Spire Citadel',
      'regional_suspicion': {
        'Mythical Surulere — Sun-Spire Citadel': {
          'heat_level': 5,
          'rumors': [
            'Ancestral spirits whisper of an unmanifested deity walking the grand Eko market.',
            'The Griots of Osogbo detected a celestial ripple over the Olokun tide spires.'
          ]
        }
      },
      'flags': {
        'realm_type': 'Nigerian Mythology — Pre-Woven Offline Realm',
        'pantheon_status': 'Ancient Orisha watching in secret',
        'mythic_cycle': 'Age of the Sun-Spire',
      },
      'npc_relationships': {
        'npc_oluwo': {
          'id': 'npc_oluwo',
          'name': 'Oluwo Ifa-Tayo',
          'role': 'High Memory Keeper of Osogbo',
          'lore_origin': 'Yoruba Ifa Oral Divination Corpus',
          'cultural_archetype': 'Elder Babalawo Memory Weaver',
          'personality_tags': ['wise', 'reverent', 'discerning'],
          'goal': 'Protect the sacred Odu verses from royal censors',
          'secret': 'Knows an unremembered god walks among mortals',
          'trust': 2,
          'disposition': 'neutral',
          'known_facts': ['Observed unusual starfall over the Surulere spires'],
          'last_seen_turn': 0,
        },
        'npc_moremi': {
          'id': 'npc_moremi',
          'name': 'Moremi of the Sun Gate',
          'role': 'Warden of the Citadel Spires',
          'lore_origin': 'Classical Ife Historical Heroine Legends',
          'cultural_archetype': 'Tactical Fortress Guard',
          'personality_tags': ['brave', 'tactical', 'unyielding'],
          'goal': 'Expose corrupt merchants smuggling forbidden reliquaries',
          'secret': 'Owes a blood debt to an unknown benefactor',
          'trust': 0,
          'disposition': 'wary',
          'known_facts': ['Noticed ether fluctuations at midnight near Eko market'],
          'last_seen_turn': 0,
        },
        'npc_priestess_akenzua': {
          'id': 'npc_priestess_akenzua',
          'name': 'Priestess Akenzua',
          'role': 'Keeper of Olokun Coral Relics',
          'lore_origin': 'Benin Kingdom Coral & Bronze Antiquities',
          'cultural_archetype': 'Royal Coral Oracle',
          'personality_tags': ['mysterious', 'cautious'],
          'goal': 'Channel ocean ether to protect coastal trade routes',
          'secret': 'Guards the sacred coral staff of Olokun',
          'trust': 1,
          'disposition': 'friendly',
          'known_facts': ['Sensed a divine manifestation in the ether'],
          'last_seen_turn': 0,
        }
      }
    });
  }

  Future<void> _handleAccept() async {
    if (_generatedWorld == null) return;

    final manager = context.read<GameStateManager>();

    // 1. Initialize GameState with generated WorldData
    GameState newState = GameState.initial(
      name: 'Unbound God',
      origin: 'Divine Entity',
      startingLocation: _generatedWorld!.currentLocation,
    ).copyWith(world: _generatedWorld);

    // 2. Load into state manager
    manager.createNewGame(
      name: newState.character.name,
      origin: newState.character.origin,
      startingLocation: newState.world.currentLocation,
    );
    manager.applyDelta(
      // Apply initial world setup as state update
      dynamicWorldSetup(_generatedWorld!),
    );

    // 3. Save initial slot to SQLite
    SaveSlot slot = SaveSlot.fromGameState(
      slotName: 'World: ${_generatedWorld!.currentLocation}',
      state: manager.state,
    );
    await _repository.insertSaveSlot(slot);

    // 4. Trigger callback to navigate to Character Creation
    if (widget.onWorldAccepted != null) {
      widget.onWorldAccepted!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('World Accepted & Saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('World Weaver — Concept Setup', style: AppTypography.uiHeader),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weave Your Universe',
              style: AppTypography.narrationDisplay,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Describe the secondary fantasy world you wish to stand in. The AI World Weaver will compile an original, grounded World Bible from deep cultural folklore.',
              style: AppTypography.narrationBody,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Prompt Input Field
            TextField(
              controller: _conceptController,
              enabled: !_isGenerating,
              style: AppTypography.uiBody,
              decoration: InputDecoration(
                labelText: 'World Concept Prompt',
                hintText: 'e.g. African high fantasy, Steampunk desert empire',
                prefixIcon: const Icon(Icons.auto_awesome, color: AppColors.accent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.accent),
                  onPressed: _isGenerating ? null : _handleGenerate,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                ),
                onPressed: _isGenerating ? null : _handleGenerate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'Weaving Cosmology...' : 'Weave World Bible',
                  style: AppTypography.uiHeader.copyWith(
                    color: AppColors.background,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTypography.uiBody.copyWith(color: AppColors.suspicionHigh),
              ),
            ],

            // World Preview Section
            if (_generatedWorld != null && !_isGenerating) ...[
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              const Text(
                'World Bible Preview',
                style: AppTypography.loreTitle,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Location Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starting Location: ${_generatedWorld!.currentLocation}',
                        style: AppTypography.narrationDisplay.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Suspicion Level: ${_getInitialHeat()}%',
                        style: AppTypography.uiBody.copyWith(
                          color: AppColors.getSuspicionColor(_getInitialHeat()),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Rumors Section
              const Text('Active Regional Rumors', style: AppTypography.uiHeader),
              const SizedBox(height: AppSpacing.xs),
              ..._getRumors().map(
                (rumor) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record,
                          size: 8, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(rumor, style: AppTypography.narrationBody.copyWith(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Deep-Lore Living NPCs Section
              const Text('Generated Deep-Lore Inhabitants', style: AppTypography.uiHeader),
              const SizedBox(height: AppSpacing.xs),
              ..._generatedWorld!.npcRelationships.values.map(
                (npc) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    title: Text(npc.name, style: AppTypography.loreTitle.copyWith(fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${npc.role} • ${npc.culturalArchetype}',
                            style: AppTypography.uiBody.copyWith(fontSize: 12)),
                        Text('Lore Origin: ${npc.loreOrigin}',
                            style: AppTypography.uiCaption),
                        Text('Goal: ${npc.goal}', style: AppTypography.uiLabel),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Accept / Re-Weave Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _handleGenerate,
                      child: const Text('Re-Weave World', style: AppTypography.uiBody),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _handleAccept,
                      child: Text(
                        'Accept World',
                        style: AppTypography.uiHeader.copyWith(
                          color: AppColors.background,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getInitialHeat() {
    if (_generatedWorld == null) return 0;
    String loc = _generatedWorld!.currentLocation;
    return _generatedWorld!.regionalSuspicion[loc]?.heatLevel ?? 0;
  }

  List<String> _getRumors() {
    if (_generatedWorld == null) return [];
    String loc = _generatedWorld!.currentLocation;
    return _generatedWorld!.regionalSuspicion[loc]?.rumors ?? [];
  }
}

// Helper to wrap initial WorldData into a StateDelta for GameStateManager
dynamicWorldSetup(WorldData world) {
  return StateDelta(
    narration: 'The cosmos coalesces around ${world.currentLocation}.',
    flagsSet: world.flags,
    npcUpdates: world.npcRelationships.values.toList(),
    locationChange: world.currentLocation,
  );
}
