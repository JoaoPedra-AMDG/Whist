import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/game_record.dart';
import '../services/game_storage.dart';
import 'game_rules.dart';
import 'scoring.dart';
import 'seating.dart';

class GameController extends ChangeNotifier {
  GameController({GameStorage? storage}) : _storage = storage ?? GameStorage();

  final GameStorage _storage;
  WhistGame? game;
  bool loading = true;
  String? loadError;

  Future<void> load() async {
    try {
      game = await _storage.load();
      if (game?.isFinished ?? false) _archive(game!);
    } catch (error) {
      loadError = '$error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> start(
    List<String> players,
    int cards, {
    int? firstDealer,
  }) async {
    final seats = List<int>.generate(players.length, (index) => index);
    var dealer = firstDealer ?? players.length - 1;
    if (!seats.contains(dealer)) {
      throw ArgumentError.value(dealer, 'firstDealer');
    }
    final rounds = generateRounds(cards);
    for (final round in rounds) {
      round.dealer = dealer;
      round.turnOrder = callingOrder(seats, dealer);
      dealer = nextDealer(seats, dealer);
    }
    final previous = game == null ? null : WhistGame.fromJson(game!.toJson());
    if (previous?.isFinished ?? false) _archive(previous!);
    final next = WhistGame(
      players: List.of(players),
      startingCards: cards,
      rounds: rounds,
      seatOrder: seats,
      history: previous?.history,
    );
    await _storage.save(next);
    game = next;
    notifyListeners();
  }

  Future<void> updateSeating(List<int> seats, int currentDealer) async {
    final current = game!;
    if (current.isFinished ||
        seats.length != current.players.length ||
        seats.toSet().length != seats.length ||
        !seats.toSet().containsAll(
          List<int>.generate(current.players.length, (index) => index),
        ) ||
        !seats.contains(currentDealer)) {
      throw ArgumentError('Choose each player once and a current dealer.');
    }
    final next = WhistGame.fromJson(current.toJson());
    final roundIndex = current.currentRoundIndex;
    for (var index = 0; index < roundIndex; index++) {
      next.rounds[index].dealer ??= current.dealerForRound(index);
      next.rounds[index].turnOrder ??= current.turnOrderForRound(index);
    }
    next.seatOrder
      ..clear()
      ..addAll(seats);
    var dealer = currentDealer;
    for (var index = roundIndex; index < next.rounds.length; index++) {
      next.rounds[index].dealer = dealer;
      next.rounds[index].turnOrder = callingOrder(seats, dealer);
      dealer = nextDealer(seats, dealer);
    }
    await _storage.save(next);
    game = next;
    notifyListeners();
  }

  Future<void> saveDraft(
    int index,
    Map<int, int> calls,
    Map<int, int> wins,
  ) async {
    final next = WhistGame.fromJson(game!.toJson());
    final round = next.rounds[index];
    if (round.completed) return;
    round.calls
      ..clear()
      ..addAll(calls);
    round.wins
      ..clear()
      ..addAll(wins);
    await _storage.save(next);
    game = next;
    notifyListeners();
  }

  Future<void> commit(
    int index,
    Map<int, int> calls,
    Map<int, int> wins,
  ) async {
    final next = WhistGame.fromJson(game!.toJson());
    final round = next.rounds[index];
    round.calls
      ..clear()
      ..addAll(calls);
    round.wins
      ..clear()
      ..addAll(wins);
    round.completed = true;
    if (next.isFinished) _archive(next);
    await _storage.save(next);
    game = next;
    notifyListeners();
  }

  Future<void> finishEarly() async {
    final current = game!;
    if (current.isFinished || current.roundsPlayed == 0) {
      throw StateError('Complete at least one round before finishing.');
    }
    final next = WhistGame.fromJson(current.toJson());
    next.endedEarly = true;
    _archive(next);
    await _storage.save(next);
    game = next;
    notifyListeners();
  }

  void _archive(WhistGame target) {
    final previous = target.history.indexWhere(
      (record) => record.id == target.id,
    );
    final record = GameRecord(
      id: target.id,
      finishedAt:
          previous < 0 ? DateTime.now() : target.history[previous].finishedAt,
      endedEarly: target.endedEarly,
      roundsPlayed: target.roundsPlayed,
      totalRounds: target.rounds.length,
      players: target.players,
      scores: [
        for (var index = 0; index < target.players.length; index++)
          totalScore(target, index),
      ],
    );
    if (previous < 0) {
      target.history.add(record);
    } else {
      target.history[previous] = record;
    }
  }
}
