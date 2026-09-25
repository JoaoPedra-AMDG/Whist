import 'package:web/web.dart' as web;

const _key = 'whist_game_v1';

Future<String?> loadGame() async => web.window.localStorage.getItem(_key);

Future<void> saveGame(String value) async {
  web.window.localStorage.setItem(_key, value);
}
