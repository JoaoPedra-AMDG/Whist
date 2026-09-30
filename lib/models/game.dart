import '../logic/seating.dart';

class GameRound {
  GameRound({
    required this.cards,
    required this.blind,
    Map<int, int>? calls,
    Map<int, int>? wins,
    this.dealer,
    List<int>? turnOrder,
    this.completed = false,
  }) : calls = calls ?? {},
       wins = wins ?? {},
       turnOrder = turnOrder == null ? null : List.of(turnOrder);

  final int cards;
  final bool blind;
  final Map<int, int> calls;
  final Map<int, int> wins;
  int? dealer;
  List<int>? turnOrder;
  bool completed;

  String get label => blind ? '1 · Blind' : '$cards';

  Map<String, Object?> toJson() => {
    'cards': cards,
    'blind': blind,
    'calls': calls.map((key, value) => MapEntry('$key', value)),
    'wins': wins.map((key, value) => MapEntry('$key', value)),
    'dealer': dealer,
    'turnOrder': turnOrder,
    'completed': completed,
  };

  factory GameRound.fromJson(Map<String, dynamic> json) => GameRound(
    cards: json['cards'] as int,
    blind: json['blind'] as bool? ?? false,
    calls: (json['calls'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(int.parse(key), value as int),
    ),
    wins: (json['wins'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(int.parse(key), value as int),
    ),
    dealer: json['dealer'] as int?,
    turnOrder: (json['turnOrder'] as List<dynamic>?)?.cast<int>(),
    completed: json['completed'] as bool? ?? false,
  );
}

class WhistGame {
  WhistGame({
    required this.players,
    required this.startingCards,
    required this.rounds,
    List<int>? seatOrder,
  }) : seatOrder = List.of(
         seatOrder ?? List<int>.generate(players.length, (index) => index),
       );

  final List<String> players;
  final int startingCards;
  final List<GameRound> rounds;
  final List<int> seatOrder;

  int dealerForRound(int index) =>
      rounds[index].dealer ?? ((players.length - 1 + index) % players.length);

  List<int> turnOrderForRound(int index) =>
      rounds[index].turnOrder ?? callingOrder(seatOrder, dealerForRound(index));

  int get currentRoundIndex {
    final index = rounds.indexWhere((round) => !round.completed);
    return index < 0 ? rounds.length : index;
  }

  bool get isFinished => currentRoundIndex == rounds.length;

  Map<String, Object?> toJson() => {
    'version': 2,
    'players': players,
    'seatOrder': seatOrder,
    'startingCards': startingCards,
    'rounds': rounds.map((round) => round.toJson()).toList(),
  };

  factory WhistGame.fromJson(Map<String, dynamic> json) {
    final game = WhistGame(
      players: List<String>.from(json['players'] as List<dynamic>),
      seatOrder: (json['seatOrder'] as List<dynamic>?)?.cast<int>(),
      startingCards: json['startingCards'] as int,
      rounds:
          (json['rounds'] as List<dynamic>)
              .map((round) => GameRound.fromJson(round as Map<String, dynamic>))
              .toList(),
    );
    if ((json['version'] as int? ?? 1) < 2) {
      // Earlier releases always called in player-list order. Preserve every
      // round with entered data, then rotate the dealer for later rounds.
      var historicalEnd = -1;
      for (var index = 0; index < game.rounds.length; index++) {
        final round = game.rounds[index];
        if (round.completed ||
            round.calls.isNotEmpty ||
            round.wins.isNotEmpty) {
          historicalEnd = index;
        }
      }
      var dealer = game.players.length - 1;
      for (var index = 0; index < game.rounds.length; index++) {
        if (index > 0 && index > historicalEnd) {
          dealer = nextDealer(game.seatOrder, dealer);
        }
        game.rounds[index].dealer = dealer;
        game.rounds[index].turnOrder =
            index <= historicalEnd
                ? List.of(game.seatOrder)
                : callingOrder(game.seatOrder, dealer);
      }
    }
    return game;
  }
}
