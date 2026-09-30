import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/scoring.dart';
import 'final_results_screen.dart';
import 'round_flow_screen.dart';
import 'rules_screen.dart';
import 'score_sheet_screen.dart';
import 'seating_screen.dart';
import '../theme/whist_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final game = widget.controller.game!;
      if (game.isFinished) {
        return FinalResultsScreen(controller: widget.controller);
      }
      final index = game.currentRoundIndex;
      final round = game.rounds[index];
      final callsReady = round.calls.length == game.players.length;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Whist'),
          actions: [
            IconButton(
              tooltip: 'Seating and dealer',
              icon: const Icon(Icons.groups_outlined),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SeatingScreen(controller: widget.controller),
                    ),
                  ),
            ),
            IconButton(
              tooltip: 'Score sheet',
              icon: const Icon(Icons.table_chart_outlined),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              ScoreSheetScreen(controller: widget.controller),
                    ),
                  ),
            ),
            IconButton(
              tooltip: 'Rules',
              icon: const Icon(Icons.help_outline),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RulesScreen()),
                  ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ROUND ${index + 1} OF ${game.rounds.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.style_outlined,
                          color: WhistPalette.accent,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${round.cards} ${round.cards == 1 ? 'card' : 'cards'}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        if (round.blind) const Chip(label: Text('BLIND')),
                      ],
                    ),
                    Text(
                      callsReady
                          ? 'Play, then enter tricks won.'
                          : 'Collect calls before playing.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => SeatingScreen(
                                    controller: widget.controller,
                                  ),
                            ),
                          ),
                      icon: const Icon(Icons.groups_outlined, size: 18),
                      label: Text(
                        'Dealer: ${game.players[game.dealerForRound(index)]} · Edit seats',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final (seatIndex, player)
                              in game.seatOrder.indexed)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: WhistPalette.surfaceRaised,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: WhistPalette.outline,
                                        ),
                                      ),
                                      child: Text(
                                        '${seatIndex + 1}',
                                        style: const TextStyle(
                                          color: WhistPalette.accentMuted,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            game.players[player],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                          ),
                                          Text(
                                            'Called ${round.calls[player]?.toString() ?? '—'} · Won ${round.wins[player]?.toString() ?? '—'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${totalScore(game, player)}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: WhistPalette.gold,
                                          ),
                                        ),
                                        Text(
                                          'points',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => RoundFlowScreen(
                                    controller: widget.controller,
                                    roundIndex: index,
                                    initialStage:
                                        callsReady
                                            ? RoundStage.results
                                            : RoundStage.calls,
                                  ),
                            ),
                          ),
                      icon: Icon(
                        callsReady
                            ? Icons.check_circle_outline
                            : Icons.touch_app_outlined,
                      ),
                      label: Text(
                        callsReady ? 'Enter results' : 'Enter predictions',
                      ),
                    ),
                    if (callsReady)
                      TextButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => RoundFlowScreen(
                                      controller: widget.controller,
                                      roundIndex: index,
                                    ),
                              ),
                            ),
                        child: const Text('Edit calls'),
                      ),
                    TextButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ScoreSheetScreen(
                                    controller: widget.controller,
                                  ),
                            ),
                          ),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('Score sheet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
