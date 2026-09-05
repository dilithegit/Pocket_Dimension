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
import '../lore/lore_ingestion_manager.dart';
import '../state/game_state_manager.dart';
import '../widgets/custom_ui_components.dart';

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
      'consequence_web': [
        {
          'id': 'c_surulere_whispers',
          'summary': 'Ancestral spirits whisper of an unmanifested deity walking the grand Eko market',
          'involved_npc_ids': ['npc_oluwo'],
          'location': 'Mythical Surulere — Sun-Spire Citadel',
          'origin_turn': 1,
          'spread_level': 'secret',
          'status': 'dormant',
          'trigger_hint': 'Celestial ripple detected over Olokun tide spires'
        }
      ],
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
    int slotId = await _repository.insertSaveSlot(slot);

    // 4. Trigger background lore ingestion in parallel with character creation
    LoreIngestionManager().runLoreIngestion(_generatedWorld!, slotId);

    // 5. Trigger callback to navigate to Character Creation
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
      appBar: const IlluminatedHeaderBar(
        title: 'World Weaver',
        subtitle: 'Concept & Cosmology Setup',
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
              child: IlluminatedButton(
                label: _isGenerating ? 'Weaving Cosmology...' : 'Weave World Bible',
                icon: Icons.auto_awesome,
                isLoading: _isGenerating,
                onPressed: _isGenerating ? null : _handleGenerate,
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
              IlluminatedSaveSlotCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starting Location: ${_generatedWorld!.currentLocation}',
                      style: AppTypography.narrationDisplay.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Consequence Echoes: ${_generatedWorld!.consequenceWeb.length}',
                      style: AppTypography.uiBody.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Consequence Web Section
              const Text('Active Consequence Echoes', style: AppTypography.uiHeader),
              const SizedBox(height: AppSpacing.xs),
              ..._generatedWorld!.consequenceWeb.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      const Icon(Icons.hub_outlined,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(c.summary, style: AppTypography.narrationBody.copyWith(fontSize: 14)),
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
                (npc) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: IlluminatedSaveSlotCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(npc.name, style: AppTypography.loreTitle.copyWith(fontSize: 15)),
                        const SizedBox(height: AppSpacing.xs),
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
                    child: IlluminatedButton(
                      label: 'Re-Weave World',
                      isPrimary: false,
                      onPressed: _handleGenerate,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: IlluminatedButton(
                      label: 'Accept World',
                      isPrimary: true,
                      onPressed: _handleAccept,
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
