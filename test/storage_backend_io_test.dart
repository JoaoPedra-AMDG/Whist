import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:whist/services/storage_backend_io.dart';

void main() {
  test('desktop game file saves and reloads updated data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'whist-storage-test-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}game.json');
    try {
      expect(await readGameFile(file), isNull);
      await writeGameFile(file, '{"round":1}');
      expect(await readGameFile(file), '{"round":1}');
      await writeGameFile(file, '{"round":2}');
      expect(await readGameFile(file), '{"round":2}');
    } finally {
      if (await file.exists()) await file.delete();
      await directory.delete();
    }
  });
}
