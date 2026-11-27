// Parity tests of CopilotKit's Image lightbox and the Button's href and
// copy verbs, ported from
// packages/react-core/src/v2/generative-ui/standard/__tests__/
// composites.test.tsx (MIT, (c) Atai Barkai). Each test names its upstream
// line.
//
// Parity for: Image, Button, FollowUp, EntityCard
//
// FollowUp and EntityCard are ported below. The rest of the composites
// are later phase. The manifest test (:21) reads the group object
// `compositeComponents`; here
// its facts come from the catalog document: the group is the run of five
// names in the standard catalog's order, and the events are the generated
// `eventArguments` (CopilotKit's event declarations). Upstream's
// `window.open` spy is a fake url_launcher platform here
// (`fakeUrlLauncher`: the URL and `webOnlyWindowName: '_blank'`), and its
// `navigator.clipboard.writeText` mock a mock of the platform channel's
// `Clipboard.setData`. The image cache holds a loaded picture for each
// image, since the test binding answers every request with HTTP 400.
//
// Not ported (bound to internals):
// - :313 and :330 find the lightbox by `[data-a2ui-lightbox]` and read its
//   `<img>`'s `src`: here the lightbox is the route over the surface's
//   page, and the URL is the one its image loads.
// - :366 the `window.open` features `noopener,noreferrer`: url_launcher_web
//   opens its new tab without an opener; no platform interface carries
//   them. The URL and the `_blank` window are tested.
// - :400 `data-a2ui-copied` (a data attribute for the copied state): the
//   check mark the copied state shows is tested instead.
//
// Later phase (no Dart yet):
// - :40 "LinkCard renders a new-tab link with domain, title and
//   description" and :57 "LinkCard with a bound onClick is a button that
//   sends the event": LinkCard.
// - :71 "Citation shows its source on click" (beside an inline Text in a
//   Row): Citation.
// - :188 "ImageGrid renders every image and opens the lightbox on click"
//   and :214 "ImageGrid lightbox walks through all images with the arrows
//   and keys": ImageGrid.
// - :241 "CarouselMediaItem opens a lightbox over every slide of its
//   carousel", :272 "CarouselMediaItem with href opens the URL instead of
//   the lightbox" and :293 "CarouselMediaItem renders its image at the
//   size's width": Carousel, CarouselMediaItem.
// - :344 "toggles a Popover when its trigger is a Button": Popover,
//   PopoverTrigger, PopoverContent (the Button only triggers it).
// - :414 "Pressable with href opens the URL": Pressable.

import 'package:a2ui_kit/a2ui_kit.dart';
import 'package:a2ui_kit/src/document/catalog_document.g.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/parity.dart';

/// The Image widgets whose alt text is [alt]: upstream's
/// `findByAltText(alt)`.
Finder _imageWithAlt(String alt) => find.byWidgetPredicate(
  (widget) => widget is Image && widget.semanticLabel == alt,
  description: 'an image with the alt text "$alt"',
);

/// Puts a loaded picture in the image cache for each of [urls], as a
/// browser that loads them.
Future<void> _loaded(WidgetTester tester, List<String> urls) async {
  final picture = (await tester.runAsync(
    () => createTestImage(width: 40, height: 20),
  ))!;
  addTearDown(picture.dispose);
  for (final url in urls) {
    PaintingBinding.instance.imageCache.putIfAbsent(
      NetworkImage(url),
      () => OneFrameImageStreamCompleter(
        SynchronousFuture(ImageInfo(image: picture.clone())),
      ),
    );
  }
  addTearDown(PaintingBinding.instance.imageCache.clear);
}

/// Whether a lightbox is open: upstream's `lightbox()` is not null. The
/// lightbox is the one route these surfaces push over their page.
bool _lightboxOpen(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator)).canPop();

/// The URL of the image the lightbox shows, null when it shows none:
/// upstream's `shownSrc()` (composites.test.tsx:18).
String? _shownSrc(WidgetTester tester) {
  for (final element in find.byType(Image).evaluate()) {
    if (ModalRoute.of<Object?>(element) is! PopupRoute<Object?>) continue;
    if (element.widget case Image(:final NetworkImage image)) {
      return image.url;
    }
  }
  return null;
}

