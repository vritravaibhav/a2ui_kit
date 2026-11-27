// Widget tests of the playground's Section, Heading, Stat, StatGroup,
// KeyValueList, Agenda, Timeline, ComparisonTable, Progress, Rating,
// TagList, Quote, Alert and Callout, after its renderers (layout, content,
// data and feedback .tsx).

import 'package:a2ui_kit/a2ui_kit.dart';
import 'package:a2ui_kit/src/components/playground/data_display/kpi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

final _light = A2uiKitTheme.playground(Brightness.light);

Map<String, Object?> _root(Map<String, Object?> props) => {
  'id': 'root',
  ...props,
};

/// The font size the KPI at [label] is drawn at.
double _kpiFontSize(WidgetTester tester, String label) {
  final render = tester.renderObject<RenderKpiText>(
    find.descendant(
      of: find.bySemanticsLabel(label),
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_KpiText',
      ),
    ),
  );
  return render.fontSizeFor(render.constraints.maxWidth);
}

/// Expects [count] KPI values, each laid out within its box, with no
/// overflow reported.
void _expectKpisInside(WidgetTester tester, {required int count}) {
  final renders = tester
      .renderObjectList<RenderKpiText>(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_KpiText'),
      )
      .toList();
  expect(renders, hasLength(count));
  for (final render in renders) {
    expect(
      render.contentWidth,
      lessThanOrEqualTo(render.size.width + .01),
      reason: render.text,
    );
    expect(
      render.size.width,
      lessThanOrEqualTo(render.constraints.maxWidth + .01),
    );
  }
  expect(tester.takeException(), isNull);
}

