import '../models/game.dart';

int roundScore(int call, int won) => won + (call == won ? 10 : 0);

int totalScore(WhistGame game, int playerIndex, {int? throughRound}) {
  final end = throughRound ?? game.rounds.length - 1;
  var total = 0;
  for (var index = 0; index <= end && index < game.rounds.length; index++) {
    final round = game.rounds[index];
    if (!round.completed) continue;
    final call = round.calls[playerIndex];
    final won = round.wins[playerIndex];
    if (call != null && won != null) total += roundScore(call, won);
  }
  return total;
}

int successfulCalls(WhistGame game, int playerIndex) =>
    game.rounds
        .where(
          (round) =>
              round.completed &&
              round.calls[playerIndex] != null &&
              round.calls[playerIndex] == round.wins[playerIndex],
        )
        .length;
