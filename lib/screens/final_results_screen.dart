import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/scoring.dart';
import 'game_setup_screen.dart';
import 'score_sheet_screen.dart';

class FinalResultsScreen extends StatelessWidget {
  const FinalResultsScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final game = controller.game!;
    final ranking = List<int>.generate(game.players.length, (index) => index)
      ..sort((a, b) => totalScore(game, b).compareTo(totalScore(game, a)));
    final winningScore = totalScore(game, ranking.first);
    final winners = ranking
        .where((player) => totalScore(game, player) == winningScore)
        .map((player) => game.players[player])
        .join(' & ');
    return Scaffold(
      appBar: AppBar(title: const Text('Final results')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.emoji_events_outlined,
                  size: 54,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  winners,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  ranking
                              .where(
                                (player) =>
                                    totalScore(game, player) == winningScore,
                              )
                              .length >
                          1
                      ? 'Joint winners'
                      : 'Winner',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                for (var place = 0; place < ranking.length; place++)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Text(
                            '${place + 1}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.players[ranking[place]],
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${successfulCalls(game, ranking[place])} correct calls · '
                                  '${(successfulCalls(game, ranking[place]) * 100 / game.rounds.length).round()}%',
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${totalScore(game, ranking[place])}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton.tonal(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ScoreSheetScreen(controller: controller),
                        ),
                      ),
                  child: const Text('View score sheet'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final created = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameSetupScreen(controller: controller),
                      ),
                    );
                    if (created == true && context.mounted) {
                      // The surrounding GameScreen rebuilds from the new game.
                    }
                  },
                  child: const Text('New game'),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                  child: const Text('Return home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
