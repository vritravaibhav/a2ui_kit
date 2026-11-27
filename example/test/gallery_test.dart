import 'package:a2ui_kit_example/main.dart';
import 'package:a2ui_kit_example/replays.dart';
import 'package:a2ui_kit_example/samples.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the sample menu and chooses [name], scrolling the menu when the
/// entry sits below the fold.
Future<void> _chooseSample(WidgetTester tester, String name) async {
  await tester.tap(find.byType(DropdownButton<String>));
  await tester.pumpAndSettle();
  final item = find.text(name).last;
  await tester.scrollUntilVisible(
    item,
    48,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the gallery shows every sample without an error', (
    tester,
  ) async {
    // Blueprint's outline keeps flowing, so a settle would not finish.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const GalleryApp());
    expect(find.text('This week'), findsOneWidget);
    for (final name in gallerySamples.keys.skip(1)) {
      await _chooseSample(tester, name);
      expect(tester.takeException(), isNull, reason: name);
    }
  });

  for (final name in replayNames) {
    testWidgets('plays the $name replay frame by frame', (tester) async {
      final replay = (await tester.runAsync(() => Replay.load(name)))!;
      expect(replay.frames, isNotEmpty);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ReplayView(replay: replay)),
          ),
        ),
      );
      final count = replay.frames.length;
      expect(find.textContaining('Frame 1 of $count'), findsOneWidget);
      for (var frame = 2; frame <= count; frame++) {
        await tester.tap(find.byTooltip('Next frame'));
        await tester.pump();
        expect(
          find.textContaining('Frame $frame of $count'),
          findsOneWidget,
          reason: '$name frame $frame',
        );
        expect(tester.takeException(), isNull, reason: '$name frame $frame');
      }
      // Back one frame, then play from the start to the end.
      await tester.tap(find.byTooltip('Previous frame'));
      await tester.pump();
      expect(find.textContaining('Frame ${count - 1} of'), findsOneWidget);
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.textContaining('Frame $count of $count'), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);
      // The last frame still holds Blueprint stand-ins, whose outline
      // keeps flowing.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();
    });
  }

  testWidgets('a replay entry of the menu loads and plays the replay', (
    tester,
  ) async {
    await tester.pumpWidget(
      GalleryApp(initialSample: replayEntry('lisbon-weather')),
    );
    // The replay loads from the asset bundle.
    for (var i = 0; i < 10 && find.byType(ReplayView).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.textContaining('Frame 1 of 2'), findsOneWidget);
    expect(find.text(replayEntry('lisbon-weather')), findsOneWidget);
  });

  testWidgets('switches brightness and the three looks', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.tap(find.byTooltip('Brightness'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Look'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('This week'), findsOneWidget);
    }
  });

  testWidgets('shows an action with the agent ids', (tester) async {
    // The walk passes Blueprint, whose outline keeps flowing.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const GalleryApp());
    // The menu builds the items near the chosen one: step through them.
    for (final name in gallerySamples.keys.skip(1)) {
      await _chooseSample(tester, name);
      if (name == 'Callout') break;
    }
    await tester.ensureVisible(find.text('Learn more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learn more'));
    await tester.pump();
    expect(find.text('learn_more {}'), findsOneWidget);
  });
}