void main() {
  group('Section', () {
    testWidgets('title, eyebrow on its line, description, children', (
      tester,
    ) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'Section',
          'eyebrow': 'Overview',
          'title': 'This week',
          'description': 'Activity across your workspace.',
          'children': ['t'],
        }),
        {'id': 't', 'component': 'Text', 'text': 'Child'},
      ]);
      final title = tester.getRect(find.text('This week'));
      final eyebrow = tester.getRect(find.text('Overview'));
      expect(eyebrow.left, greaterThan(title.right));
      expect(
        tester.getRect(find.text('Activity across your workspace.')).top,
        greaterThan(title.bottom),
      );
      expect(
        tester.getRect(find.text('Child', findRichText: true)).top,
        greaterThanOrEqualTo(
          tester.getRect(find.text('Activity across your workspace.')).bottom +
              12,
        ),
      );
      expect(tester.widget<Text>(find.text('This week')).style!.fontSize, 15);
    });
  });

  group('Heading', () {
    testWidgets('is a header; level sets the size; words fade in', (
      tester,
    ) async {
      await pumpComponents(tester, theme: _light, [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['a', 'b'],
        },
        {
          'id': 'a',
          'component': 'Heading',
          'text': 'Three days in Tokyo',
          'eyebrow': 'Trip plan',
          'subtitle': 'Food markets and temples.',
        },
        {'id': 'b', 'component': 'Heading', 'text': 'Small', 'level': '3'},
      ]);
      await tester.pumpAndSettle();
      final big = tester.widget<RichText>(
        find.text('Three days in Tokyo', findRichText: true),
      );
      expect(big.text.style!.fontSize, 19);
      final small = tester.widget<RichText>(
        find.text('Small', findRichText: true),
      );
      expect(small.text.style!.fontSize, 15.5);
      final semantics = tester.getSemantics(
        find.text('Three days in Tokyo', findRichText: true),
      );
      expect(semantics.flagsCollection.isHeader, isTrue);
      expect(find.text('Trip plan'), findsOneWidget);
    });

    testWidgets('a grown text fades in only its new words', (tester) async {
      final surfaces = await pumpComponents(
        tester,
        [
          _root({
            'component': 'Heading',
            'text': {'@path': '/t'},
          }),
        ],
        data: {'t': 'Hello'},
      );
      await tester.pumpAndSettle();
      surfaces.setData('/t', 'Hello there world');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      final rich = tester.widget<RichText>(
        find.text('Hello there world', findRichText: true),
      );
      final spans = <TextSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
      // "Hello" keeps its colour; "there" and "world" are still fading.
      expect(spans.first.text, 'Hello');
      expect(spans.first.style, isNull);
      expect(spans.last.text, 'world');
      expect(spans.last.style!.color!.a, lessThan(.5));
      await tester.pumpAndSettle();
    });

    testWidgets('words still fading keep fading when the text grows', (
      tester,
    ) async {
      final surfaces = await pumpComponents(
        tester,
        [
          _root({
            'component': 'Heading',
            'text': {'@path': '/t'},
          }),
        ],
        data: {'t': 'Hello there'},
      );
      await tester.pump(const Duration(milliseconds: 100));
      double alphaOf(String text, String word) {
        var alpha = 1.0;
        tester
            .widget<RichText>(find.text(text, findRichText: true))
            .text
            .visitChildren((span) {
              if (span is TextSpan && span.text == word) {
                alpha = span.style?.color?.a ?? 1;
              }
              return true;
            });
        return alpha;
      }

      final before = alphaOf('Hello there', 'there');
      expect(before, lessThan(1));
      surfaces.setData('/t', 'Hello there world');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // "there" goes on from where it was, rather than showing at once.
      final after = alphaOf('Hello there world', 'there');
      expect(after, greaterThanOrEqualTo(before));
      expect(after, lessThan(1));
      expect(alphaOf('Hello there world', 'world'), lessThan(after));
      await tester.pumpAndSettle();
      expect(alphaOf('Hello there world', 'there'), 1);
      expect(alphaOf('Hello there world', 'world'), 1);
    });
  });

  group('Stat', () {
    testWidgets('label, value, delta and caption; the icon takes the tone', (
      tester,
    ) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'Stat',
          'label': 'Monthly recurring revenue',
          'value': r'$48.2k',
          'delta': '-12.4%',
          'caption': 'vs. September',
          'icon': 'trending-up',
          'tone': 'positive',
        }),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Monthly recurring revenue'), findsOneWidget);
      expect(find.bySemanticsLabel(r'$48.2k'), findsOneWidget);
      expect(find.text('vs. September'), findsOneWidget);
      // A minus sign: down, in the negative tone.
      final delta = tester.widget<Text>(find.text('-12.4%'));
      expect(
        delta.style!.color,
        _light.playground.toneColor(A2uiTone.negative),
      );
      final glyphs = tester.widgetList<LucideGlyph>(find.byType(LucideGlyph));
      // lucide-react 1.57.0, the playground's.
      expect(glyphs.map((g) => g.icon), [
        lucideIcon('trending-up', release: LucideRelease.playground),
        lucideImport('ArrowDownRight', LucideRelease.playground),
      ]);
      expect(
        glyphs.first.color,
        _light.playground.toneColor(A2uiTone.positive),
      );
    });

    testWidgets("the value's size follows the card's width", (tester) async {
      await pumpComponents(tester, width: 320, [
        {
          'id': 'root',
          'component': 'Row',
          'children': ['a', 'b'],
        },
        {'id': 'a', 'component': 'Stat', 'label': 'A', 'value': '42'},
        {
          'id': 'b',
          'component': 'Stat',
          'label': 'B',
          'value': '1,234,567,890',
        },
      ]);
      await tester.pumpAndSettle();
      // Two Stats in a Row 8px apart share it equally (flex: 1 1 0%): each
      // card is 156px, its content 122px.
      final a = tester.getRect(find.text('A'));
      final b = tester.getRect(find.text('B'));
      expect(b.left - a.left, closeTo(156 + 8, 1));
      // A short value reaches the 26px ceiling; a long one fits the card:
      // at most 122 / (.62 × 13 characters), less where the font's glyphs
      // are wider than .62em (the test font's are 1em), so it stays inside.
      expect(_kpiFontSize(tester, '42'), 26);
      final long = _kpiFontSize(tester, '1,234,567,890');
      expect(long, lessThanOrEqualTo(122 / (.62 * 13)));
      expect(long, closeTo(122 / (.975 * 13), .1));
      _expectKpisInside(tester, count: 2);
    });

    testWidgets('the glyphs are measured once for a text, not per layout', (
      tester,
    ) async {
      final surfaces = await pumpComponents(tester, width: 320, [
        {
          'id': 'root',
          'component': 'Stat',
          'label': 'B',
          'value': '1,234,567,890',
        },
      ]);
      await tester.pumpAndSettle();
      final render = tester.renderObject<RenderKpiText>(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_KpiText'),
      );
      expect(render.debugSizeMeasures, 1);
      // Other widths scale the one measure: text width is linear in size.
      final at122 = render.fontSizeFor(122);
      expect(render.fontSizeFor(61), closeTo(at122 / 2, 1e-9));
      render.markNeedsLayout();
      await tester.pump();
      expect(render.debugSizeMeasures, 1);
      _expectKpisInside(tester, count: 1);
      // A new text is measured again.
      surfaces.apply([
        {
          'version': '1.0',
          'updateComponents': {
            'surfaceId': testSurfaceId,
            'components': [
              {
                'id': 'root',
                'component': 'Stat',
                'label': 'B',
                'value': '9,876,543,210,000',
              },
            ],
          },
        },
      ]);
      await tester.pumpAndSettle();
      expect(render.debugSizeMeasures, 2);
      _expectKpisInside(tester, count: 1);
      // Review 2a A2: a font that arrives later (fontsChange) clears the
      // measure, and the next layout measures again.
      await tester.binding.handleSystemMessage({'type': 'fontsChange'});
      await tester.pumpAndSettle();
      expect(render.debugSizeMeasures, 3);
      _expectKpisInside(tester, count: 1);
    });

    testWidgets('at text scale 2 a value in a Row at 320px stays in its card', (
      tester,
    ) async {
      await pumpComponents(tester, width: 320, textScale: 2, [
        {
          'id': 'root',
          'component': 'Row',
          'children': ['a', 'b'],
        },
        {'id': 'a', 'component': 'Stat', 'label': 'A', 'value': 1234567.89},
        {
          'id': 'b',
          'component': 'Stat',
          'label': 'B',
          'value': 'Ongoing maintenance window',
        },
      ]);
      await tester.pumpAndSettle();
      _expectKpisInside(tester, count: 2);
    });

    testWidgets('numbers are formatted en-US', (tester) async {
      await pumpComponents(tester, [
        _root({'component': 'Stat', 'label': 'Units', 'value': 1234567.891}),
      ]);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('1,234,567.89'), findsOneWidget);
    });
  });

  group('StatGroup', () {
    testWidgets('cells in 132px columns; empty is an 80px card', (
      tester,
    ) async {
      await pumpComponents(tester, width: 600, [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['g', 'e'],
        },
        {
          'id': 'g',
          'component': 'StatGroup',
          'items': [
            {'label': 'Visitors', 'value': '84,210', 'delta': '+8.1%'},
            {'label': 'Signups', 'value': 2318},
            {
              'label': 'Avg. session',
              'value': '4m 12s',
              'delta': '0.0%',
              'trend': 'flat',
            },
          ],
        },
        {'id': 'e', 'component': 'StatGroup', 'items': <Object?>[]},
      ]);
      await tester.pumpAndSettle();
      final visitors = tester.getRect(find.text('Visitors'));
      final signups = tester.getRect(find.text('Signups'));
      final session = tester.getRect(find.text('Avg. session'));
      // 600px holds four 132px columns; three items fill three of them,
      // and auto-fit collapses the empty fourth.
      expect(signups.top, visitors.top);
      expect(session.top, visitors.top);
      expect(find.bySemanticsLabel('2,318'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('0.0%')).style!.color,
        _light.playground.mutedForeground,
      );
    });
  });

  testWidgets('at text scale 2 each StatGroup cell holds its value', (
    tester,
  ) async {
    await pumpComponents(tester, width: 320, textScale: 2, [
      {
        'id': 'root',
        'component': 'StatGroup',
        'items': [
          {'label': 'Revenue', 'value': r'$1,234,567.89', 'delta': '+8.1%'},
          {'label': 'Orders', 'value': 23185412},
          {'label': 'Status', 'value': 'Degraded performance everywhere'},
        ],
      },
    ]);
    await tester.pumpAndSettle();
    _expectKpisInside(tester, count: 3);
  });

  group('KeyValueList', () {
    final items = [
      {'label': 'Placed', 'value': 'Oct 14, 2026', 'hint': '9:42 AM PT'},
      {'label': 'Items', 'value': 3000},
      {'label': 'Total', 'value': r'$236.40'},
    ];

    testWidgets('label left, value right on one line', (tester) async {
      await pumpComponents(tester, width: 400, [
        _root({'component': 'KeyValueList', 'title': 'Order', 'items': items}),
      ]);
      expect(find.text('Order'), findsOneWidget);
      final label = tester.getRect(find.text('Items'));
      final value = tester.getRect(find.text('3,000').hitTestable());
      expect(value.left, greaterThan(label.right));
      // Right-aligned against the card's 16px padding and 1px border.
      expect(value.right, closeTo(400 - 17, 1));
      expect(find.text('9:42 AM PT').hitTestable(), findsOneWidget);
    });

    testWidgets('under 256px the label sits over the value', (tester) async {
      await pumpComponents(tester, width: 240, [
        _root({'component': 'KeyValueList', 'items': items}),
      ]);
      final label = tester.getRect(find.text('Items'));
      final value = tester.getRect(find.text('3,000').hitTestable());
      expect(value.top, greaterThan(label.bottom));
      expect(value.left, label.left);
    });

    testWidgets('columns: 2 from a 448px card', (tester) async {
      await pumpComponents(tester, width: 520, [
        _root({'component': 'KeyValueList', 'items': items, 'columns': 2}),
      ]);
      final placed = tester.getRect(find.text('Placed'));
      final count = tester.getRect(find.text('Items'));
      expect(count.top, placed.top);
      expect(count.left, greaterThan(placed.left + 200));
    });
  });

  group('Alert', () {
    testWidgets('tones pick the palette and icon; it is a status', (
      tester,
    ) async {
      await pumpComponents(tester, theme: _light, [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['a', 'b', 'c', 'd'],
        },
        {
          'id': 'a',
          'component': 'Alert',
          'tone': 'warning',
          'title': 'Usage at 92%',
          'message': 'You will hit the limit in 3 days.',
        },
        {'id': 'b', 'component': 'Alert', 'title': 'Heads up'},
        {'id': 'c', 'component': 'Alert', 'tone': 'success', 'title': 'Saved'},
        {'id': 'd', 'component': 'Alert', 'tone': 'error', 'title': 'Failed'},
      ]);
      final warning = _light.playground.alerts[AlertTone.warning]!;
      expect(
        tester.widget<Text>(find.text('Usage at 92%')).style!.color,
        warning.foreground,
      );
      final glyphs = tester.widgetList<LucideGlyph>(find.byType(LucideGlyph));
      // `AlertTriangle`, `Info`, `CheckCircle2` and `XCircle`
      // (feedback.tsx:27, :17, :22, :32), lucide-react 1.57.0's: each alias
      // draws its icon.
      LucideIconNode playground(String name) =>
          lucideIcon(name, release: LucideRelease.playground)!;
      expect(glyphs.map((g) => g.icon), [
        playground('triangle-alert'),
        playground('info'),
        playground('circle-check'),
        playground('circle-x'),
      ]);
      // 1.0 redrew circle-check: the playground's, not react-core's.
      expect(
        glyphs.elementAt(2).icon,
        isNot(lucideIcon('circle-check', release: LucideRelease.reactCore)),
      );
      expect(
        tester.getSemantics(find.text('Heads up')).getSemanticsData().role,
        isNotNull,
      );
    });
  });

  group('Callout', () {
    testWidgets('the button shows only when onAction is bound', (tester) async {
      final surfaces = await pumpComponents(tester, [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['a', 'b'],
        },
        {
          'id': 'a',
          'component': 'Callout',
          'title': 'Tip',
          'text': 'Fixed-schema surfaces paint at once.',
          'actionLabel': 'Learn more',
          'onAction': {
            'event': {'name': 'learn_more'},
          },
        },
        {
          'id': 'b',
          'component': 'Callout',
          'text': 'No action here.',
          'actionLabel': 'Hidden',
        },
      ]);
      expect(find.text('Hidden'), findsNothing);
      await tester.tap(find.text('Learn more'));
      await tester.pump();
      expect(surfaces.actions.map((a) => a.name), ['learn_more']);
      expect(surfaces.actions.single.context, isEmpty);
      // The tile always shows a lightbulb.
      expect(
        tester.widgetList<LucideGlyph>(find.byType(LucideGlyph)).first.icon,
        lucideIcon('lightbulb', release: LucideRelease.playground),
      );
    });

    testWidgets('wraps the button under the text at 320px, text scale 2', (
      tester,
    ) async {
      await pumpComponents(tester, width: 320, textScale: 2, [
        _root({
          'component': 'Callout',
          'title': 'Tip',
          'text': 'Fixed-schema surfaces paint as soon as the data lands.',
          'actionLabel': 'Learn more',
          'onAction': {
            'event': {'name': 'x'},
          },
        }),
      ]);
      expect(tester.takeException(), isNull);
    });
  });

  group('Agenda', () {
    final accent = _light.playground.toneColor(A2uiTone.accent);
    final info = _light.playground.toneColor(A2uiTone.info);

    testWidgets('draws days, times, and an empty day', (tester) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'Agenda',
          'title': 'Launch week',
          'days': [
            {
              'date': '2026-11-24',
              'events': [
                {
                  'time': '09:30',
                  'title': 'Kickoff',
                  'speaker': 'Ada Lovelace',
                  'location': 'Hall A',
                  'description': 'Goals for the week and the demo path.',
                  'tone': 'accent',
                },
                {'title': 'Office hours', 'location': 'Room 2', 'tone': 'info'},
              ],
            },
            {'date': '2026-11-25', 'label': 'Ship', 'events': <Object?>[]},
            {'date': 'not-a-date', 'events': <Object?>[]},
          ],
        }),
      ]);
      expect(
        tester.getSemantics(find.text('Launch week')).flagsCollection.isHeader,
        isTrue,
      );
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('Nov'), findsWidgets);
      expect(find.text('Kickoff'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Hall A'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget);
      expect(find.text('All day'), findsOneWidget);
      expect(find.text('Ship'), findsOneWidget);
      expect(find.text('Wed'), findsNothing);
      expect(find.text('Nothing scheduled'), findsNWidgets(2));
      expect(find.text('not-a-date'), findsOneWidget);
      final bars = tester
          .widgetList<Container>(
            find.byWidgetPredicate((widget) {
              final decoration = widget is Container ? widget.decoration : null;
              return decoration is BoxDecoration &&
                  decoration.borderRadius == BorderRadius.circular(999);
            }),
          )
          .map((bar) => (bar.decoration! as BoxDecoration).color)
          .toList();
      expect(bars, [accent, info]);
      expect(
        tester.widget<LucideGlyph>(find.byType(LucideGlyph).first).icon.name,
        'MapPin',
      );
    });

    testWidgets('an omitted tone walks the chart palette', (tester) async {
      final chart = _light.playground.chart;
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'Agenda',
          'days': [
            {
              'date': '2026-11-24',
              'events': [
                {'title': 'Kickoff'},
                {'title': 'Review'},
              ],
            },
            {
              'date': '2026-11-25',
              'events': [
                {'title': 'Ship'},
              ],
            },
          ],
        }),
      ]);
      final bars = tester
          .widgetList<Container>(
            find.byWidgetPredicate((widget) {
              final decoration = widget is Container ? widget.decoration : null;
              return decoration is BoxDecoration &&
                  decoration.borderRadius == BorderRadius.circular(999);
            }),
          )
          .map((bar) => (bar.decoration! as BoxDecoration).color)
          .toList();
      expect(bars, [chart[0], chart[1], chart[2]]);
    });

    testWidgets('resolves a bound title', (tester) async {
      await pumpComponents(
        tester,
        [
          _root({
            'component': 'Agenda',
            'title': {'@path': '/title'},
            'days': [
              {
                'date': '2026-11-24',
                'events': [
                  {'title': 'Kickoff'},
                ],
              },
            ],
          }),
        ],
        data: {'title': 'Bound week'},
      );
      expect(find.text('Bound week'), findsOneWidget);
      expect(find.text('Kickoff'), findsOneWidget);
    });
  });

  group('Timeline', () {
    final tokens = _light.playground;
    final positive = tokens.toneColor(A2uiTone.positive);
    final accent = tokens.toneColor(A2uiTone.accent);

    testWidgets('draws status, time, and a custom icon', (tester) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'Timeline',
          'items': [
            {
              'title': 'Brief signed',
              'time': 'Mon',
              'description': 'The scope is locked.',
              'status': 'done',
            },
            {
              'title': 'Build the demo',
              'time': '',
              'description': 'In review.',
              'status': 'current',
              'icon': 'flag',
            },
            {'title': 'Ship', 'status': 'upcoming'},
          ],
        }),
      ]);
      expect(find.text('Brief signed'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('The scope is locked.'), findsOneWidget);
      expect(find.text('Build the demo'), findsOneWidget);
      expect(find.text(''), findsNothing);
      expect(find.text('Ship'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Ship')).style!.color,
        tokens.foreground.withValues(alpha: tokens.foreground.a * .65),
      );
      expect(
        tester.widget<Text>(find.text('Brief signed')).style!.color,
        tokens.foreground,
      );
      final glyphs = tester
          .widgetList<LucideGlyph>(find.byType(LucideGlyph))
          .map((glyph) => glyph.icon.name)
          .toList();
      expect(glyphs, ['Check', 'Flag']);
      final nodes = tester
          .widgetList<Container>(
            find.byWidgetPredicate((widget) {
              final decoration = widget is Container ? widget.decoration : null;
              return decoration is BoxDecoration &&
                  decoration.shape == BoxShape.circle &&
                  decoration.border != null;
            }),
          )
          .map((node) => (node.decoration! as BoxDecoration).border)
          .toList();
      expect((nodes[0]! as Border).top.color, const Color(0x00000000));
      expect((nodes[1]! as Border).top.color, accent);
      expect((nodes[2]! as Border).top.color, tokens.lineStrong);
      final connectors = tester
          .widgetList<ColoredBox>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is ColoredBox &&
                  widget.child is SizedBox &&
                  (widget.child! as SizedBox).width == 1,
            ),
          )
          .map((box) => box.color)
          .toList();
      expect(connectors, [positive.withValues(alpha: .45), tokens.lineStrong]);
    });

    testWidgets('treats a missing status as done', (tester) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'Timeline',
          'items': [
            {'title': 'Started'},
          ],
        }),
      ]);
      expect(
        tester.widget<LucideGlyph>(find.byType(LucideGlyph)).icon.name,
        'Check',
      );
    });

    testWidgets('resolves bound items', (tester) async {
      await pumpComponents(
        tester,
        [
          _root({
            'component': 'Timeline',
            'items': {'@path': '/items'},
          }),
        ],
        data: {
          'items': [
            {'title': 'Bound step', 'time': 'Tue'},
          ],
        },
      );
      expect(find.text('Bound step'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
    });
  });

  group('ComparisonTable', () {
    final tokens = _light.playground;
    final accent = tokens.toneColor(A2uiTone.accent);
    final tint = accent.withValues(alpha: .07);

    testWidgets('compares options and marks the highlight', (tester) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'ComparisonTable',
          'title': 'Plans',
          'highlight': 1,
          'options': ['Starter', 'Team', 'Scale'],
          'rows': [
            {
              'feature': 'Seats',
              'values': ['3', 'Unlimited', ''],
            },
            {
              'feature': 'SSO',
              'values': [false, true, true],
            },
            {
              'feature': 'Price',
              'values': [12, 1200],
            },
          ],
        }),
      ]);
      expect(
        tester.getSemantics(find.text('Plans')).flagsCollection.isHeader,
        isTrue,
      );
      expect(find.text('Feature'), findsOneWidget);
      expect(find.text('Starter'), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Seats'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Unlimited'), findsOneWidget);
      expect(find.text('-'), findsNWidgets(2));
      expect(find.text('1,200'), findsOneWidget);
      expect(find.bySemanticsLabel('Yes'), findsNWidgets(2));
      expect(find.bySemanticsLabel('No'), findsOneWidget);
      final tinted = tester
          .widgetList<Container>(
            find.byWidgetPredicate((widget) {
              if (widget is! Container) return false;
              final decoration = widget.decoration;
              if (decoration is BoxDecoration && decoration.color == tint) {
                return true;
              }
              return widget.color == tint;
            }),
          )
          .length;
      // The highlighted option's header plus one cell per row.
      expect(tinted, 4);
      final badge = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Recommended'),
              matching: find.byType(Container),
            )
            .first,
      );
      final badgeDecoration = badge.decoration! as BoxDecoration;
      expect(badgeDecoration.color, accent.withValues(alpha: .14));
      expect(badgeDecoration.borderRadius, BorderRadius.circular(999));
    });

    testWidgets('grows the recommended chip with the text scale', (
      tester,
    ) async {
      Future<Size> labelAt(double textScale) async {
        await pumpComponents(
          tester,
          theme: _light,
          textScale: textScale,
          width: 720,
          [
            _root({
              'component': 'ComparisonTable',
              'highlight': 0,
              'options': ['Pro'],
              'rows': [
                {
                  'feature': 'SSO',
                  'values': [true],
                },
              ],
            }),
          ],
        );
        expect(tester.takeException(), isNull);
        return tester.getSize(find.text('Recommended'));
      }

      final normal = await labelAt(1);
      final huge = await labelAt(2);
      expect(huge.width, greaterThan(normal.width * 1.8));
      expect(huge.height, greaterThan(normal.height * 1.8));
      final chip = tester.getSize(
        find
            .ancestor(
              of: find.text('Recommended'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(chip.width, greaterThanOrEqualTo(huge.width));
      expect(chip.height, greaterThanOrEqualTo(huge.height));
    });

    testWidgets('fills the highlight when the mark is shorter than the row', (
      tester,
    ) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'ComparisonTable',
          'highlight': 1,
          'options': ['Starter', 'Pro', 'Enterprise'],
          'rows': [
            {
              'feature': 'Dedicated support',
              'values': [false, false, true],
            },
          ],
        }),
      ]);
      final cells = tester
          .renderObjectList<RenderBox>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.padding ==
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          )
          .toList();
      expect(cells, hasLength(3));
      expect(cells.map((cell) => cell.size.height).toSet(), hasLength(1));
      final highlighted = cells[1];
      expect(highlighted.size.height, greaterThan(14 + 20));
    });

    testWidgets('ignores a highlight that is not a whole number', (
      tester,
    ) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'ComparisonTable',
          'options': ['A', 'B'],
          'highlight': 1.5,
          'rows': [
            {
              'feature': 'Ready',
              'values': [true, false],
            },
          ],
        }),
      ]);
      expect(find.text('Recommended'), findsNothing);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('resolves a bound title', (tester) async {
      await pumpComponents(
        tester,
        [
          _root({
            'component': 'ComparisonTable',
            'title': {'@path': '/title'},
            'options': ['A'],
            'rows': [
              {
                'feature': 'Ready',
                'values': [true],
              },
            ],
          }),
        ],
        data: {'title': 'Bound plans'},
      );
      expect(find.text('Bound plans'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
    });
  });

  group('Progress', () {
    testWidgets('draws the label, the rounded percent and the caption', (
      tester,
    ) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'Progress',
          'label': 'Storage used',
          'value': 72,
          'caption': '72 GB of 100 GB, resets Nov 1',
          'tone': 'accent',
        }),
      ]);
      expect(find.text('Storage used'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('72 GB of 100 GB, resets Nov 1'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox &&
              widget.color == _light.playground.toneColor(A2uiTone.accent),
        ),
        findsOneWidget,
      );
    });

    testWidgets('clamps the value to 0-100 and falls back to accent', (
      tester,
    ) async {
      await pumpComponents(tester, theme: _light, [
        _root({'component': 'Progress', 'label': 'Over', 'value': 140}),
      ]);
      expect(find.text('100%'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox &&
              widget.color == _light.playground.toneColor(A2uiTone.accent),
        ),
        findsOneWidget,
      );
    });

    testWidgets('reads a bound value', (tester) async {
      await pumpComponents(
        tester,
        theme: _light,
        [
          _root({
            'component': 'Progress',
            'label': 'Used',
            'value': {'@path': '/used'},
          }),
        ],
        data: {'used': 40},
      );
      expect(find.text('40%'), findsOneWidget);
    });
  });

  group('Rating', () {
    testWidgets('draws the stars, one decimal and the review count', (
      tester,
    ) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'Rating',
          'value': 4.6,
          'count': 1284,
          'label': 'Customer rating',
        }),
      ]);
      expect(find.text('Customer rating'), findsOneWidget);
      expect(find.text('4.6'), findsOneWidget);
      expect(find.text('1,284 reviews'), findsOneWidget);
      expect(find.bySemanticsLabel('4.6 out of 5 stars'), findsOneWidget);
    });

    testWidgets('clamps a value above 5', (tester) async {
      await pumpComponents(tester, theme: _light, [
        _root({'component': 'Rating', 'value': 9}),
      ]);
      expect(find.text('5.0'), findsOneWidget);
      expect(find.bySemanticsLabel('5.0 out of 5 stars'), findsOneWidget);
    });
  });

  group('TagList', () {
    testWidgets('draws each tag as a chip', (tester) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'TagList',
          'tags': ['TypeScript', 'React 19', 'pnpm'],
        }),
      ]);
      expect(find.text('TypeScript'), findsOneWidget);
      expect(find.text('React 19'), findsOneWidget);
      expect(find.text('pnpm'), findsOneWidget);
    });

    testWidgets('skips empty tags', (tester) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'TagList',
          'tags': ['Alpha', '', 'Beta'],
        }),
      ]);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text(''), findsNothing);
    });
  });

  group('Quote', () {
    testWidgets('draws the quote, author and role', (tester) async {
      await pumpComponents(tester, theme: _light, [
        _root({
          'component': 'Quote',
          'text': 'The best interface is already filled in.',
          'author': 'Maya Chen',
          'role': 'Head of Design',
        }),
      ]);
      expect(
        find.text('The best interface is already filled in.'),
        findsOneWidget,
      );
      expect(find.textContaining('Maya Chen'), findsOneWidget);
      expect(find.textContaining('Head of Design'), findsOneWidget);
      expect(
        tester.widget<LucideGlyph>(find.byType(LucideGlyph)).icon.name,
        'Quote',
      );
    });
  });

  group('Agenda multiline', () {
    testWidgets('lets a long description wrap past two lines', (tester) async {
      const long =
          'Goals for the week, the demo path, the fallback plan, '
          'and every follow-up the launch owners still owe before Friday.';
      await pumpComponents(tester, theme: _light, width: 320, [
        _root({
          'component': 'Agenda',
          'days': [
            {
              'date': '2026-11-24',
              'events': [
                {'time': '09:30', 'title': 'Kickoff', 'description': long},
              ],
            },
          ],
        }),
      ]);
      final text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, isNull);
      expect(tester.getSize(find.text(long)).height, greaterThan(30));
    });
  });
}
