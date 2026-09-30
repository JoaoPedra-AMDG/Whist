import 'package:flutter_test/flutter_test.dart';
import 'package:whist/logic/game_rules.dart';
import 'package:whist/logic/game_controller.dart';
import 'package:whist/logic/scoring.dart';
import 'package:whist/logic/seating.dart';
import 'package:whist/models/game.dart';
import 'package:whist/services/game_storage.dart';

void main() {
  test('ten-card sequence has 21 rounds and one blind round', () {
    final rounds = generateRounds(10);
    expect(rounds.length, 21);
    expect(rounds.map((round) => round.cards), [
      10,
      9,
      8,
      7,
      6,
      5,
      4,
      3,
      2,
      1,
      1,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
    ]);
    expect(rounds.where((round) => round.blind).length, 1);
    expect(rounds[10].blind, isTrue);
  });

  test('starting cards respect a 52-card deck', () {
    expect(maxStartingCards(3), 17);
    expect(maxStartingCards(6), 8);
  });

  test('calls begin left of the dealer and end with the dealer', () {
    const seats = [0, 1, 2, 3];
    expect(callingOrder(seats, 1), [2, 3, 0, 1]);
    expect(nextDealer(seats, 1), 2);
    expect(callingOrder(seats, 2), [3, 0, 1, 2]);
  });

  test('changing seats keeps past scores and rotates future dealers', () async {
    String? saved;
    final controller = GameController(
      storage: GameStorage(
        reader: () async => saved,
        writer: (value) async {
          saved = value;
        },
      ),
    );
    await controller.start(['A', 'B', 'C'], 2, firstDealer: 1);
    expect(controller.game!.dealerForRound(0), 1);
    expect(controller.game!.turnOrderForRound(0), [2, 0, 1]);
    expect(controller.game!.dealerForRound(1), 2);
    await controller.commit(0, {0: 0, 1: 0, 2: 1}, {0: 1, 1: 1, 2: 0});
    final score = totalScore(controller.game!, 0);
    await controller.updateSeating([0, 2, 1], 0);
    expect(controller.game!.seatOrder, [0, 2, 1]);
    expect(controller.game!.turnOrderForRound(0), [2, 0, 1]);
    expect(controller.game!.dealerForRound(0), 1);
    expect(controller.game!.turnOrderForRound(1), [2, 1, 0]);
    expect(controller.game!.dealerForRound(2), 2);
    expect(totalScore(controller.game!, 0), score);
    expect(saved, isNotNull);
  });

  test('a failed seating save leaves the previous dealer in place', () async {
    var failSave = false;
    final controller = GameController(
      storage: GameStorage(
        reader: () async => null,
        writer: (_) async {
          if (failSave) throw StateError('Storage unavailable');
        },
      ),
    );
    await controller.start(['A', 'B', 'C'], 1);
    failSave = true;
    await expectLater(
      controller.updateSeating([0, 2, 1], 0),
      throwsA(isA<GameStorageException>()),
    );
    expect(controller.game!.seatOrder, [0, 1, 2]);
    expect(controller.game!.dealerForRound(0), 2);
  });

  test(
    'early finish excludes drafts and keeps past games after a new game',
    () async {
      String? saved;
      final storage = GameStorage(
        reader: () async => saved,
        writer: (value) async => saved = value,
      );
      final controller = GameController(storage: storage);
      await controller.start(['Alice', 'Bob'], 1);
      await controller.commit(0, {0: 0, 1: 0}, {0: 1, 1: 0});
      await controller.saveDraft(1, {0: 1, 1: 0}, {0: 1});
      await controller.finishEarly();

      expect(controller.game!.isFinished, isTrue);
      expect(controller.game!.roundsPlayed, 1);
      expect(controller.game!.history, hasLength(1));
      expect(controller.game!.history.single.scores, [1, 10]);
      expect(controller.game!.history.single.endedEarly, isTrue);

      await controller.start(['Bob', 'Alice'], 1);
      expect(controller.game!.history, hasLength(1));
      final reloaded = GameController(storage: storage);
      await reloaded.load();
      expect(reloaded.game!.history.single.players, ['Alice', 'Bob']);
      expect(reloaded.game!.history.single.scores, [1, 10]);
    },
  );

  test(
    'completed games archive once and a correction updates final scores',
    () async {
      final controller = GameController(
        storage: GameStorage(reader: () async => null, writer: (_) async {}),
      );
      await controller.start(['Alice', 'Bob'], 1);
      for (var index = 0; index < controller.game!.rounds.length; index++) {
        await controller.commit(index, {0: 0, 1: 0}, {0: 1, 1: 0});
      }
      expect(controller.game!.history, hasLength(1));
      final finishedAt = controller.game!.history.single.finishedAt;
      await controller.commit(0, {0: 1, 1: 0}, {0: 1, 1: 0});
      expect(controller.game!.history, hasLength(1));
      expect(controller.game!.history.single.finishedAt, finishedAt);
      expect(controller.game!.history.single.scores, [13, 30]);
    },
  );

  test('failed early-finish save leaves the game active', () async {
    var failSave = false;
    final controller = GameController(
      storage: GameStorage(
        reader: () async => null,
        writer: (_) async {
          if (failSave) throw StateError('Storage unavailable');
        },
      ),
    );
    await controller.start(['Alice', 'Bob'], 1);
    await controller.commit(0, {0: 0, 1: 0}, {0: 1, 1: 0});
    failSave = true;
    await expectLater(
      controller.finishEarly(),
      throwsA(isA<GameStorageException>()),
    );
    expect(controller.game!.isFinished, isFalse);
    expect(controller.game!.history, isEmpty);
  });

  test('older saved games retain entered call order and scores', () {
    final old = WhistGame(
      players: ['A', 'B', 'C'],
      startingCards: 1,
      rounds: generateRounds(1),
    );
    old.rounds[0]
      ..calls.addAll({0: 0, 1: 0, 2: 0})
      ..wins.addAll({0: 1, 1: 0, 2: 0})
      ..completed = true;
    old.rounds[1].calls[0] = 0;
    final json = old.toJson();
    json['version'] = 1;
    json.remove('seatOrder');
    for (final round in json['rounds']! as List<dynamic>) {
      (round as Map<String, Object?>)
        ..remove('dealer')
        ..remove('turnOrder');
    }
    final loaded = WhistGame.fromJson(json);
    expect(loaded.turnOrderForRound(0), [0, 1, 2]);
    expect(loaded.turnOrderForRound(1), [0, 1, 2]);
    expect(loaded.dealerForRound(2), 0);
    expect(loaded.turnOrderForRound(2), [1, 2, 0]);
    expect(totalScore(loaded, 0), 1);
  });

  test('scoring includes exact and zero-call bonuses', () {
    expect(roundScore(4, 4), 14);
    expect(roundScore(4, 3), 3);
    expect(roundScore(0, 0), 10);
    expect(roundScore(0, 2), 2);
  });

  test('final prediction restriction', () {
    expect(forbiddenFinalCall(9, [3, 3]), 3);
    expect(forbiddenFinalCall(3, [2, 2]), isNull);
    expect(validCalls(9, [3, 3, 3]), isFalse);
    expect(validCalls(9, [3, 3, 2]), isTrue);
  });

  test('result total must match tricks available', () {
    expect(validResults(7, [2, 3, 2]), isTrue);
    expect(validResults(7, [2, 3, 1]), isFalse);
    expect(validResults(7, [8, -1, 0]), isFalse);
  });

  test('totals derive from completed rounds and update after correction', () {
    final game = WhistGame(
      players: ['A', 'B'],
      startingCards: 2,
      rounds: [
        GameRound(
          cards: 2,
          blind: false,
          calls: {0: 1, 1: 0},
          wins: {0: 1, 1: 1},
          completed: true,
        ),
        GameRound(
          cards: 1,
          blind: false,
          calls: {0: 0, 1: 0},
          wins: {0: 0, 1: 1},
          completed: true,
        ),
      ],
    );
    expect(totalScore(game, 0, throughRound: 0), 11);
    expect(totalScore(game, 0), 21);
    expect(totalScore(game, 1), 2);
    game.rounds[0].wins[0] = 0;
    game.rounds[0].wins[1] = 2;
    expect(totalScore(game, 0, throughRound: 0), 0);
    expect(totalScore(game, 0), 10);
    expect(totalScore(game, 1), 3);
  });

  test('game serialization retains draft and completed rounds', () {
    final game = WhistGame(
      players: ['A', 'B'],
      startingCards: 1,
      rounds: [
        GameRound(
          cards: 1,
          blind: false,
          calls: {0: 0, 1: 0},
          wins: {0: 1, 1: 0},
          completed: true,
        ),
        GameRound(cards: 1, blind: true, calls: {0: 1}),
      ],
    );
    final loaded = WhistGame.fromJson(game.toJson());
    expect(loaded.currentRoundIndex, 1);
    expect(loaded.rounds[1].calls[0], 1);
    expect(loaded.rounds[0].completed, isTrue);
  });
}
