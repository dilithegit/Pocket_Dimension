import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/character.dart';
import '../models/world.dart';
import '../models/state_delta.dart';
import '../models/save_slot.dart';
import '../database/save_slot_repository.dart';
import '../network/gemini_client.dart';

/// GameStateManager manages in-memory GameState, enforces Schema Version 2 canonical rules,
/// applies AI DM StateDeltas safely, handles memory summarization thresholds, and extends
/// ChangeNotifier to trigger Flutter UI rebuilds reactively.
class GameStateManager extends ChangeNotifier {
  GameState _state;
  int? _activeSlotId;
  String _activeSlotName;
  bool _isOfflineMode = false;
  bool _isProcessing;

  GameStateManager({
    GameState? initialState,
    int? activeSlotId,
    String activeSlotName = 'Autosave',
  })  : _state = initialState ??
            GameState.initial(
              name: 'Nameless God',
              origin: 'Conceptual Entity',
            ),
        _activeSlotId = activeSlotId,
        _activeSlotName = activeSlotName,
        _isProcessing = false;

  /// Get current immutable GameState snapshot.
  GameState get state => _state;

  /// Offline mode status.
  bool get isOfflineMode => _isOfflineMode;

  void setOfflineMode(bool enabled) {
    _isOfflineMode = enabled;
    notifyListeners();
  }

  /// Active save slot ID (null if unsaved new game).
  int? get activeSlotId => _activeSlotId;

  /// Active save slot label name.
  String get activeSlotName => _activeSlotName;

  /// True while processing an AI turn or saving.
  bool get isProcessing => _isProcessing;

  /// Initialize a brand new game session.
  void createNewGame({
    required String name,
    required String origin,
    String startingLocation = 'Nexus of Worlds',
  }) {
    _state = GameState.initial(
      name: name,
      origin: origin,
      startingLocation: startingLocation,
    );
    _activeSlotId = null;
    _activeSlotName = 'New Adventure';
    notifyListeners();
  }

  /// Update character model while preserving current WorldData.
  void updateCharacter(Character character) {
    _state = _state.copyWith(character: character);
    notifyListeners();
  }

  /// Load an existing GameState from a SaveSlot database record.
  void loadFromSlot(SaveSlot slot) {
    _state = slot.toGameState();
    _activeSlotId = slot.id;
    _activeSlotName = slot.slotName;
    notifyListeners();
  }

  /// Save current GameState to SQLite via SaveSlotRepository.
  Future<int> saveToSlot({
    required SaveSlotRepository repository,
    String? slotName,
  }) async {
    _isProcessing = true;
    notifyListeners();

    String nameToUse = slotName ?? _activeSlotName;
    SaveSlot slot = SaveSlot.fromGameState(
      id: _activeSlotId,
      slotName: nameToUse,
      state: _state,
    );

    int slotId;
    if (_activeSlotId == null) {
      slotId = await repository.insertSaveSlot(slot);
      _activeSlotId = slotId;
    } else {
      await repository.updateSaveSlot(slot);
      slotId = _activeSlotId!;
    }

    _activeSlotName = nameToUse;
    _isProcessing = false;
    notifyListeners();
    return slotId;
  }

