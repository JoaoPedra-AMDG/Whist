class GameRecord {
  GameRecord({
    required this.id,
    required this.finishedAt,
    required this.endedEarly,
    required this.roundsPlayed,
    required this.totalRounds,
    required List<String> players,
    required List<int> scores,
  }) : players = List.of(players),
       scores = List.of(scores);

  final String id;
  final DateTime finishedAt;
  final bool endedEarly;
  final int roundsPlayed;
  final int totalRounds;
  final List<String> players;
  final List<int> scores;

  Map<String, Object?> toJson() => {
    'id': id,
    'finishedAt': finishedAt.toIso8601String(),
    'endedEarly': endedEarly,
    'roundsPlayed': roundsPlayed,
    'totalRounds': totalRounds,
    'players': players,
    'scores': scores,
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    id: json['id'] as String,
    finishedAt: DateTime.parse(json['finishedAt'] as String),
    endedEarly: json['endedEarly'] as bool? ?? false,
    roundsPlayed: json['roundsPlayed'] as int,
    totalRounds: json['totalRounds'] as int,
    players: List<String>.from(json['players'] as List<dynamic>),
    scores: List<int>.from(json['scores'] as List<dynamic>),
  );
}
