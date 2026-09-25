import 'package:flutter_test/flutter_test.dart';
import 'package:whist/logic/game_rules.dart';
import 'package:whist/logic/scoring.dart';
import 'package:whist/models/game.dart';

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
