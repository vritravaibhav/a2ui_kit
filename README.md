# a2ui_kit

[![CI](https://github.com/vritravaibhav/a2ui_kit/actions/workflows/ci.yml/badge.svg)](https://github.com/vritravaibhav/a2ui_kit/actions/workflows/ci.yml)

Generative UI for Flutter. Your AI agent sends [A2UI](https://a2ui.org/)
JSON, and a2ui_kit draws it as native Flutter widgets: charts, tables, LaTeX
maths, Markdown, forms, SVG drawings, cards and more, on Android, iOS, the
web and desktop.

It renders the catalog of CopilotKit's A2UI Playground
([a2ui.open.bot](https://a2ui.open.bot)) on
[`a2ui_flutter`](https://pub.dev/packages/a2ui_flutter) and
[`a2ui_core`](https://pub.dev/packages/a2ui_core) (A2UI 1.0), so an agent
written for the playground catalog
(`https://copilotkit.ai/a2ui/catalogs/playground/v1`) drives a Flutter app
unchanged.

![A bar chart, LaTeX maths and a table with spans, drawn by a2ui_kit](https://raw.githubusercontent.com/vritravaibhav/a2ui_kit/main/doc/screenshots/overview.png)

## Why a2ui_kit

- **60 components today**, more in every release: layout, text, maths,
  tables, charts, forms, lists, schedules, ratings and media.
- **The same JSON as the web.** Component names, props and JSON Schemas are
  CopilotKit's, and an agent's messages are checked as CopilotKit checks
  them, with the same error messages back to the agent.
- **Looks right from the start**: the playground's look in light and dark,
  CopilotKit's library look, or your own Material `ColorScheme`.
- **Accessible**: keyboard focus where the browser gives it, screen-reader
  labels, and every chart read as a table of its data.
- **Tested against CopilotKit's own tests**, ported to Dart, in over 1,800
  tests.

## What it draws

| Group | Components |
|---|---|
| Layout | Box, Column, Row, Grid, GridItem, Card, Flow, FlowItem, Section, Spacer, Divider |
| Text | Title, Heading, Text, Caption, Label, Bold, Italic, Underline, Strikethrough, Badge, Blockquote, Code, Markdown, Math, Link |
| Data | Table, TableSection, TableRow, TableCell, List, ListItem, KeyValueList, Stat, StatGroup, Agenda, ComparisonTable, Progress, Rating, Timeline |
| Charts | LineChart, AreaChart, BarChart, PieChart, ScatterChart, Sparkline, Chart |
| Forms | Form, TextField, Select, CheckBox, RadioGroup, Button |
| Cards and prompts | EntityCard, FollowUp |
| Media and notices | Image, Icon, Svg, Alert, Callout |

All 16 functions run, `calc` and `series` included. The catalog's other 61
components (practice cards, maps, more charts, business cards and more) are
in the catalog already, so payloads that use them validate, but they draw
nothing yet: they arrive release by release.

`Blueprint` is outside that catalog. The playground's agent emits it while a
component's props are still streaming (`of`, `h`, `state`, `hideName`).
`A2uiKitOptions(includeBlueprint: true)` draws those frames; the default
catalog leaves the name out, as CopilotKit's exported catalog does.

### Macros

`FlightCard` and `WeatherReport` are model-facing only: the render catalog
does not list them. `a2uiKitMacros` expands each call into the standard
components above (a WeatherReport needs a forecast, or `fetchWeather`).
`ProductCard` still expands only on the server.

## Setup

```yaml
dependencies:
  a2ui_core: ^0.8.0
  a2ui_flutter: ^0.4.0
  a2ui_kit: ^0.1.0
```

```dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/a2ui_kit.dart';

final processor = MessageProcessor<ComponentImplementation>(
  catalogs: [a2uiKitCatalog()],
);

// For each surface the agent creates:
A2uiSurface(surface: surface);
```

`a2uiKitStandardCatalog()` gives the 69 standard components alone, under
CopilotKit's `copilotkit/standard@1` id.

### Operations CopilotKit refuses

CopilotKit checks each operation an agent sends before applying it, and
drops one it refuses with a reason the agent gets back: a version other
than `"1.0"`, a component of an unknown type or with a prop its schema does
not declare, a component that is its own child, a template or data path
with an empty segment, a data prop that calls anything but `@index` and the
basic value functions (`openUrl` runs only from an event), a v0.9
`{"path": "/x"}` binding, a root data write that is no object. `a2ui_core`
takes many of those. Pass the agent's messages through an
`A2uiOperationValidator` first, before the id normaliser below:

```dart
final checks = A2uiOperationValidator(processor);
processor.processMessages(checks.filterMessages(messagesFromAgent));
```

A refused operation reaches `processor.model.onError` with CopilotKit's
reason. A literal `null` on a prop is read as the prop being unset, as in
CopilotKit.

### Component ids from CopilotKit agents

CopilotKit accepts any string as a component id, and its agents write ids
such as `spacer-l` or `mapCard-title`. `a2ui_core` validates A2UI 1.0
strictly and refuses an id that is not an identifier. Put an
`A2uiIdNormalizer` between the agent and the processor: it rewrites such ids
(`spacer-l` becomes `spacer_l`) everywhere the catalog's schemas put a
component reference, and maps them back in what the app sends to the agent.

```dart
final ids = A2uiIdNormalizer();
processor.processMessages(
  ids.normalizeMessages(checks.filterMessages(messagesFromAgent)),
);
processor.model.onAction.subscribe(
  (action) => sendToAgent(ids.outboundAction(action).toJson()),
);
processor.model.onError.subscribe(
  (error) => sendToAgent(ids.outboundError(error).toJson()),
);
```

Use one normaliser per conversation: it remembers each id it rewrote.

### What the user typed stays

Once the user types into a field, its data path belongs to the user, as in
CopilotKit: an agent write to that path, or below it, is dropped, and a write
above it (`/form` for a field on `/form/name`) keeps what the user typed.
Pass the agent's messages through an `A2uiUserOwnedData`, after the id
normaliser:

```dart
final owned = A2uiUserOwnedData(processor);
processor.processMessages(
  owned.filterMessages(
    ids.normalizeMessages(checks.filterMessages(messagesFromAgent)),
  ),
);
```

Ownership ends when the surface is deleted. An override builder that writes
data marks it with `A2uiUserOwnedData.setOwnedValue`.

### When a part can't be shown

As in CopilotKit, a component whose props, once their bindings resolve, do
not fit its schema (a Title's `text` bound to a number) shows "Couldn’t
display this part: invalid props (…)" in its place, and a component that
throws, an override builder included, shows its error with a Retry; a
cyclic reference shows "cyclic reference to …". The siblings keep working,
and each is reported to the surface's `onError`.

## Inputs and forms

TextField, Select, CheckBox and RadioGroup write what the user enters to the
data path their `value` is bound to (`{"@path": "/form/email"}`); a
TextField writes text, also for numbers ("" while a number field holds no
number). A control with a literal `value` keeps the user's edit when the
agent changes the literal. Their `checks` show under them once
the user has left the field or it holds a value, and a Button with a failing
error check is disabled. Inside a Form, a Button with `submit: true` or Enter
in a single-line field submits it: required fields and the `email` and `url`
text fields are checked first, as a browser does, then `onSubmit` is sent.
`A2uiFormScope` and `A2uiFormController` let an override builder take part in
a Form.

`writableProps` and `eventArguments` list which props each component writes
back and which arguments each event sends (a List pick sends its `index`,
`label` and `value` in the event's context).

## Charts

The playground's charts (LineChart, AreaChart, BarChart, PieChart,
ScatterChart, Sparkline) draw as the playground's TanStack Charts
definitions say: its palette, a dashed grid, about five "nice" value ticks,
monotone curves, band and point scales, stacks rounded at their outer end,
padded donut slices, a crosshair and tooltip that follow the pointer, a tap
or the arrow keys, "No data yet" without rows, and a 700ms grow-in (none
under reduced motion). CopilotKit's standard `Chart` draws as recharts
draws it: recharts' ticks and their line breaks, bands, `monotone` curves,
a legend sorted by name, a tooltip that glides into place, and recharts'
keyboard (Left and Right step, Enter shows or hides, Escape hides).
Every chart is read to screen readers as its name and a table of its data.
`A2uiChartColors` (in `A2uiPlaygroundTokens.charts`) holds the axis, grid,
tooltip and highlight colours.

The charts are `CustomPaint`s of ports of the libraries' geometry, not
`fl_chart` charts: `fl_chart` draws neither the playground's curve nor its
band, stack and arc shapes, nor recharts' axes, so the look would differ.

## For agents

- `a2uiKitCatalogDocument` is CopilotKit's exported `catalog.json`, the
  render contract, for inline catalogs in client capabilities.
- `a2uiKitInferenceCatalogDocument` is the model-facing
  `inference-catalog.json`: trimmed descriptions, no styling props, and the
  three server-side macros (FlightCard, ProductCard, WeatherReport).
- `a2uiKitCatalogPrompt()` turns it into a prompt: the playground's design
  rules, then one line per component and function.

`a2uiKitMacros` expands FlightCard and WeatherReport into the standard
components they become (WeatherReport needs a forecast, or
`fetchWeather`). ProductCard still expands only on the server. The render
catalog does not list the macros: a stray one on the wire fails like any
unknown component.

## Look and theme

Surfaces take the hosted playground's look by default: a violet accent, zinc
tinted surfaces and 14px large radii, in the brightness of the ambient
`Theme`. `A2uiKitTheme` holds every token, as a `ThemeExtension`:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      A2uiKitTheme.playground(Brightness.light).withColors({
        A2uiColorToken.accent: const Color(0xffd97706),
      }),
    ],
  ),
);
```

`A2uiKitTheme.standard(brightness)` is CopilotKit's library look (a
near-black accent), and `A2uiKitOptions(look: A2uiKitLook.standard)` makes it
the default of a catalog. In the standard look a surface takes its type from
the app around it, the `DefaultTextStyle`'s font, size, line height, weight
and colour, as CopilotKit's standard surface inherits the chat text's
(`font: inherit; color: inherit`): wrap the surface in a `DefaultTextStyle` to
give it a size (16px and the look's ink stand in where the app gives none).
The playground look sets its own type: 16px, a 1.5 line height and its ink. `A2uiKitTheme.fromColorScheme(scheme)` maps a
Material `ColorScheme` onto the tokens, as the playground's Material design
system does.

Icons are [Lucide](https://lucide.dev)'s, drawn from lucide-react's own icon
nodes as its `<svg>` strokes them, at the release each CopilotKit renderer
draws: 0.525.0 for the standard components (the Icon among them), 1.57.0 for
the playground's own. Names are read as CopilotKit reads them: `arrow-right`,
`ArrowRight`, and the A2UI basic names (`arrowBack`) in the Icon component.
`lucideIcon(name, release: …)` and `LucideGlyph` serve override builders. Lengths follow CopilotKit: a number is 4px steps
for spacing and sizes, pixels for radii and font sizes; a string is CSS
(`12px`, `1rem`, `50%`).

## Overrides

Replace any component's builder, as CopilotKit's `useOverride` does; the
schema stays the catalog's, and the typed props views (`BadgeProps`,
`CardProps`, …) read the props:

```dart
a2uiKitCatalog(
  options: A2uiKitOptions(
    overrides: {
      'Badge': (context, node, props, buildChild) =>
          Chip(label: Text(BadgeProps(props).label ?? '')),
    },
  ),
);
```

## Platforms

Android, iOS, web, macOS, Windows and Linux. Links open with `url_launcher`
(a new tab on the web), or through `A2uiKitOptions.onOpenUrl`.

The `openUrl` function opens only http and https URLs, on CopilotKit's two
paths: on the web a URL resolves against the page, as the browser's `URL`
resolves it (the URL Standard's parser, ported from whatwg-url); elsewhere
only an absolute URL opens. `onOpenUrl` gets the URL as a Dart `Uri`, which
may percent-encode what the URL Standard keeps (a backslash in the query).
On the web a host with a non-ASCII character or an `xn--` label is refused
for now: the IDNA mapping (UTS #46) is not ported yet.

## Differences from the React renderer

| Area | React (CopilotKit) | a2ui_kit |
|---|---|---|
| A component that throws | Its error boundary catches a throw anywhere in its render | A throw inside a widget the builder returns, during that widget's own build or layout, is not caught, and shows Flutter's error widget: Flutter gives a parent no way to catch a descendant's build error |
| The fallback's Retry | A `<button>` inline after the message | The button follows the message as the next item of a wrap, so a message of several lines puts it on a line of its own: the message stays the alert's own label, and the button a node of its own |
| Component ids | Any string, `spacer-l` included | a2ui_core 0.8 rejects ids that are not UAX #31 identifiers under A2UI 1.0: A2uiIdNormalizer rewrites them on the way in and back on the way out. An action's context keeps no data path, so in it every map shaped as a Table cell (its `componentId`, else its `id`) whose id the way in wrote into a Table cell or column of the action's surface goes back with the agent's id, an agent's own record of that shape included. |
| Metadata extension keys | Any key (`acme.track`), read by nothing | a2ui_core 0.8 rejects a component whose `metadata.extensions` has a key that is no UAX #31 identifier: A2uiIdNormalizer rewrites such keys as it rewrites ids (`acme_track`), values kept; none goes back to the agent. |
| Form validation | The browser's: a bubble on the first invalid field | Required, email and URL fields checked the same way; Chrome's message shows under the field |
| Select | The browser's native list; a screen reader hears a combobox, collapsed or expanded, its chosen option selected | A Material menu; Up and Down change the value. For screen readers the control is a button, expanded while its menu is open and valued by the chosen option's label, and each option a button, the chosen one selected: Flutter's combobox role has no semantics checks and fails them in debug |
| Text fields | Native inputs | Material `TextField`s; English Material localizations are supplied when the app has none |
| Markdown | Streamdown: GFM, KaTeX, shiki, mermaid, HTML | GFM and `$$` math; code is not highlighted, mermaid shows as code, HTML as text; Streamdown's default styles, not checked against the playground |
| Math | KaTeX 0.16.27: HTML and MathML in its web fonts | flutter_math_fork 0.7.4 typesets the formula, not KaTeX 0.16.27: a command KaTeX has and neither flutter_math_fork nor this package does shows as an unknown command, its name in KaTeX's red, and such an environment (`CD`) as the whole source in red; `\smash` draws its content at its own height and depth; KaTeX's fonts are flutter_math_fork's copies of them, not KaTeX 0.16.27's files; Screen readers hear the formula's TeX source, where KaTeX gives them MathML: Flutter's semantics has no MathML; A display formula, or an inline formula's piece, wider than its line scrolls sideways from its start; KaTeX's overflows its line, start-aligned, into the page's scroll area, which a Flutter scroll view never takes from what a child paints past its box; The equation numbers of `align`, `gather`, `alignat` and `equation` start at (1) in each formula; KaTeX's count on over the whole page (a CSS counter on `body`) |
| Icons | lucide-react's icons map, loaded on first use (media.tsx:76-103): an Icon draws nothing until it arrives | lucide-react 0.525.0's and 1.57.0's own icon nodes, compiled in: an Icon draws on the first frame |
| A broken image | The browser's broken-image sign | The image's description |
| KPI and heading animations | Fade with a 1–2px blur | Fade without the blur |
| A List's markers | The browser's `::marker` | Drawn as `•` and `n.`; a horizontal list's items align to the top |
| Entrance animations | The playground's surface host animates new nodes | Not ported (they are not the components') |
| Scrollable containers | Items shrink to the box, then the rest scrolls | Items keep their content size along the scroll axis |
| Title in the playground look | Revert to the page's type (the playground's stylesheet) | Same: the heading styles inherit; the standard look uses CopilotKit's h2–h4 fallbacks |
| Colours | `oklch()` gamut-mapped by the browser | Clipped per channel to sRGB |
| Text scale | A `16px` line height stays 16px | Line heights scale with the text |
| Fonts | The page's (Geist in the playground) | The app's; set `A2uiKitTypography.fontFamily` |
| Code's font on the web | The browser's `monospace` | On Flutter web, where only the app's own fonts exist, code draws in flutter_math_fork's KaTeX_Typewriter, the last of the theme's mono fallbacks, unless the app sets `A2uiKitTypography.monoFontFamily` |
| Grid string templates | Any CSS | A string template reads lengths, `fr`, `auto`, `min-content`, `max-content`, `minmax()` and `repeat()`; anything else is equal columns. A bare `Nfr` reads as `minmax(0, Nfr)` where CSS reads `minmax(auto, Nfr)`, so an `fr` column never widens to its content's min-content; `minmax(a, b)` reads as b when b is `fr` or a content keyword, else as a; and an item spanning several columns does not widen the `auto`, `min-content` or `max-content` columns it crosses |
| Grid `rows` | `grid-template-rows`: a count adds empty rows, a template sizes them | Not applied: each row is as tall as its content |
| Grid and Flow spans | `span N` clamped to 10,000,000 grid lines (Chromium 159) | A span or row span past 1,000 is 1,000: each track is sized as an entry of its own, so ten million would take a phone's memory and many seconds of layout; an implicit grid of 1,000 tracks and their gaps already runs far past any screen |
| Shadows | CSS blur | The same Gaussian, converted to Flutter's blur radius |
| Dark playground cards | An `inset 0 1px 0` 4% white top highlight in the card's shadow | Not drawn: Flutter's shadows have no inset (the top sheen gradient is) |
| Functions | `Intl` in the browser's locale | `package:intl` in `A2uiKitOptions.locale`: English currency symbols follow CLDR (`CA$`), other locales `package:intl`'s simple symbols; `formatDate` reads ISO 8601 text and timestamps, not the engine-specific formats `Date` also reads |
| Inline links | Each `<a>` takes the focus where it sits | Tab reaches each link of a Text in order, but the focus scrolls to the Text's start, and the link is tinted rather than outlined |
| Playground charts | TanStack Charts 1.1.0 (SVG), ported from its published source | TanStack's own SVG transitions are not drawn; the playground's CSS wipe-in is (700ms, none under reduced motion); Labels are measured by their advance width and the font's ascent and descent, as Flutter has no ink bounds (TanStack measures the canvas' painted bounds); the hanging baseline is 80% of the ascent, and SVG's middle baseline (the y labels) half an x-height above the alphabetic one, half an em standing in for the x-height: margins and label thinning can differ by a pixel or two; A focused area point's tooltip swatch is its series' colour, where TanStack's is the area's fade (`url(#a2-fade-N)`), which no HTML swatch paints; A pinned tooltip ignores the pointer (TanStack's takes it, so its text can be selected) |
| Standard Chart | recharts 3.10.1 (SVG), loaded lazily (a placeholder, a table if it fails to load) | recharts' geometry is ported to a CustomPaint from recharts 3.10.1's published es6/ source, with d3-shape 3.2.0, d3-scale 4.0.2 and d3-array 3.2.4; No lazy loading, so no placeholder or fallback table; A white box with the label in the surface's text colour, as CopilotKit leaves it: BUG(port); recharts places SVG text by its baseline: the font's alphabetic baseline goes there, d3's cap height (0.71em) moves it, and a slice label's `alignment-baseline: middle` is stood in for by centring the cap height; What leaves the chart's box, the tooltip included, is clipped as CopilotKit's `overflow-x: auto` box clips it; the scrollbar it would show is not drawn; Other SVG props a row could carry (stroke, opacity, …) and a row's fill on lines and areas are not honoured; A slice label has no font size of its own, so the page's CSS size applies; the surface's text size stands in for it; A data key naming a member every JavaScript object inherits (`constructor`, `toString`) reads as missing, where recharts reads that inherited function; recharts measures tick words in the page's font at the size it last measured; the ticks' own 12px stands in for it; The browser's own focus outline shows when the focus matches `:focus-visible` by Chrome's heuristic (the keyboard's focus; a press's once a key is pressed): a 2px ring at offset 0 in CopilotKit's `outline-ring/50`, round recharts' `<svg>` (the chart's whole box, so the overflow box clips it, as in the browser), the pie's `<g>` (the tight box of its slices) and TanStack's `<svg>`; `outline: auto` is the browser's own drawing, so its exact width and colour differ; A tooltip that shows again glides from where the last one was shown; recharts first moves its hidden, emptied box; The legend's icon has its middle half an x-height above the entry's first baseline, where CSS's `vertical-align: middle` puts it (CSS 2.1 section 10.8.1), the entry in the surface's font (INV-046); Flutter's text API gives no x-height (`dart:ui`'s line metrics give the ascent, descent and baseline only), so CSS's own value for an x-height a browser can't determine, 0.5em (CSS Values 4 section 6.1.1), stands in for the font's |
| Table accessibility | A `<table>` named by its `<caption>`, row groups, rows, `<th scope="col">` and `<th scope="row">` headers | A table node named by the caption, a row node per row, a column-header node per header of a header row and a cell node per other cell; a row header is read as a cell: Flutter's `SemanticsRole` has no row header; a TableSection's envelope name, description and live region apply to nothing (its `hidden` hides its rows): Flutter has no row group node |
| Table scrolling | One box that scrolls both ways (`overflow-x: auto`; with `stickyHeader`, a 480px `max-height`) | Two scroll views, sideways inside downwards: with `stickyHeader` the sideways scrollbar sits under the table, not at the 480px box's bottom |
| Chart text in goldens | SVG text | Painted text: alchemist's CI goldens draw it as black blocks |
| Chart accessibility | TanStack's `ariaLabel`; the standard Chart's `<figure>` and hidden `<table>` | Every chart is an image named by its title, followed by hidden rows that read each cell after its column; The figure is a group named by its title (the `<figure>` named by its `<figcaption>`), its drawing hidden, holding the data table read as CopilotKit's visually hidden `<table>`: a table, a row of column headers, then a row of cells per data row; the row header (`<th scope="row">`) is read as a cell, as Flutter's roles have no row header |

## Credits

Component definitions, descriptions and samples are from CopilotKit (MIT),
© Atai Barkai. The catalog documents in `lib/src/document/` are generated from
CopilotKit's exports; see `NOTICE.md`. a2ui_kit is not affiliated with
CopilotKit. Icons are Lucide's (ISC), from lucide-react's icon nodes.

## License

MIT; see `LICENSE`.