/// The button named [name]: upstream's `findByRole("button", { name })`.
Finder _button(WidgetTester tester, String name) {
  final button = find.bySemanticsLabel(name);
  expect(tester.getSemantics(button), isSemantics(isButton: true));
  return button;
}

/// The description of [name] in the catalog document.
Object? _description(String name) =>
    switch ((a2uiKitCatalogDocument['components']! as Map)[name]) {
      final Map<Object?, Object?> component => component['description'],
      _ => null,
    };

void main() {
  group('compositeComponents', () {
    // composites.test.tsx:21
    test('is valid input for createGenerativeUI, with a description for '
        'every component', () {
      const names = [
        'LinkCard',
        'Citation',
        'FollowUp',
        'EntityCard',
        'ImageGrid',
      ];
      final start = standardComponentNames.indexOf(names.first);
      expect(
        standardComponentNames.sublist(start, start + names.length),
        names,
      );
      // `toEqual` on the group's keys fails on an extra member too: the
      // composites are the last group of the catalog.
      expect(start + names.length, standardComponentNames.length);
      for (final name in names) {
        expect(_description(name), matches(RegExp(r'\S')), reason: name);
      }
      expect(eventArguments['FollowUp'], contains('onFollowUp'));
    });
  });

  group('Image lightbox and Popover trigger', () {
    // composites.test.tsx:313
    testWidgets('opens the image full-screen on click and closes on Escape', (
      tester,
    ) async {
      await _loaded(tester, ['https://example.com/a.png']);
      await renderStandard(tester, [
        {
          'id': 'root',
          'component': 'Image',
          'url': 'https://example.com/a.png',
          'description': 'A',
        },
      ]);
      final image = _imageWithAlt('A');
      expect(image, findsOneWidget);
      expect(_lightboxOpen(tester), isFalse);
      await tester.tap(image);
      await tester.pumpAndSettle();
      expect(_shownSrc(tester), 'https://example.com/a.png');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_lightboxOpen(tester), isFalse);
    });

    // composites.test.tsx:330
    testWidgets('does not open a lightbox when lightbox is false', (
      tester,
    ) async {
      await _loaded(tester, ['https://example.com/b.png']);
      await renderStandard(tester, [
        {
          'id': 'root',
          'component': 'Image',
          'url': 'https://example.com/b.png',
          'description': 'B',
          'lightbox': false,
        },
      ]);
      await tester.tap(_imageWithAlt('B'));
      await tester.pumpAndSettle();
      expect(_lightboxOpen(tester), isFalse);
    });
  });

  group('Button and Pressable client-side verbs', () {
    // composites.test.tsx:366
    testWidgets('Button with href opens the URL in a new tab and does not '
        'dispatch', (tester) async {
      final launcher = fakeUrlLauncher();
      final view = await renderStandard(tester, [
        {
          'id': 'root',
          'component': 'Button',
          'label': 'Docs',
          'href': 'https://docs.copilotkit.ai',
          'onClick': {
            'event': {'name': 'never'},
          },
        },
      ]);
      await tester.tap(_button(tester, 'Docs'));
      await tester.pump();
      expect(
        launcher.opened,
        contains(openedInNewTab('https://docs.copilotkit.ai')),
      );
      expect(view.actions, isEmpty);
    });

    // composites.test.tsx:386
    testWidgets('Button with href ignores unsafe schemes', (tester) async {
      final launcher = fakeUrlLauncher();
      await renderStandard(tester, [
        {
          'id': 'root',
          'component': 'Button',
          'label': 'Bad',
          'href': 'javascript:alert(1)',
        },
      ]);
      await tester.tap(_button(tester, 'Bad'));
      await tester.pump();
      expect(launcher.launches, isEmpty);
    });

    // composites.test.tsx:400
    testWidgets('Button with copy writes to the clipboard and shows a check', (
      tester,
    ) async {
      final written = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') written.add(call.arguments);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await renderStandard(tester, [
        {
          'id': 'root',
          'component': 'Button',
          'label': 'Copy code',
          'copy': 'ABC-123',
        },
      ]);
      final button = _button(tester, 'Copy code');
      await tester.tap(button);
      await tester.pump();
      // toHaveBeenCalledWith("ABC-123").
      expect(written, anyElement(equals({'text': 'ABC-123'})));
      // The copied state (data-a2ui-copied) shows a check.
      expect(
        find.descendant(
          of: button,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is LucideGlyph &&
                widget.icon ==
                    lucideIcon('check', release: LucideRelease.reactCore),
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('FollowUp and EntityCard', () {
    // composites.test.tsx:99
    testWidgets("FollowUp dispatches the item's message as an action", (
      tester,
    ) async {
      final view = await renderStandard(tester, [
        {
          'id': 'root',
          'component': 'FollowUp',
          'title': 'Next',
          'items': [
            'Cheaper version',
            {'label': 'Luxury', 'message': 'Make it luxury'},
          ],
          'onFollowUp': {
            'event': {'name': 'follow_up'},
          },
        },
      ]);
      await tester.tap(_button(tester, 'Luxury'));
      await tester.pump();
      expect(view.actions, hasLength(1));
      expect(view.actions.single.name, 'follow_up');
      expect(view.actions.single.context, {'message': 'Make it luxury'});
    });

    // composites.test.tsx:119
    testWidgets('FollowUp sends its message without an onFollowUp binding', (
      tester,
    ) async {
      final view = await renderStandard(tester, [
        {
          'id': 'root',
          'component': 'FollowUp',
          'items': ['Make it cheaper'],
        },
      ]);
      await tester.tap(_button(tester, 'Make it cheaper'));
      await tester.pump();
      final action = view.actions.single;
      expect(action.name, 'follow_up');
      expect(action.sourceComponentId, 'root');
      expect(action.userMessage, 'Make it cheaper');
    });

    // composites.test.tsx:136
    testWidgets('EntityCard renders title, meta, badge, rating and action '
        'buttons', (tester) async {
      final view = await renderStandard(tester, [
        {
          'id': 'root',
          'component': 'EntityCard',
          'title': 'Café Central',
          'subtitle': 'Coffee house',
          'description': 'Grand historic café.',
          'meta': 'Open until 22:00',
          'badge': {'label': 'Popular', 'color': 'success'},
          'rating': 4.5,
          'ratingCount': 1200,
          'actions': [
            {'label': 'Pick'},
          ],
          'onAction': {
            'event': {'name': 'pick'},
          },
        },
      ]);
      expect(find.text('Café Central'), findsOneWidget);
      expect(find.text('Open until 22:00'), findsOneWidget);
      expect(find.text('Popular'), findsOneWidget);
      expect(find.bySemanticsLabel('4.5 out of 5'), findsOneWidget);
      await tester.tap(_button(tester, 'Pick'));
      await tester.pump();
      expect(view.actions, hasLength(1));
      expect(view.actions.single.name, 'pick');
      expect(view.actions.single.context, {'label': 'Pick'});
    });

    // composites.test.tsx:162
    testWidgets('EntityCard with href opens the page and a button with href '
        'opens its URL', (tester) async {
      final launcher = fakeUrlLauncher();
      final view = await renderStandard(tester, [
        {
          'id': 'root',
          'component': 'EntityCard',
          'title': 'Sacher',
          'href': 'https://sacher.example',
          'actions': [
            {'label': 'Directions', 'href': 'https://maps.example'},
          ],
        },
      ]);
      await tester.tap(_button(tester, 'Directions'));
      await tester.pump();
      await tester.tap(find.text('Sacher'));
      await tester.pump();
      expect(launcher.opened, [
        openedInNewTab('https://maps.example'),
        openedInNewTab('https://sacher.example'),
      ]);
      expect(view.actions, isEmpty);
    });
  });
}