  /// Process a player freeform turn: calls Gemini DM Client, applies StateDelta,
  /// handles memory summarization if needed, and notifies UI listeners to rebuild.
  Future<StateDelta> processPlayerTurn(
    String playerInput,
    GeminiClient client, {
    String? worldBibleContext,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // 1. Send prompt payload to Gemini DM Engine
      StateDelta delta = await client.processTurn(
        state: _state,
        playerInput: playerInput,
        worldBibleContext: worldBibleContext,
      );

      // 2. Apply validated delta updates to in-memory state
      applyDelta(delta, playerInput: playerInput);

      // 3. Check memory summarization threshold (~10 turns)
      if (shouldSummarize()) {
        await summarizeMemory(client);
      }

      return delta;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Safely apply StateDelta mutations without allowing arbitrary state overrides.
  void applyDelta(StateDelta delta, {String? playerInput}) {
    // --- A. World Flags Update ---
    Map<String, dynamic> updatedFlags = Map.from(_state.world.flags);
    updatedFlags.addAll(delta.flagsSet);

    // --- B. Regional Suspicion Update ---
    Map<String, RegionalSuspicion> updatedSuspicion =
        Map.from(_state.world.regionalSuspicion);
    String currentLoc = delta.locationChange ?? _state.world.currentLocation;

    if (delta.suspicionIncrease.isNotEmpty) {
      String region = delta.suspicionIncrease['region_name'] as String? ?? currentLoc;
      int heatInc = (delta.suspicionIncrease['heat_increase'] as num?)?.toInt() ?? 0;
      String? newRumor = delta.suspicionIncrease['new_rumor'] as String?;

      RegionalSuspicion existing = updatedSuspicion[region] ??
          const RegionalSuspicion(heatLevel: 0, rumors: []);

      List<String> newRumorList = List.from(existing.rumors);
      if (newRumor != null && newRumor.isNotEmpty && !newRumorList.contains(newRumor)) {
        newRumorList.add(newRumor);
      }

      updatedSuspicion[region] = existing.copyWith(
        heatLevel: (existing.heatLevel + heatInc).clamp(0, 100),
        rumors: newRumorList,
      );
    }

    // --- C. Deep-Lore Dynamic NPCs Update ---
    Map<String, NpcRelationship> updatedNpcs =
        Map.from(_state.world.npcRelationships);
    for (NpcRelationship npc in delta.npcUpdates) {
      NpcRelationship existing = updatedNpcs[npc.id] ?? npc;
      List<String> mergedFacts = List.from(existing.knownFacts);
      for (String fact in npc.knownFacts) {
        if (!mergedFacts.contains(fact)) {
          mergedFacts.add(fact);
        }
      }

      updatedNpcs[npc.id] = npc.copyWith(
        knownFacts: mergedFacts,
        lastSeenTurn: _state.narrativeMemory.recentTurns.length + 1,
      );
    }

    // --- D. Inventory Updates ---
    List<InventoryItem> updatedInventory = List.from(_state.character.inventory);

    // Remove items
    for (var itemRem in delta.inventoryRemove) {
      updatedInventory.removeWhere((item) => item.id == itemRem.id || item.name == itemRem.name);
    }

    // Add items
    for (var itemAdd in delta.inventoryAdd) {
      int existingIdx = updatedInventory.indexWhere((item) => item.id == itemAdd.id);
      if (existingIdx >= 0) {
        var existing = updatedInventory[existingIdx];
        updatedInventory[existingIdx] = existing.copyWith(qty: existing.qty + itemAdd.qty);
      } else {
        updatedInventory.add(itemAdd);
      }
    }

    // --- E. Narrative Memory Exchanges ---
    List<String> updatedTurns = List.from(_state.narrativeMemory.recentTurns);
    if (playerInput != null && playerInput.isNotEmpty) {
      updatedTurns.add('Player: $playerInput');
    }
    updatedTurns.add('DM: ${delta.narration}');

    // Assemble updated GameState
    _state = _state.copyWith(
      character: _state.character.copyWith(
        inventory: updatedInventory,
      ),
      world: _state.world.copyWith(
        currentLocation: currentLoc,
        regionalSuspicion: updatedSuspicion,
        flags: updatedFlags,
        npcRelationships: updatedNpcs,
      ),
      narrativeMemory: _state.narrativeMemory.copyWith(
        recentTurns: updatedTurns,
      ),
    );

    notifyListeners();
  }

  /// Returns true if recent_turns exceeds ~10 exchange entries.
  bool shouldSummarize() {
    return _state.narrativeMemory.recentTurns.length >= 10;
  }

  /// Performs memory summarization pass via GeminiClient.
  Future<void> summarizeMemory(GeminiClient client) async {
    List<String> turnsToSummarize = List.from(_state.narrativeMemory.recentTurns);
    String newSummary = await client.summarizeMemory(
      currentSummary: _state.narrativeMemory.rollingSummary,
      turnsToSummarize: turnsToSummarize,
    );

    _state = _state.copyWith(
      narrativeMemory: _state.narrativeMemory.copyWith(
        rollingSummary: newSummary,
        recentTurns: [], // Trim old turns after folding into rolling summary
      ),
    );

    notifyListeners();
  }
}
