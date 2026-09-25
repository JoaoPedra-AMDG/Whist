class GameRound {
  GameRound({
    required this.cards,
    required this.blind,
    Map<int, int>? calls,
    Map<int, int>? wins,
    this.completed = false,
  }) : calls = calls ?? {},
       wins = wins ?? {};

  final int cards;
  final bool blind;
  final Map<int, int> calls;
  final Map<int, int> wins;
  bool completed;

  String get label => blind ? '1 · Blind' : '$cards';

  Map<String, Object?> toJson() => {
    'cards': cards,
    'blind': blind,
    'calls': calls.map((key, value) => MapEntry('$key', value)),
    'wins': wins.map((key, value) => MapEntry('$key', value)),
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
    completed: json['completed'] as bool? ?? false,
  );
}

class WhistGame {
  WhistGame({
    required this.players,
    required this.startingCards,
    required this.rounds,
  });

  final List<String> players;
  final int startingCards;
  final List<GameRound> rounds;

  int get currentRoundIndex {
    final index = rounds.indexWhere((round) => !round.completed);
    return index < 0 ? rounds.length : index;
  }

  bool get isFinished => currentRoundIndex == rounds.length;

  Map<String, Object?> toJson() => {
    'version': 1,
    'players': players,
    'startingCards': startingCards,
    'rounds': rounds.map((round) => round.toJson()).toList(),
  };

  factory WhistGame.fromJson(Map<String, dynamic> json) => WhistGame(
    players: List<String>.from(json['players'] as List<dynamic>),
    startingCards: json['startingCards'] as int,
    rounds:
        (json['rounds'] as List<dynamic>)
            .map((round) => GameRound.fromJson(round as Map<String, dynamic>))
            .toList(),
  );
}
