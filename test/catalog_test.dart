import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_kit/a2ui_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/harness.dart';

void main() {
  group('documents', () {
    test('the catalog document is the fixture', () {
      expect(a2uiKitCatalogDocument, fixture('catalog.json'));
    });

    test('the inference document is the fixture', () {
      expect(
        a2uiKitInferenceCatalogDocument,
        fixture('inference-catalog.json'),
      );
    });

    test('the documents are read-only', () {
      expect(
        () => a2uiKitCatalogDocument['title'] = 'x',
        throwsUnsupportedError,
      );
      final components = a2uiKitCatalogDocument['components']! as Map;
      expect(() => components.remove('Box'), throwsUnsupportedError);
    });

    test('a2ui_core reads both documents', () {
      final catalog = Catalog.fromJson(a2uiKitCatalogDocument);
      expect(catalog.id, kA2uiPlaygroundCatalogId);
      expect(catalog.components, hasLength(121));
      expect(catalog.functions, hasLength(16));
      final inference = Catalog.fromJson(a2uiKitInferenceCatalogDocument);
      expect(inference.components, hasLength(124));
    });
  });

  group('a2uiKitCatalog', () {
    final catalog = a2uiKitCatalog();

    test('has the 121 components and 16 functions under the playground id', () {
      expect(catalog.id, kA2uiPlaygroundCatalogId);
      expect(catalog.components, hasLength(121));
      expect(catalog.functions, hasLength(16));
      expect(catalog.protocolVersion, A2uiProtocolVersion.v1_0);
      expect(catalog.title, 'A2UI Playground catalog');
      expect(catalog.instructions, startsWith('## Design rules'));
    });

    test('writes back the exported document', () {
      expect(catalog.toJson(), fixture('catalog.json'));
    });

    test('keeps every schema as exported', () {
      final document = a2uiKitCatalogDocument['components']! as Map;
      for (final component in catalog.components.values) {
        expect(
          component.schema.value,
          document[component.name],
          reason: component.name,
        );
      }
    });

    test('renders the 32 phase 1 components, the 7 phase 2a charts and '
        "tier 1's components", () {
      expect(a2uiKitPortedComponents, {
        // Phase 1a.
        'Box', 'Column', 'Row', 'Grid', 'GridItem', 'Card', 'Spacer', //
        'Divider', 'Title', 'Text', 'Caption', 'Label', 'Badge',
        // Phase 1b.
        'Markdown', 'Link', 'Button', 'Form', 'TextField', 'Select',
        'CheckBox', 'RadioGroup', 'List', 'ListItem', 'Image', 'Icon',
        'Section', 'Heading', 'Stat', 'StatGroup', 'KeyValueList', 'Alert',
        'Callout', 'Agenda', 'Timeline', 'ComparisonTable', 'Progress',
        'Rating', 'FollowUp', 'EntityCard',
        // Phase 2a.
        'Chart', 'LineChart', 'AreaChart', 'BarChart', 'PieChart', //
        'ScatterChart', 'Sparkline',
        // Tier 1: text.
        'Math', 'Bold', 'Italic', 'Underline', 'Strikethrough', 'Code', //
        'Blockquote',
        // Tier 1: tables, drawings and flows.
        'Table', 'TableSection', 'TableRow', 'TableCell', 'Svg', 'Flow', //
        'FlowItem',
      });
    });

    test('finds every child reference the schemas declare', () {
      final refs = catalog.refMap;
      for (final (component, prop) in [
        ('Box', 'children'),
        ('Card', 'child'),
        ('Card', 'children'),
        ('Text', 'children'),
        ('Grid', 'children'),
        ('GridItem', 'children'),
        ('Tooltip', 'trigger'),
        ('Tooltip', 'content'),
        ('Modal', 'trigger'),
        ('Modal', 'content'),
        ('Button', 'child'),
        ('Section', 'children'),
      ]) {
        expect(
          refs.fieldsFor(component).keys,
          contains(prop),
          reason: '$component.$prop',
        );
      }
      for (final (component, prop) in [
        ('Tabs', 'tabs'),
        ('Accordion', 'items'),
      ]) {
        expect(
          refs.fieldsFor(component).keys,
          contains(prop),
          reason: '$component.$prop[].child',
        );
      }
    });
  });

  group('a2uiKitStandardCatalog', () {
    test('has the 69 standard components under the standard id', () {
      final catalog = a2uiKitStandardCatalog();
      expect(catalog.id, kA2uiStandardCatalogId);
      expect(catalog.components, hasLength(69));
      expect(catalog.components.keys.first, 'Box');
      expect(catalog.components.keys.last, 'ImageGrid');
      expect(catalog.components.containsKey('Section'), isFalse);
      expect(catalog.functions, hasLength(16));
      expect(catalog.instructions, isNull);
    });
  });

  group('a2uiKitCatalogPrompt', () {
    test('starts with the design rules and lists every component', () {
      final prompt = a2uiKitCatalogPrompt();
      expect(prompt, startsWith('## Design rules'));
      expect(prompt, contains('\n- Box: '));
      expect(prompt, contains('\n- FlightCard: '));
      expect(prompt, contains('\n- calc: '));
      expect(_componentLines(prompt), hasLength(124));
    });

    test('leaves the macros out on request', () {
      final prompt = a2uiKitCatalogPrompt(macros: false);
      expect(prompt, isNot(contains('\n- FlightCard:')));
      expect(_componentLines(prompt), hasLength(121));
    });
  });

  group('validation', () {
    test('rejects a component without its required props', () async {
      final surfaces = TestSurfaces()
        ..create([
          {'id': 'root', 'component': 'Title'},
        ]);
      addTearDown(surfaces.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(surfaces.errors.first.message, contains('"text"'));
    });

    testWidgets('rejects a macro, which only the server expands', (
      tester,
    ) async {
      final surfaces = TestSurfaces()
        ..create([
          {
            'id': 'root',
            'component': 'FlightCard',
            'airline': 'X',
            'from': 'A',
            'to': 'B',
            'depart': '10:00',
            'arrive': '12:00',
          },
        ]);
      addTearDown(surfaces.dispose);
      await tester.pumpWidget(surfaceApp(surfaces.surface));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        surfaces.errors.map((e) => e.message).join(),
        contains('FlightCard'),
      );
    });
  });
}

/// The component lines of a prompt.
Iterable<String> _componentLines(String prompt) {
  final start = prompt.indexOf('## Components');
  final end = prompt.indexOf('## Functions');
  return prompt
      .substring(start, end)
      .split('\n')
      .where((line) => line.startsWith('- '));
}
