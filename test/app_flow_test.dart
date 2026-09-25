import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whist/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.whist.scorekeeper/storage');
  String? savedGame;

  setUp(() {
    savedGame = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'loadGame':
          return savedGame;
        case 'saveGame':
          savedGame = call.arguments as String;
          return null;
      }
      throw PlatformException(code: 'unknown_method');
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('create game and enter sequential calls', (tester) async {
    await tester.pumpWidget(const WhistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'John');
    await tester.enterText(fields.at(1), 'Sarah');
    await tester.enterText(fields.at(2), 'Michael');
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();

    expect(find.text('ROUND 1 OF 21'), findsOneWidget);
    expect(savedGame, isNotNull);
    await tester.tap(find.text('Enter predictions'));
    await tester.pumpAndSettle();
    expect(find.text('John'), findsWidgets);
    await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
    await tester.pumpAndSettle();
    expect(find.text('Sarah'), findsWidgets);
  });
}
