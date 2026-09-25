import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/game.dart';
import 'storage_backend_stub.dart'
    if (dart.library.io) 'storage_backend_io.dart'
    if (dart.library.html) 'storage_backend_web.dart'
    as backend;

class GameStorageException implements Exception {
  GameStorageException(this.action, this.cause);

  final String action;
  final Object cause;

  String get guidance {
    if (cause is MissingPluginException) {
      return 'This app build does not include local storage for this platform. Install the updated app and restart it; hot reload is not enough.';
    }
    if (cause is PlatformException) {
      final error = cause as PlatformException;
      return 'Storage reported ${error.code}: ${error.message ?? 'no details'}. Check free space, then try again. If it continues, restart the app.';
    }
    if (cause is FormatException || cause is TypeError) {
      return 'The saved game data could not be read. Keep the app installed and contact support before starting a new game.';
    }
    return '${cause.runtimeType}: $cause. Check available storage and try again; if it continues, restart the app.';
  }

  @override
  String toString() => 'Could not $action. $guidance';
}

class GameStorage {
  GameStorage({
    Future<String?> Function()? reader,
    Future<void> Function(String)? writer,
  }) : _reader = reader ?? backend.loadGame,
       _writer = writer ?? backend.saveGame;

  final Future<String?> Function() _reader;
  final Future<void> Function(String) _writer;

  Future<WhistGame?> load() async {
    try {
      final value = await _reader();
      if (value == null || value.isEmpty) return null;
      return WhistGame.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (error) {
      throw GameStorageException('open the saved game', error);
    }
  }

  Future<void> save(WhistGame game) async {
    try {
      await _writer(jsonEncode(game.toJson()));
    } catch (error) {
      throw GameStorageException('save the game', error);
    }
  }
}
