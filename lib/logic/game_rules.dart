import '../models/game.dart';

List<GameRound> generateRounds(int startingCards) {
  if (startingCards < 1) {
    throw ArgumentError.value(startingCards, 'startingCards');
  }
  return [
    for (var cards = startingCards; cards >= 1; cards--)
      GameRound(cards: cards, blind: false),
    GameRound(cards: 1, blind: true),
    for (var cards = 1; cards <= startingCards; cards++)
      GameRound(cards: cards, blind: false),
  ];
}

int maxStartingCards(int playerCount) {
  if (playerCount < 2 || playerCount > 52) {
    throw ArgumentError.value(playerCount, 'playerCount');
  }
  return 52 ~/ playerCount;
}

int? forbiddenFinalCall(int cards, Iterable<int> priorCalls) {
  final value = cards - priorCalls.fold<int>(0, (sum, call) => sum + call);
  return value >= 0 && value <= cards ? value : null;
}

bool validCalls(int cards, List<int> calls) =>
    calls.every((call) => call >= 0 && call <= cards) &&
    calls.fold<int>(0, (sum, call) => sum + call) != cards;

bool validResults(int cards, List<int> wins) =>
    wins.every((won) => won >= 0 && won <= cards) &&
    wins.fold<int>(0, (sum, won) => sum + won) == cards;
