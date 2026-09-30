import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whist/app.dart';
import 'package:whist/logic/game_controller.dart';
import 'package:whist/logic/game_rules.dart';
import 'package:whist/models/game.dart';
import 'package:whist/services/game_storage.dart';
import 'package:whist/screens/game_screen.dart';
import 'package:whist/screens/game_setup_screen.dart';
import 'package:whist/screens/seating_screen.dart';
import 'package:whist/theme/whist_theme.dart';

void main() {
  testWidgets(
    'round entry follows dealer order and keeps actions below scroll',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final controller = GameController(
        storage: GameStorage(reader: () async => null, writer: (_) async {}),
      );
      await controller.start(
        ['John', 'Sarah', 'Michael', 'Anne', 'Peter', 'Lucy'],
        1,
        firstDealer: 0,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildWhistTheme(),
          home: GameScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enter predictions'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.text('Enter predictions'), findsOneWidget);
      expect(
        tester.getBottomRight(find.text('Enter predictions')).dy,
        lessThan(640),
      );
      await tester.tap(find.text('Enter predictions'));
      await tester.pumpAndSettle();
      expect(find.text('Sarah'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
      await tester.pumpAndSettle();
      expect(find.text('Michael'), findsOneWidget);
      for (var turn = 0; turn < 5; turn++) {
        await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Play round'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enter results'));
      await tester.pumpAndSettle();
      expect(find.text('Sarah'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('setup lets players choose the first dealer', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = GameController(
      storage: GameStorage(reader: () async => null, writer: (_) async {}),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWhistTheme(),
        home: GameSetupScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('player-name-1')), 'John');
    await tester.enterText(
      find.byKey(const ValueKey('player-name-2')),
      'Sarah',
    );
    await tester.enterText(
      find.byKey(const ValueKey('player-name-3')),
      'Michael',
    );
    final dealerPicker = find.byType(
      DropdownButtonFormField<TextEditingController>,
    );
    await tester.ensureVisible(dealerPicker);
    await tester.tap(dealerPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sarah').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start game'));
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();
    expect(controller.game!.dealerForRound(0), 1);
    expect(controller.game!.turnOrderForRound(0), [2, 0, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seating controls change the current dealer and seat order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = GameController(
      storage: GameStorage(reader: () async => null, writer: (_) async {}),
    );
    await controller.start(['John', 'Sarah', 'Michael'], 1);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWhistTheme(),
        home: SeatingScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move Sarah later'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Set John as dealer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save seating'));
    await tester.pumpAndSettle();
    expect(controller.game!.seatOrder, [0, 2, 1]);
    expect(controller.game!.dealerForRound(0), 0);
    expect(controller.game!.turnOrderForRound(0), [2, 1, 0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('setup shows all name fields and scrolls to added players', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      WhistApp(
        gameController: GameController(
          storage: GameStorage(reader: () async => null, writer: (_) async {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(3));

    for (var count = 4; count <= 7; count++) {
      await tester.tap(find.text('Add player'));
      await tester.pumpAndSettle();
      final newField = find.byKey(ValueKey('player-name-$count'));
      expect(newField, findsOneWidget);
      expect(tester.getTopLeft(newField).dy, greaterThanOrEqualTo(0));
      expect(tester.getBottomRight(newField).dy, lessThanOrEqualTo(640));
    }
    expect(find.byType(TextField), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });

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

    await tester.enterText(find.byKey(const ValueKey('player-name-1')), 'John');
    await tester.enterText(
      find.byKey(const ValueKey('player-name-2')),
      'Sarah',
    );
    await tester.enterText(
      find.byKey(const ValueKey('player-name-3')),
      'Michael',
    );
    await tester.ensureVisible(find.text('Start game'));
    await settle();
    await tester.tap(find.text('Start game'));
    await settle();

    expect(find.text('ROUND 1 OF 21'), findsOneWidget);
    await tester.tap(find.text('Enter predictions'));
    await settle();
    await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
    await settle();
    await tester.tap(find.widgetWithText(OutlinedButton, '0').first);
    await settle();
    final forbiddenButton = find.widgetWithText(OutlinedButton, '10');
    expect(tester.widget<OutlinedButton>(forbiddenButton).onPressed, isNull);
    expect(
      tester
          .widget<Text>(
            find.descendant(of: forbiddenButton, matching: find.text('10')),
          )
          .style
          ?.color,
      WhistPalette.danger,
    );
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
