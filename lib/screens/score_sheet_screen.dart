import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/scoring.dart';
import 'round_flow_screen.dart';

class ScoreSheetScreen extends StatelessWidget {
  const ScoreSheetScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final game = controller.game!;
      return Scaffold(
        appBar: AppBar(title: const Text('Score sheet')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Tap a completed round to correct it. Swipe sideways to see every player.',
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  headingRowHeight: 66,
                  columns: [
                    const DataColumn(label: Text('Round / cards')),
                    for (final player in game.seatOrder)
                      DataColumn(
                        label: Text(
                          '${game.players[player]}\nCall · Won · Total',
                        ),
                      ),
                  ],
                  rows: [
                    for (var index = 0; index < game.rounds.length; index++)
                      DataRow(
                        onSelectChanged:
                            game.rounds[index].completed
                                ? (_) => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => RoundFlowScreen(
                                          controller: controller,
                                          roundIndex: index,
                                          editing: true,
                                        ),
                                  ),
                                )
                                : null,
                        color:
                            game.rounds[index].blind
                                ? WidgetStatePropertyAll(
                                  Theme.of(context).colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                )
                                : null,
                        cells: [
                          DataCell(
                            Text(
                              '${index + 1} · ${game.rounds[index].label}${game.rounds[index].completed ? '' : ' · —'}',
                            ),
                          ),
                          for (final player in game.seatOrder)
                            DataCell(
                              Text(
                                game.rounds[index].completed
                                    ? '${game.rounds[index].calls[player]} · ${game.rounds[index].wins[player]} · ${totalScore(game, player, throughRound: index)}'
                                    : '— · — · —',
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
