import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../models/game_record.dart';
import '../theme/whist_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final records = List<GameRecord>.of(controller.game?.history ?? [])
        ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
      final totals = <String, _PlayerTotal>{};
      for (final record in records) {
        final best = record.scores.reduce((a, b) => a > b ? a : b);
        for (var index = 0; index < record.players.length; index++) {
          final name = record.players[index];
          final key = name.trim().toLowerCase();
          final player = totals.putIfAbsent(key, () => _PlayerTotal(name));
          player.games++;
          player.points += record.scores[index];
          if (record.scores[index] == best) player.wins++;
        }
      }
      final ranking =
          totals.values.toList()..sort((a, b) {
            final wins = b.wins.compareTo(a.wins);
            if (wins != 0) return wins;
            final points = b.points.compareTo(a.points);
            return points != 0 ? points : a.name.compareTo(b.name);
          });
      return Scaffold(
        appBar: AppBar(title: const Text('Leaderboard')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child:
                  records.isEmpty
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No finished games yet. Finish a game to see scores here.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'ALL TIME',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          for (final (place, player) in ranking.indexed)
                            Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: WhistPalette.surfaceRaised,
                                  child: Text('${place + 1}'),
                                ),
                                title: Text(player.name),
                                subtitle: Text(
                                  '${player.games} games · ${player.points} points',
                                ),
                                trailing: Text(
                                  '${player.wins} wins',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: WhistPalette.gold),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'PREVIOUS GAMES',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          for (final record in records)
                            Card(
                              child: ExpansionTile(
                                title: Text(_date(record.finishedAt)),
                                subtitle: Text(
                                  '${record.roundsPlayed} of ${record.totalRounds} rounds · ${record.endedEarly ? 'Finished early' : 'Completed'}',
                                ),
                                children: [
                                  for (final index in _scoreOrder(record))
                                    ListTile(
                                      dense: true,
                                      title: Text(record.players[index]),
                                      trailing: Text(
                                        '${record.scores[index]} points',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Saved on this device only. Use the same browser to keep your history.',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
            ),
          ),
        ),
      );
    },
  );

  static String _date(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static List<int> _scoreOrder(GameRecord record) =>
      List<int>.generate(record.players.length, (index) => index)
        ..sort((a, b) => record.scores[b].compareTo(record.scores[a]));
}

class _PlayerTotal {
  _PlayerTotal(this.name);
  final String name;
  int games = 0;
  int wins = 0;
  int points = 0;
}
