// Widget tests of Carousel, CarouselItem and PulseIndicator.

import 'package:a2ui_kit/a2ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

final _standard = A2uiKitTheme.standard(Brightness.light);

void main() {
  group('PulseIndicator', () {
    testWidgets('draws a labelled live dot', (tester) async {
      await pumpComponents(tester, theme: _standard, [
        {'id': 'root', 'component': 'PulseIndicator', 'label': 'Live'},
      ]);
      expect(find.bySemanticsLabel('Live'), findsOneWidget);
    });

    testWidgets('hides an unlabelled dot from semantics', (tester) async {
      await pumpComponents(tester, theme: _standard, [
        {'id': 'root', 'component': 'PulseIndicator'},
      ]);
      expect(find.bySemanticsLabel('Live'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Carousel', () {
    testWidgets('draws its slides and names the region', (tester) async {
      await pumpComponents(tester, theme: _standard, width: 280, [
        {
          'id': 'root',
          'component': 'Carousel',
          'label': 'Release highlights',
          'children': ['s1', 's2', 's3'],
        },
        {
          'id': 's1',
          'component': 'CarouselItem',
          'children': ['s1_t'],
        },
        {'id': 's1_t', 'component': 'Title', 'text': 'Faster deploys'},
        {
          'id': 's2',
          'component': 'CarouselItem',
          'children': ['s2_t'],
        },
        {'id': 's2_t', 'component': 'Title', 'text': 'Audit log'},
        {
          'id': 's3',
          'component': 'CarouselItem',
          'children': ['s3_t'],
        },
        {'id': 's3_t', 'component': 'Title', 'text': 'Usage alerts'},
      ]);
      expect(find.text('Faster deploys'), findsOneWidget);
      expect(find.text('Audit log'), findsOneWidget);
      expect(find.text('Usage alerts'), findsOneWidget);
      expect(find.bySemanticsLabel('Release highlights'), findsOneWidget);
      expect(find.bySemanticsLabel('Next'), findsOneWidget);
      expect(find.bySemanticsLabel('Previous'), findsOneWidget);
    });

    testWidgets('writes activeIndex when the next arrow is pressed', (
      tester,
    ) async {
      final surfaces = await pumpComponents(
        tester,
        theme: _standard,
        width: 200,
        data: {'slide': 0},
        [
          {
            'id': 'root',
            'component': 'Carousel',
            'label': 'Slides',
            'activeIndex': {'@path': '/slide'},
            'children': ['s1', 's2'],
          },
          {
            'id': 's1',
            'component': 'CarouselItem',
            'width': 40,
            'children': ['s1_t'],
          },
          {'id': 's1_t', 'component': 'Title', 'text': 'One'},
          {
            'id': 's2',
            'component': 'CarouselItem',
            'width': 40,
            'children': ['s2_t'],
          },
          {'id': 's2_t', 'component': 'Title', 'text': 'Two'},
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expect(surfaces.surface.dataModel.get('/slide'), 1);
    });
  });
}
