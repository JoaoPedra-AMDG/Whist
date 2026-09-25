import 'dart:io';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.whist.scorekeeper/storage');

bool get _isPhone => Platform.isAndroid || Platform.isIOS;

File get _gameFile {
  final environment = Platform.environment;
  late final String base;
  if (Platform.isWindows) {
    final appData = environment['APPDATA'];
    base =
        appData != null && appData.isNotEmpty
            ? appData
            : environment['USERPROFILE'] ?? Directory.current.path;
  } else if (Platform.isMacOS) {
    base =
        '${environment['HOME'] ?? Directory.current.path}/Library/Application Support';
  } else {
    final xdg = environment['XDG_DATA_HOME'];
    base =
        xdg != null && xdg.isNotEmpty
            ? xdg
            : '${environment['HOME'] ?? Directory.current.path}/.local/share';
  }
  return File(
    '$base${Platform.pathSeparator}Whist${Platform.pathSeparator}game.json',
  );
}

Future<String?> loadGame() async {
  if (_isPhone) return _channel.invokeMethod<String>('loadGame');
  return readGameFile(_gameFile);
}

Future<String?> readGameFile(File file) async {
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> saveGame(String value) async {
  if (_isPhone) {
    await _channel.invokeMethod<void>('saveGame', value);
    return;
  }
  await writeGameFile(_gameFile, value);
}

Future<void> writeGameFile(File file, String value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(value, flush: true);
}
