import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/scoring.dart';
import 'game_setup_screen.dart';
import 'leaderboard_screen.dart';
import 'score_sheet_screen.dart';

class FinalResultsScreen extends StatefulWidget {
  const FinalResultsScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<FinalResultsScreen> createState() => _FinalResultsScreenState();
}

class _FinalResultsScreenState extends State<FinalResultsScreen> {
  int _place = 0;

  @override
  Widget build(BuildContext context) {
    final game = widget.controller.game!;
    final ranking = List<int>.generate(game.players.length, (index) => index)
      ..sort((a, b) => totalScore(game, b).compareTo(totalScore(game, a)));
    final current = ranking[_place.clamp(0, ranking.length - 1)];
    final best = totalScore(game, ranking.first);
    final winners = ranking
        .where((player) => totalScore(game, player) == best)
        .map((player) => game.players[player])
        .join(' & ');
    return Scaffold(
      appBar: AppBar(title: const Text('Final results')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    winners,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    winners.contains(' & ') ? 'Joint winners' : 'Winner',
                    textAlign: TextAlign.center,
                  ),
                  if (game.endedEarly)
                    Text(
                      'Finished after ${game.roundsPlayed} of ${game.rounds.length} rounds',
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'PLACE ${_place + 1} OF ${ranking.length}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              game.players[current],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${totalScore(game, current)}',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const Text('points'),
                            const SizedBox(height: 6),
                            Text(
                              '${successfulCalls(game, current)} correct calls · '
                              '${(successfulCalls(game, current) * 100 / game.roundsPlayed).round()}%',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Previous player',
                        onPressed:
                            _place == 0 ? null : () => setState(() => _place--),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('${_place + 1} / ${ranking.length}'),
                      IconButton(
                        tooltip: 'Next player',
                        onPressed:
                            _place >= ranking.length - 1
                                ? null
                                : () => setState(() => _place++),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  FilledButton.tonal(
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
                    child: const Text('View score sheet'),
                  ),
                  TextButton.icon(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => LeaderboardScreen(
                                  controller: widget.controller,
                                ),
                          ),
                        ),
                    icon: const Icon(Icons.leaderboard_outlined),
                    label: const Text('Leaderboard & past games'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => GameSetupScreen(
                                        controller: widget.controller,
                                      ),
                                ),
                              ),
                          child: const Text('New game'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst),
                          child: const Text('Return home'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
