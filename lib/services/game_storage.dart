import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/game.dart';

class GameStorage {
  static const _channel = MethodChannel('com.whist.scorekeeper/storage');

  Future<WhistGame?> load() async {
    final value = await _channel.invokeMethod<String>('loadGame');
    if (value == null || value.isEmpty) return null;
    return WhistGame.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> save(WhistGame game) =>
      _channel.invokeMethod<void>('saveGame', jsonEncode(game.toJson()));
}
