import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../models/character.dart';
import '../models/state_delta.dart';
import '../state/game_state_manager.dart';
import '../network/gemini_client.dart';
import '../widgets/game_notification_overlay.dart';
import '../database/save_slot_repository.dart';

/// ChatScreen — Step 8 Implementation with Suspicion / Masquerade HUD:
/// - Ambient screen-edge vignette tint (IgnorePointer, 1.5s smooth color transition).
/// - Input bar soft glow shifting dynamically through suspicionLow/Mid/High.
/// - Peripheral numeric & icon readout for accessibility (eye icon + heat Level / 100).
/// - DM Narration: Serif book face, raw styled text (no chat bubble background).
/// - Player Input: Sans face, right-aligned, surface bubble.
/// - Text-Reveal live-typing stream animation.
/// - Non-blocking slide-out drawer for Living NPCs, Rumors, and Inventory.
class ChatScreen extends StatefulWidget {
  final VoidCallback? onReturnToSaves;

  const ChatScreen({
    super.key,
    this.onReturnToSaves,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiClient _geminiClient = GeminiClient();
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(GameStateManager manager) async {
    String text = _inputController.text.trim();
    if (text.isEmpty || manager.isProcessing || _isStreaming) return;

    _inputController.clear();
    FocusScope.of(context).unfocus();

    int currentHeat = _getHeatLevel(manager.state);
    int currentNpcCount = manager.state.world.npcRelationships.length;

    try {
      StateDelta delta;
      if (manager.isOfflineMode) {
        // Offline Engine: Local branching narrative response
        delta = _processOfflineBranchingTurn(text, manager);
        manager.applyDelta(delta, playerInput: text);
      } else {
        // Online API Engine
        delta = await manager.processPlayerTurn(text, _geminiClient);
      }

      await _animateTextReveal(delta.narration);

      if (mounted) {
        int newHeat = _getHeatLevel(manager.state);
        int newNpcCount = manager.state.world.npcRelationships.length;

        if (newHeat - currentHeat >= 10) {
          GameNotificationOverlay.show(
            context,
            title: 'Regional Suspicion Spiked!',
            message: 'Heat in ${manager.state.world.currentLocation} rose to $newHeat%.',
            icon: Icons.warning_amber_rounded,
            accentColor: AppColors.suspicionHigh,
          );
        }

        if (newNpcCount > currentNpcCount && delta.npcUpdates.isNotEmpty) {
          var newNpc = delta.npcUpdates.last;
          GameNotificationOverlay.show(
            context,
            title: 'New Inhabitant Encountered!',
            message: '${newNpc.name} (${newNpc.culturalArchetype}) observed your presence.',
            icon: Icons.person_add_alt_1_rounded,
            accentColor: AppColors.accent,
          );
        }

        await manager.saveToSlot(repository: _repository);
      }
    } catch (_) {
      const fallbackMsg = 'The mists of reality swirl, clouding your vision. Try again.';
      manager.applyDelta(const StateDelta(narration: fallbackMsg));
      await _animateTextReveal(fallbackMsg);
    }
  }

  StateDelta _processOfflineBranchingTurn(String input, GameStateManager manager) {
    String lower = input.toLowerCase();
    String loc = manager.state.world.currentLocation;

    if (lower.contains('talk') || lower.contains('speak') || lower.contains('meet') || lower.contains('ask')) {
      return StateDelta.fromJson({
        'narration': 'You approach Oluwo Ifa-Tayo by the sacred Osogbo shrine. He senses your unearthly authority and bows low: "Unseen deity, the Odu verses predicted your manifestation in $loc. What wisdom do you bring?"',
        'state_delta': {
          'flags_set': {'met_oluwo': true},
          'suspicion_increase': {
            'region_name': loc,
            'heat_increase': 5,
            'new_rumor': 'Whispers spread of an unmanifested god speaking with the Memory Keeper.'
          },
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
          'suspicion_increase': {
            'region_name': loc,
            'heat_increase': 15,
            'new_rumor': 'Celestial starfire flared over the citadel spires.'
          }
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
          'suspicion_increase': {
            'region_name': loc,
            'heat_increase': 4,
            'new_rumor': 'Subtle ether currents ripple through the realm.'
          }
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
    int charIndex = 0;

    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (charIndex < fullText.length) {
        int step = (charIndex + 3 < fullText.length) ? 3 : (fullText.length - charIndex);
        charIndex += step;
        if (mounted) {
          setState(() {
            _streamingNarration = fullText.substring(0, charIndex);
          });
          _scrollToBottom();
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isStreaming = false;
            _streamingNarration = '';
          });
        }
        completer.complete();
      }
    });

    return completer.future;
  }

  int _getHeatLevel(state) {
    String loc = state.world.currentLocation;
    return state.world.regionalSuspicion[loc]?.heatLevel ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameStateManager>();
    final state = manager.state;
    int heatLevel = _getHeatLevel(state);
    Color targetSuspicionColor = AppColors.getSuspicionColor(heatLevel);

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
          // Accessibility HUD: Peripheral numeric & icon readout
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: targetSuspicionColor),
            duration: const Duration(milliseconds: 1200),
            builder: (context, color, child) {
              final activeColor = color ?? targetSuspicionColor;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusFull,
                  border: Border.all(color: activeColor.withValues(alpha: 0.6), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: activeColor),
                    const SizedBox(width: 4),
                    Text(
                      '$heatLevel/100',
                      style: AppTypography.uiCaption.copyWith(
                        color: activeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
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

      body: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: targetSuspicionColor),
        duration: const Duration(milliseconds: 1500),
        builder: (context, suspicionColor, child) {
          final currentColor = suspicionColor ?? targetSuspicionColor;

          return Stack(
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
                          color: AppColors.suspicionMid.withValues(alpha: 0.2),
                          border: const Border(
                            bottom: BorderSide(color: AppColors.suspicionMid, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.suspicionMid),
                            const SizedBox(width: 6),
                            Text(
                              'The mists have severed your tether to the realm. Running local branching engine...',
                              style: AppTypography.uiCaption.copyWith(
                                color: AppColors.suspicionMid,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Top Ambient Suspicion HUD Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: currentColor.withValues(alpha: 0.12),
                        border: Border(
                          bottom: BorderSide(color: currentColor, width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 18, color: currentColor),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Regional Suspicion: $heatLevel%',
                            style: AppTypography.uiBody.copyWith(
                              color: currentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            heatLevel >= 70
                                ? 'CRITICAL HUNT'
                                : heatLevel >= 31
                                    ? 'WARY MORTALS'
                                    : 'UNDETECTED DEITY',
                            style: AppTypography.uiCaption.copyWith(
                              color: currentColor,
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
                        border: Border(top: BorderSide(color: currentColor.withValues(alpha: 0.6), width: 1.5)),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.20),
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
                            icon: (manager.isProcessing || _isStreaming)
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.background,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Ambient Screen-Edge Vignette Tint (IgnorePointer: non-blocking)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        currentColor.withValues(alpha: 0.12),
                      ],
                      stops: const [0.75, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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

  /// Slide-Out End Drawer holding Living NPCs Roster, Rumors, and Character Inventory
  Widget _buildWorldSheetDrawer(BuildContext context, GameStateManager manager) {
    final state = manager.state;
    String loc = state.world.currentLocation;
    List<String> rumors = state.world.regionalSuspicion[loc]?.rumors ?? [];

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
                Tab(text: 'Rumors'),
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

              // Regional Rumors Panel
              rumors.isEmpty
                  ? const Center(
                      child: Text('No active regional rumors.', style: AppTypography.uiCaption),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: rumors.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            leading: const Icon(Icons.record_voice_over_rounded, color: AppColors.accent),
                            title: Text(rumors[index], style: AppTypography.narrationBody.copyWith(fontSize: 14)),
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
