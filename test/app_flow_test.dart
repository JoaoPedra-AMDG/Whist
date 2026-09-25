import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whist/app.dart';
import 'package:whist/logic/game_controller.dart';
import 'package:whist/logic/game_rules.dart';
import 'package:whist/models/game.dart';
import 'package:whist/services/game_storage.dart';

void main() {
  testWidgets('failed saves explain the problem and never advance the round', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    String? savedGame;
    var failNextSave = false;
    final storage = GameStorage(
      reader: () async => savedGame,
      writer: (value) async {
        if (failNextSave) {
          failNextSave = false;
          throw StateError('Device storage is full');
        }
        savedGame = value;
      },
    );
    final controller = GameController(storage: storage);
    var step = 0;
    Future<void> settle() async {
      await tester.pumpAndSettle();
      step++;
      final error = tester.takeException();
      if (error != null) {
        fail('Layout or framework error at step $step: $error');
      }
    }

    await tester.pumpWidget(WhistApp(gameController: controller));
    await settle();
    await tester.tap(find.text('New game'));
    await settle();

    await tester.enterText(find.byType(TextField), 'John');
    await tester.tap(find.byTooltip('Next player'));
    await settle();
    await tester.enterText(find.byType(TextField), 'Sarah');
    await tester.tap(find.byTooltip('Next player'));
    await settle();
    await tester.enterText(find.byType(TextField), 'Michael');
    await tester.tap(find.text('Start game'));
    await settle();

    expect(find.text('ROUND 1 OF 21'), findsOneWidget);
    await tester.tap(find.text('Enter predictions'));
    await settle();
    await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
    await settle();
    await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
    await settle();
    failNextSave = true;
    await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
    await settle();

    expect(find.text('Retry save'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Play round'))
          .onPressed,
      isNull,
    );
    expect(controller.game!.rounds.first.calls.length, 2);
    await tester.tap(find.text('Details'));
    await settle();
    expect(find.textContaining('Device storage is full'), findsWidgets);
    await tester.tap(find.text('Close'));
    await settle();
    await tester.tap(find.text('Retry save'));
    await settle();
    await tester.tap(find.text('Play round'));
    await settle();

    await tester.tap(find.text('Enter results'));
    await settle();
    await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
    await settle();
    await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
    await settle();
    await tester.tap(find.widgetWithText(OutlinedButton, '10').first);
    await settle();

    failNextSave = true;
    await tester.tap(find.text('Confirm round'));
    await settle();
    expect(controller.game!.currentRoundIndex, 0);
    expect(find.text('Confirm round'), findsOneWidget);
    await tester.tap(find.text('Details'));
    await settle();
    expect(find.textContaining('Device storage is full'), findsWidgets);
    await tester.tap(find.text('Close'));
    await settle();
    await tester.tap(find.text('Confirm round'));
    await settle();

    expect(find.text('ROUND 2 OF 21'), findsOneWidget);
    expect(controller.game!.currentRoundIndex, 1);
    expect(savedGame, isNotNull);
  });

  testWidgets('rules and final results fit a compact phone', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final game = WhistGame(
      players: ['John', 'Sarah', 'Michael'],
      startingCards: 1,
      rounds: generateRounds(1),
    );
    for (final round in game.rounds) {
      round.calls.addAll({0: 0, 1: 0, 2: 0});
      round.wins.addAll({0: 1, 1: 0, 2: 0});
      round.completed = true;
    }
    final data = jsonEncode(game.toJson());
    final controller = GameController(
      storage: GameStorage(reader: () async => data, writer: (_) async {}),
    );
    await tester.pumpWidget(WhistApp(gameController: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View final results'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next player'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Return home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    for (var page = 1; page < 6; page++) {
      await tester.tap(find.byTooltip('Next rule'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
