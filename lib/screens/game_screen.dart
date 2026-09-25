import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/scoring.dart';
import 'final_results_screen.dart';
import 'round_flow_screen.dart';
import 'rules_screen.dart';
import 'score_sheet_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final game = controller.game!;
      if (game.isFinished) return FinalResultsScreen(controller: controller);
      final index = game.currentRoundIndex;
      final round = game.rounds[index];
      final callsReady = round.calls.length == game.players.length;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Whist'),
          actions: [
            IconButton(
              tooltip: 'Score sheet',
              icon: const Icon(Icons.table_chart_outlined),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScoreSheetScreen(controller: controller),
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'ROUND ${index + 1} OF ${game.rounds.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${round.cards} ${round.cards == 1 ? 'card' : 'cards'}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      if (round.blind)
                        Chip(
                          label: const Text('BLIND'),
                          avatar: const Icon(
                            Icons.visibility_off_outlined,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    callsReady
                        ? 'Play the round, then enter tricks won.'
                        : 'Collect everyone’s calls before playing.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 22),
                  for (var player = 0; player < game.players.length; player++)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.players[player],
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Called ${round.calls[player]?.toString() ?? '—'}  ·  Won ${round.wins[player]?.toString() ?? '—'}',
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${totalScore(game, player)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Text('points'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RoundFlowScreen(
                                  controller: controller,
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
                    label: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        callsReady ? 'Enter results' : 'Enter predictions',
                      ),
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
                                    controller: controller,
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
                                (_) => ScoreSheetScreen(controller: controller),
                          ),
                        ),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('View score sheet'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
