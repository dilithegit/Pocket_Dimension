import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/character.dart';
import '../models/world.dart';
import '../models/consequence_entry.dart';
import '../models/state_delta.dart';
import '../models/save_slot.dart';
import '../database/save_slot_repository.dart';
import '../lore/lore_retrieval_manager.dart';
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
    int? saveSlotId,
    void Function(String textDelta)? onTextDelta,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final targetSlotId = saveSlotId ?? _activeSlotId;
      String? groundingContextStr;

      if (targetSlotId != null && targetSlotId > 0) {
        final scoredChunks = await LoreRetrievalManager(
          geminiClient: client,
        ).retrieveGroundingContext(playerInput, targetSlotId);

        if (scoredChunks.isNotEmpty) {
          groundingContextStr = LoreRetrievalManager.formatGroundingPrompt(scoredChunks);
          debugPrint('[GameStateManager] Injected ${scoredChunks.length} RAG lore chunks into system prompt.');
        }
      }

      // 1. Send prompt payload to Gemini DM Engine
      StateDelta delta = await client.processTurn(
        state: _state,
        playerInput: playerInput,
        worldBibleContext: worldBibleContext,
        groundingContext: groundingContextStr,
        onTextDelta: onTextDelta,
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

    // --- B. Consequence Web Merging & Validation ---
    List<ConsequenceEntry> updatedConsequences =
        List.from(_state.world.consequenceWeb);
    int newEntriesAddedThisTurn = 0;

    for (ConsequenceEntry candidate in delta.consequenceUpdates) {
      // Rule 1: New entries require a non-empty summary
      if (candidate.summary.trim().isEmpty) {
        debugPrint(
            '[GameStateManager] Dropped consequence update with empty summary: ${candidate.id}');
        continue;
      }

      int existingIdx =
          updatedConsequences.indexWhere((c) => c.id == candidate.id);
      if (existingIdx >= 0) {
        // Update to an existing entry: validate status & spreadLevel single-step progression
        ConsequenceEntry existing = updatedConsequences[existingIdx];

        int currentStatusIdx = existing.status.index;
        int targetStatusIdx = candidate.status.index;
        int safeStatusIdx = currentStatusIdx;
        if (targetStatusIdx > currentStatusIdx) {
          safeStatusIdx = (targetStatusIdx - currentStatusIdx > 1)
              ? currentStatusIdx + 1
              : targetStatusIdx;
        }

        int currentSpreadIdx = existing.spreadLevel.index;
        int targetSpreadIdx = candidate.spreadLevel.index;
        int safeSpreadIdx = currentSpreadIdx;
        if (targetSpreadIdx > currentSpreadIdx) {
          safeSpreadIdx = (targetSpreadIdx - currentSpreadIdx > 1)
              ? currentSpreadIdx + 1
              : targetSpreadIdx;
        }

        updatedConsequences[existingIdx] = existing.copyWith(
          summary: candidate.summary.isNotEmpty
              ? candidate.summary
              : existing.summary,
          involvedNpcIds: candidate.involvedNpcIds.isNotEmpty
              ? candidate.involvedNpcIds
              : existing.involvedNpcIds,
          location: candidate.location.isNotEmpty
              ? candidate.location
              : existing.location,
          spreadLevel: ConsequenceSpreadLevel.values[safeSpreadIdx],
          status: ConsequenceStatus.values[safeStatusIdx],
          triggerHint: candidate.triggerHint ?? existing.triggerHint,
        );
      } else {
        // New entry: cap to max 2 new entries per turn
        if (newEntriesAddedThisTurn >= 2) {
          debugPrint(
              '[GameStateManager] Clamped extra consequence entry: ${candidate.id}');
          continue;
        }
        updatedConsequences.add(candidate);
        newEntriesAddedThisTurn++;
      }
    }

    // --- C. Deep-Lore Dynamic NPCs Update ---
    Map<String, NpcRelationship> updatedNpcs =
        Map.from(_state.world.npcRelationships);
    for (NpcRelationship npc in delta.npcUpdates) {
      bool isNew = !updatedNpcs.containsKey(npc.id);
      if (isNew) {
        // Validate loreOrigin & culturalArchetype requirement
        if (npc.loreOrigin.trim().isEmpty ||
            npc.culturalArchetype.trim().isEmpty) {
          debugPrint('[GameStateManager] Dropped lore-less NPC update: ${npc.name}');
          continue;
        }
      }

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

    // Remove items safely
    for (var itemName in delta.inventoryRemove) {
      updatedInventory.removeWhere(
          (item) => item.id == itemName || item.name.toLowerCase() == itemName.toLowerCase());
    }

    // Add items
    for (var itemName in delta.inventoryAdd) {
      int existingIdx =
          updatedInventory.indexWhere((item) => item.id == itemName || item.name.toLowerCase() == itemName.toLowerCase());
      if (existingIdx >= 0) {
        var existing = updatedInventory[existingIdx];
        updatedInventory[existingIdx] =
            existing.copyWith(qty: existing.qty + 1);
      } else {
        updatedInventory.add(InventoryItem(
          id: 'item_${DateTime.now().microsecondsSinceEpoch}',
          name: itemName,
          qty: 1,
        ));
      }
    }

    // --- E. Narrative Memory Exchanges ---
    List<String> updatedTurns = List.from(_state.narrativeMemory.recentTurns);
    if (playerInput != null && playerInput.isNotEmpty) {
      updatedTurns.add('Player: $playerInput');
    }
    updatedTurns.add('DM: ${delta.narration}');
    String currentLoc = delta.locationChange ?? _state.world.currentLocation;

    // Assemble updated GameState
    _state = _state.copyWith(
      character: _state.character.copyWith(
        inventory: updatedInventory,
      ),
      world: _state.world.copyWith(
        currentLocation: currentLoc,
        consequenceWeb: updatedConsequences,
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
