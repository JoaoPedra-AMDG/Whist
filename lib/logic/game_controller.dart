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
    } catch (_) {
      loadError = 'The saved game could not be opened.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> start(List<String> players, int cards) async {
    game = WhistGame(
      players: List.of(players),
      startingCards: cards,
      rounds: generateRounds(cards),
    );
    notifyListeners();
    await _storage.save(game!);
  }

  Future<void> saveDraft(
    int index,
    Map<int, int> calls,
    Map<int, int> wins,
  ) async {
    final round = game!.rounds[index];
    if (round.completed) return;
    round.calls
      ..clear()
      ..addAll(calls);
    round.wins
      ..clear()
      ..addAll(wins);
    notifyListeners();
    await _storage.save(game!);
  }

  Future<void> commit(
    int index,
    Map<int, int> calls,
    Map<int, int> wins,
  ) async {
    final round = game!.rounds[index];
    round.calls
      ..clear()
      ..addAll(calls);
    round.wins
      ..clear()
      ..addAll(wins);
    round.completed = true;
    notifyListeners();
    await _storage.save(game!);
  }
}
