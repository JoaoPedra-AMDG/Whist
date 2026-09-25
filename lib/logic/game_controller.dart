import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../services/game_storage.dart';
import 'game_rules.dart';

class GameController extends ChangeNotifier {
  GameController({GameStorage? storage}) : _storage = storage ?? GameStorage();

  final GameStorage _storage;
  WhistGame? game;
  bool loading = true;
  String? loadError;

  Future<void> load() async {
    try {
      game = await _storage.load();
    } catch (error) {
      loadError = '$error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> start(List<String> players, int cards) async {
    final next = WhistGame(
      players: List.of(players),
      startingCards: cards,
      rounds: generateRounds(cards),
    );
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
    await _storage.save(next);
    game = next;
    notifyListeners();
  }
}
