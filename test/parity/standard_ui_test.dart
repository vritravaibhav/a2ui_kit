// Parity tests of CopilotKit's standard catalog, ported from
// packages/react-core/src/v2/generative-ui/standard/__tests__/
// standard-ui.test.tsx and its fixture fixtures/standard-all.json (MIT,
// (c) Atai Barkai). Our copy of the fixture,
// test/fixtures/copilotkit/standard-all.json, is the same file. Each test
// names its upstream line.
//
// Parity for: (engine)
// Signals for: Map
//
// standard-ui.test.tsx tests the standard catalog as a whole: its groups
// and the fixture that uses every standard component once. It ports no
// component's own tests, so the components the fixture renders are no
// parity coverage of theirs (RULEBOOK section 6, item 2); the three it
// keeps as signals are named above.
//
// `standardUI` is a2uiKitStandardCatalog(), and its manifest is the
// `components` of the catalog document that catalog writes (`toJson`).
// The group objects (`layoutComponents` and the others) take their names
// from the declarations in packages/shared/src/generative-ui/standard/,
// written out below in their order. The fixture goes in as it is: its ids
// (`s-layout`) pass the app's `A2uiIdNormalizer`, as renderStandard
// sends every message (a2ui_core itself rejects such ids).
//
// Not ported (bound to internals): none.
//
// Later phase (no Dart yet):
// - :72 one of the five texts it finds, and the `vi.mock("maplibre-gl")`
//   (file top) that makes the Map show its list of places: "Graz" (the
//   Map's list of places: Map). The title, "Linus" (a template row: Table,
//   TableSection, TableRow, TableCell), "Walk dog" (List items from a
//   template: List, ListItem), "Café Central" (EntityCard) and the absence
//   of a reported error are ported. "Graz" is expected absent while the
//   Map draws nothing, so the test fails, as a signal to port it, once it
//   is built.

import 'dart:convert';

import 'package:a2ui_kit/a2ui_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart' show fixture;
import '../helpers/parity.dart';

/// The standard groups in the order of `standardDeclarations`
/// (packages/shared/src/generative-ui/standard/declarations.ts:15), each
/// in its declaration order: the keys of `layoutComponents`,
/// `textComponents`, `inputComponents`, `feedbackComponents`,
/// `dataComponents`, `mediaComponents` and `compositeComponents`.
const List<List<String>> _groups = [
  // layoutDeclarations (layout.ts:212).
  [
    'Box',
    'Column',
    'Row',
    'Grid',
    'GridItem',
    'Card',
    'Flow',
    'FlowItem',
    'Carousel',
    'CarouselItem',
    'CarouselMediaItem',
    'Spacer',
    'Divider',
    'Tabs',
  ],
  // textDeclarations (text.ts:134).
  [
    'Title',
    'Text',
    'Caption',
    'Label',
    'Bold',
    'Italic',
    'Underline',
    'Strikethrough',
    'Badge',
    'Blockquote',
    'Code',
    'Markdown',
    'Math',
    'ShimmerText',
    'Link',
    'Tooltip',
  ],
  // inputDeclarations (inputs.ts:326).
  [
    'Button',
    'Pressable',
    'Form',
    'TextField',
    'TextArea',
    'Select',
    'CheckBox',
    'Radio',
    'RadioGroup',
    'Slider',
    'SegmentedControl',
    'ChoicePicker',
    'DateTimeInput',
  ],
  // feedbackDeclarations (feedback.ts:68).
  [
    'PulseIndicator',
    'FlashcardFlip',
    'Popover',
    'PopoverTrigger',
    'PopoverContent',
    'Modal',
  ],
  // dataDeclarations (data.ts:149).
  [
    'Table',
    'TableSection',
    'TableRow',
    'TableCell',
    'List',
    'ListItem',
    'Chart',
    'Map',
  ],
  // mediaDeclarations (media.ts:223).
  ['Image', 'Icon', 'Favicon', 'Svg', 'Video', 'AudioPlayer', 'HtmlView'],
  // compositeDeclarations (composites.ts:108).
  ['LinkCard', 'Citation', 'FollowUp', 'EntityCard', 'ImageGrid'],
];

/// The fixture: it uses every standard component at least once.
final Map<String, Object?> _fixture =
    fixture('standard-all.json')! as Map<String, Object?>;

/// The fixture's components, as CopilotKit's agent sends them.
List<Map<String, Object?>> get _fixtureComponents =>
    (_fixture['components']! as List<Object?>).cast<Map<String, Object?>>();

/// The fixture's data model.
Map<String, Object?> get _fixtureData =>
    _fixture['data']! as Map<String, Object?>;

/// The manifest of [catalog]: the components of its catalog document.
Map<String, Object?> _manifest(CatalogImplementation catalog) =>
    catalog.toJson()['components']! as Map<String, Object?>;

void main() {
  group('standardUI', () {
    // standard-ui.test.tsx:35
    test('has the id copilotkit/standard@1', () {
      expect(a2uiKitStandardCatalog().id, 'copilotkit/standard@1');
    });

    // standard-ui.test.tsx:39
    test('has every component of every group once, each with a '
        'description', () {
      final groupNames = [for (final group in _groups) ...group];
      final catalog = a2uiKitStandardCatalog();
      // A name in two groups would collapse into one entry here.
      expect(catalog.components.keys.toList(), groupNames);
      expect(catalog.components.length, 69);
      for (final MapEntry(key: name, value: component) in _manifest(
        catalog,
      ).entries) {
        expect(
          switch (component) {
            final Map<Object?, Object?> manifest => manifest['description'],
            _ => null,
          },
          matches(RegExp(r'\S')),
          reason: name,
        );
      }
    });

    // standard-ui.test.tsx:59
    test('has a manifest that survives a JSON round trip', () {
      final manifest = _manifest(a2uiKitStandardCatalog());
      expect(jsonDecode(jsonEncode(manifest)), manifest);
    });

    // standard-ui.test.tsx:64
    test('is used in full by the fixture', () {
      final used = {for (final node in _fixtureComponents) node['component']};
      final unused = [
        for (final name in a2uiKitStandardCatalog().components.keys)
          if (!used.contains(name)) name,
      ];
      expect(unused, <String>[]);
    });

    // standard-ui.test.tsx:72
    testWidgets('renders the fixture with no error', (tester) async {
      final view = await renderStandard(
        tester,
        _fixtureComponents,
        data: _fixtureData,
      );
      expect(
        find.text('Standard catalog fixture', findRichText: true),
        findsOneWidget,
      );
      // Template rows, template list items.
      expect(find.text('Linus', findRichText: true), findsOneWidget);
      expect(find.text('Walk dog', findRichText: true), findsOneWidget);
      expect(find.text('Café Central', findRichText: true), findsOneWidget);
      // Later phase: the Map's list of places draws nothing yet. When this
      // fails, the Map is built: port upstream's `getByText` for it here.
      expect(find.text('Graz', findRichText: true), findsNothing);
      expect(view.errors, isEmpty);
    });
  });
}
