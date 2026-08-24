import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/save_slot_repository.dart';
import '../models/consequence_entry.dart';
import '../models/game_state.dart';
import '../models/character.dart';
import '../models/state_delta.dart';
import '../network/gemini_client.dart';
import '../state/game_state_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/game_notification_overlay.dart';

/// Step 7: Chat / Narrative UI Screen & Step 8: Consequence Web HUD
/// Main gameplay loop displaying scrolling narration feed, live-typing stream, and Consequence Web sheet.
class ChatScreen extends StatefulWidget {
  final VoidCallback? onReturnToSaves;

  const ChatScreen({
    super.key,
    this.onReturnToSaves,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SaveSlotRepository _repository = SaveSlotRepository();

  bool _isStreaming = false;
  String _streamingNarration = '';
  Timer? _streamTimer;

  @override
  void dispose() {
    _streamTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(GameStateManager manager) async {
    final text = _inputController.text.trim();
    if (text.isEmpty || manager.isProcessing || _isStreaming) return;

    _inputController.clear();
    FocusScope.of(context).unfocus();

    try {
      StateDelta delta;
      if (manager.isOfflineMode) {
        delta = _buildOfflineMockTurn(manager.state, text);
      } else {
        final client = GeminiClient();
        delta = await manager.processPlayerTurn(text, client);
      }

      await _animateTextReveal(delta.narration);

      if (manager.isOfflineMode) {
        manager.applyDelta(delta, playerInput: text);
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The mists of reality swirl, clouding your vision. Try again.'),
            backgroundColor: AppColors.suspicionHigh,
          ),
        );
      }
    }
  }

  StateDelta _buildOfflineMockTurn(GameState state, String input) {
    String lower = input.toLowerCase();
    String loc = state.world.currentLocation;

    if (lower.contains('talk') || lower.contains('speak') || lower.contains('meet') || lower.contains('ask')) {
      return StateDelta.fromJson({
        'narration': 'You approach Oluwo Ifa-Tayo by the sacred Osogbo shrine. He senses your unearthly authority and bows low: "Unseen deity, the Odu verses predicted your manifestation in $loc. What wisdom do you bring?"',
        'state_delta': {
          'flags_set': {'met_oluwo': true},
          'consequence_updates': [
            {
              'id': 'c_met_oluwo',
              'summary': 'Met Oluwo Ifa-Tayo by the sacred shrine',
              'involved_npc_ids': ['npc_oluwo'],
              'location': loc,
              'origin_turn': 1,
              'spread_level': 'rumored',
              'status': 'brewing',
              'trigger_hint': 'Whispers spread of a god speaking with the Memory Keeper'
            }
          ],
          'npc_updates': [
            {
              'id': 'npc_oluwo',
              'name': 'Oluwo Ifa-Tayo',
              'role': 'High Memory Keeper of Osogbo',
              'lore_origin': 'Yoruba Ifa Oral Divination Corpus',
              'cultural_archetype': 'Elder Babalawo Memory Weaver',
              'personality_tags': ['wise', 'reverent'],
              'goal': 'Protect the sacred Odu verses from royal censors',
              'trust': 5,
              'disposition': 'friendly',
              'known_facts': ['Directly conversed with the unmanifested deity']
            }
          ]
        }
      });
    } else if (lower.contains('cast') || lower.contains('magic') || lower.contains('power') || lower.contains('spell')) {
      return StateDelta.fromJson({
        'narration': 'You unleash your divine will into the ether. A surge of ancestral starfire crackles across the spires of $loc. Mortals drop to their knees in awe and terror as the sky glows gold.',
        'state_delta': {
          'flags_set': {'starfire_manifested': true},
          'consequence_updates': [
            {
              'id': 'c_starfire_flared',
              'summary': 'Celestial starfire flared over the citadel spires',
              'involved_npc_ids': [],
              'location': loc,
              'origin_turn': 1,
              'spread_level': 'known',
              'status': 'active',
              'trigger_hint': 'Mortals witnessed golden lightning'
            }
          ]
        }
      });
    } else if (lower.contains('search') || lower.contains('look') || lower.contains('relic') || lower.contains('explore')) {
      return StateDelta.fromJson({
        'narration': 'You inspect the sacred coral shrine of Olokun. Beneath the ancient bronze relief, you discover a glowing Olokun Coral Amulet pulsing with ocean ether.',
        'state_delta': {
          'flags_set': {'found_olokun_relic': true},
          'inventory_add': [
            {'id': 'relic_olokun_coral', 'name': 'Olokun Coral Amulet', 'qty': 1}
          ]
        }
      });
    } else {
      return StateDelta.fromJson({
        'narration': 'You manifest your divine intent: "$input". The ambient ether of $loc ripples in response, echoing across the ancient spires as mortals sense your presence.',
        'state_delta': {
          'flags_set': {'last_action': input},
          'consequence_updates': [
            {
              'id': 'c_ether_ripple',
              'summary': 'Subtle ether currents rippled through the realm',
              'involved_npc_ids': [],
              'location': loc,
              'origin_turn': 1,
              'spread_level': 'secret',
              'status': 'dormant',
              'trigger_hint': 'Sensitives felt a subtle ripple'
            }
          ]
        }
      });
    }
  }

  Future<void> _animateTextReveal(String fullText) async {
    setState(() {
      _isStreaming = true;
      _streamingNarration = '';
    });

    final completer = Completer<void>();
    int currentIndex = 0;
    const chunkSize = 2;

    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }

      if (currentIndex < fullText.length) {
        int nextIndex = (currentIndex + chunkSize < fullText.length)
            ? currentIndex + chunkSize
            : fullText.length;
        setState(() {
          _streamingNarration += fullText.substring(currentIndex, nextIndex);
        });
        currentIndex = nextIndex;
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          _isStreaming = false;
        });
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameStateManager>();
    final state = manager.state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.world.currentLocation, style: AppTypography.uiHeader),
            Text(
              'Guise: ${state.character.origin}',
              style: AppTypography.uiCaption.copyWith(color: AppColors.accent),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: AppSpacing.borderRadiusFull,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hub_outlined, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  'Memories: ${state.world.consequenceWeb.length}',
                  style: AppTypography.uiCaption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () async {
              await manager.saveToSlot(repository: _repository);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Realm State Saved to SQLite!')),
                );
              }
            },
            tooltip: 'Save Game',
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_book_rounded, color: AppColors.accent),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              tooltip: 'Open World Sheet Drawer',
            ),
          ),
        ],
      ),

      endDrawer: _buildWorldSheetDrawer(context, manager),

      body: Stack(
        children: [
          // Main Gameplay Layout
          GameNotificationOverlay(
            child: Column(
              children: [
                if (manager.isOfflineMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      border: const Border(
                        bottom: BorderSide(color: AppColors.accent, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'The mists have severed your tether to the realm. Running local branching engine...',
                          style: AppTypography.uiCaption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Top Ambient Consequence HUD Bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    border: const Border(
                      bottom: BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hub_outlined, size: 18, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Consequence Web: ${state.world.consequenceWeb.length} Active Echoes',
                        style: AppTypography.uiBody.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'OMNIPOTENT REALM',
                        style: AppTypography.uiCaption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Narration Feed
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.narrativeMemory.recentTurns.length + (_isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isStreaming && index == state.narrativeMemory.recentTurns.length) {
                        return _buildDmNarrationBubble(_streamingNarration, isStreaming: true);
                      }

                      String turn = state.narrativeMemory.recentTurns[index];
                      bool isPlayer = turn.startsWith('Player:');
                      String textContent = isPlayer
                          ? turn.substring(7).trim()
                          : (turn.startsWith('DM:') ? turn.substring(3).trim() : turn);

                      if (isPlayer) {
                        return _buildPlayerInputBubble(textContent);
                      } else {
                        return _buildDmNarrationBubble(textContent);
                      }
                    },
                  ),
                ),

                // Input Bar with Ambient Glow
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.accent.withValues(alpha: 0.6), width: 1.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.20),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          enabled: !manager.isProcessing && !_isStreaming,
                          style: AppTypography.uiBody,
                          decoration: const InputDecoration(
                            hintText: 'Manifest your freeform divine action...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _handleSend(manager),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                        ),
                        onPressed: (manager.isProcessing || _isStreaming)
                            ? null
                            : () => _handleSend(manager),
                        icon: manager.isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stream progress indicator bar
          if (_isStreaming || manager.isProcessing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppColors.accent.withValues(alpha: 0.8),
                minHeight: 2.5,
              ),
            ),
        ],
      ),
    );
  }

  /// DM Narration Bubble: Serif display face, NO chat bubble background, styled on parchment like a book.
  Widget _buildDmNarrationBubble(String text, {bool isStreaming = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Dungeon Master',
                style: AppTypography.uiLabel.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isStreaming) ...[
                const SizedBox(width: AppSpacing.xs),
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.narrationBody.copyWith(
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.border, height: 1),
        ],
      ),
    );
  }

  /// Player Input Bubble: Clean UI sans-serif face, aligned right with subtle surface-color background.
  Widget _buildPlayerInputBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(
          left: 48.0,
          bottom: AppSpacing.md,
          top: AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusLg),
            topRight: Radius.circular(AppSpacing.radiusLg),
            bottomLeft: Radius.circular(AppSpacing.radiusLg),
            bottomRight: Radius.circular(AppSpacing.radiusSm),
          ),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Divine Manifestation',
              style: AppTypography.uiCaption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: AppTypography.uiBody.copyWith(
                color: AppColors.inkPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Slide-Out End Drawer holding Living NPCs Roster, Consequence Web, and Character Inventory
  Widget _buildWorldSheetDrawer(BuildContext context, GameStateManager manager) {
    final state = manager.state;
    List<ConsequenceEntry> consequenceWeb = state.world.consequenceWeb;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('World & Character Sheet', style: AppTypography.uiHeader),
            backgroundColor: AppColors.surfaceElevated,
            bottom: const TabBar(
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.inkMuted,
              tabs: [
                Tab(text: 'Living NPCs'),
                Tab(text: 'Consequence Web'),
                Tab(text: 'Inventory'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Living NPCs Panel
              state.world.npcRelationships.isEmpty
                  ? const Center(
                      child: Text('No NPCs encountered yet.', style: AppTypography.uiCaption),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: state.world.npcRelationships.values.map((npc) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(npc.name, style: AppTypography.loreTitle.copyWith(fontSize: 16)),
                                Text('${npc.role} (${npc.culturalArchetype})',
                                    style: AppTypography.uiBody.copyWith(fontSize: 13, color: AppColors.inkSecondary)),
                                const SizedBox(height: AppSpacing.xs),
                                Text('Lore Origin: ${npc.loreOrigin}', style: AppTypography.uiCaption),
                                Text('Goal: ${npc.goal}', style: AppTypography.uiLabel),
                                if (npc.knownFacts.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('Known Facts: ${npc.knownFacts.join('; ')}', style: AppTypography.uiCaption),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

              // Consequence Web Panel
              consequenceWeb.isEmpty
                  ? const Center(
                      child: Text('No consequences recorded yet.', style: AppTypography.uiCaption),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: consequenceWeb.length,
                      itemBuilder: (context, index) {
                        final item = consequenceWeb[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.hub_outlined, size: 16, color: AppColors.accent),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        item.summary,
                                        style: AppTypography.narrationBody.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('Spread: ${item.spreadLevel.name}'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Chip(
                                      label: Text('Status: ${item.status.name}'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                if (item.triggerHint != null && item.triggerHint!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('Trigger Hint: ${item.triggerHint}', style: AppTypography.uiCaption),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),

              // Inventory Panel
              state.character.inventory.isEmpty
                  ? const Center(
                      child: Text('Inventory is empty.', style: AppTypography.uiCaption),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: state.character.inventory.length,
                      itemBuilder: (context, index) {
                        InventoryItem item = state.character.inventory[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            leading: const Icon(Icons.auto_awesome_mosaic_rounded, color: AppColors.accent),
                            title: Text(item.name, style: AppTypography.uiHeader.copyWith(fontSize: 14)),
                            trailing: Text('x${item.qty}', style: AppTypography.uiLabel),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
