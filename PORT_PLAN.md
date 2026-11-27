# a2ui_kit: port plan

A Flutter package that renders the A2UI catalog of CopilotKit's A2UI Playground (https://a2ui.open.bot): all 121
components, on `a2ui_flutter` 0.4.0 and `a2ui_core` 0.8.0 (A2UI 1.0). The package name `a2ui_kit` is decided (see
[open questions](#10-decisions-and-open-questions)). This file is step 0: it was written from CopilotKit's source, and no Dart code
exists yet.

**Source pin.** CopilotKit (MIT) at commit `ff6f3b03267159cbbf70f9878d988adf4968d022` (2026-11-17; monorepo version
1.89.0). The playground pins `@copilotkit/*` 1.85.0, and its committed export
`examples/showcases/a2ui-playground/src/a2ui/export/catalog.json` is the contract: it equals what
https://a2ui.open.bot/catalog.json served on 2026-11-18 (compared as JSON). A copy is in
`test/fixtures/copilotkit/catalog.json`. Renderer behaviour was read from the React source at the same commit.

**What the lab got wrong.** The earlier prototype lab guessed props from two samples. The real rules differ in
places that show on screen. A numeric `gap` or `padding` is always n × 4px (the lab's "above 8 means pixels" is wrong:
`gap: 16` is 64px). Child references also sit inside arrays (`tabs[].child`, `items[].child`), not only in
`children`. And every prop accepts `{"@path"}` or `{"@call"}`. Sections 2 and 3 and Appendix A replace the guesses.

Contents: [1 Inventory](#1-inventory) · [2 Components](#2-components) · [3 Theming](#3-design-systems-and-theming) ·
[4 Macros](#4-macros) · [5 Architecture](#5-architecture) · [6 Tests](#6-tests) · [7 Review](#7-review) ·
[8 Quality gates](#8-quality-gates-for-pubdev) · [9 Phases](#9-phases) · [10 Decisions and open questions](#10-decisions-and-open-questions) ·
[11 Port notes](#11-port-notes) · [Appendix A: every component and prop](#appendix-a-every-component-and-prop)

---

## 1. Inventory

### Counts

| Set | Count | Groups |
|---|---|---|
| Gen UI 2.0 standard components (`standardUI`) | **69** | Layout 14, Text 16, Inputs 13, Feedback 6, Data 8, Media 7, Composites 5 |
| Playground components | **52** | Layout 2, Content 6, Data display 13, Charts 12, Maps 4, Inputs 5, Feedback 4, Domain 6 |
| **Render catalog** (`catalog.json`) | **121** | the two sets above under one catalog id; no name appears twice |
| Macros (`inference-catalog.json` only) | **3** | FlightCard, ProductCard, WeatherReport; expanded on the server (section 4) |
| Functions (`catalog.json`) | **16** | 14 A2UI basic functions + `calc` and `series` (CopilotKit extensions) |
| Internal stand-in | 1 | `Blueprint`: not in any catalog document, but the playground's agent emits it (Appendix A, end) |

The 69 match CopilotKit's docs ("a catalog of 69 ready-made components") and their group counts. The 52 match the
playground README ("52 of the playground's own"). `inference-catalog.json` holds 124 components: the 121 plus the 3
macros.

### Where the definitions live

| What | Path in the CopilotKit repo |
|---|---|
| Standard declarations (Zod props, descriptions, events, slots, `writable`) | `packages/shared/src/generative-ui/standard/{layout,text,inputs,feedback,data,chart,map,media,composites}.ts`, joined in `declarations.ts` |
| Standard tokens, theme, base stylesheet | `packages/shared/src/generative-ui/standard/{tokens,theme,styles,style-helpers}.ts` |
| Standard React renderers | `packages/react-core/src/v2/generative-ui/standard/*.tsx` (`Chart.tsx` recharts, `Map.tsx` maplibre-gl, `markdown.tsx` Streamdown, `lightbox.tsx`, `overlay-stack.ts`) |
| Function library | signatures `packages/shared/src/generative-ui/basic-functions.ts`; code `packages/core/src/generative-ui/{functions,calc,resolve}.ts` |
| Catalog export (Zod → A2UI 1.0 catalog document) | `packages/shared/src/generative-ui/catalog/catalog-export.ts`, `json-schema.ts` |
| Playground definitions (Zod) | `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/*.ts` (`shared.ts` holds `child()`, `childList()`, `tone`, `def()`) |
| Playground renderers | `…/src/a2ui/catalog/renderers/*.tsx` (+ `chart-kit.tsx`, `format.ts`, `map/`) |
| Playground catalog | `…/src/a2ui/catalog/catalog.ts` (`createGenerativeUI({ id, extends: [standardUI], components })` and `playgroundTheme`) |
| Exported documents | `…/src/a2ui/export/catalog.json` (render), `inference-catalog.json` (model); written by `…/scripts/export-catalog.ts` |
| Samples | `…/src/a2ui/catalog/samples/*.ts`; `packages/react-core/…/standard/__tests__/fixtures/standard-all.json` |
| Macros | `…/src/a2ui/macros/{macro,macros,samples}.ts` |
| Design systems | `…/src/design-systems/` (`themes.ts`, `overrides.ts`, `shadcn.tsx`, `material.tsx`, `byoc.tsx`, `design-systems.css`) |

There are also Vue and Angular ports of the 69 (`packages/vue`, `packages/angular/src/generative-ui`). The Angular one
builds chart.js configs from the framework-free `shared/standard/chart-config.ts`, which helps when a Flutter
behaviour is unclear.

### Catalog ids and wire format

- **`https://copilotkit.ai/a2ui/catalogs/playground/v1`**: the id every playground surface names in `createSurface`
  (`src/a2ui/catalog/ids.ts`). It covers all 121 components, since the playground `extends` the standard set.
- `copilotkit/standard@1`: the standard set alone (`STANDARD_CATALOG_ID`, `shared/standard/tokens.ts`). The playground
  never emits it. The package can offer it as a second catalog of the same 69 schemas (section 5).
- `…/playground/v1/macros`: used only while exporting the macro schemas, never on the wire.
- Messages are A2UI 1.0: `{"version": "1.0", "createSurface": {surfaceId, catalogId, components?, dataModel?}}`,
  then `updateComponents` and data updates. Dynamic values are `{"@path": "/x"}` and
  `{"@call": "fn", "args": {…}}`; events are `{"event": {name, userMessage?, context?}}` or
  `{"functionCall": {"@call", "args"}}`. `catalog.json` declares `"protocolVersion": "1.0"`.

### Catalog-level instructions

`catalog.json` carries `title` ("A2UI Playground catalog"), `description` and `instructions`: a "## Design rules"
list of 11 rules from `src/a2ui/catalog/instructions.ts` (`DESIGN_RULES`). Examples: lead with a Heading, then the
component built for the job; KPIs go in a Grid of Stat; 8 to 18 components; percent values are 0–100 with format
"percent"; at most 8 map markers. The model-facing `inference-catalog.json` has the same instructions. It also cuts
the standard components' styling props (`STYLE_PROPS` in `prompt-trim.ts`), cuts their descriptions to the first
sentence, and adds the macros. The package exposes both documents, so a Dart agent can prompt with the right one.

### Functions (16)

| Function | Meaning (CopilotKit) | Flutter |
|---|---|---|
| `required`, `regex`, `length`, `numeric`, `email` | validators returning `{valid, message, code}`. `regex` is unanchored with the `u` flag; `required` fails on null, "" and [] (false and 0 pass) | **ours** (ported in 1b); parity tests from `packages/core/src/generative-ui/__tests__/functions.test.ts` |
| `formatString` | `${/abs}`, `${rel}`, `${'lit'}`, `${fn(name: expr)}`, `${@index}`; `\${` is literal; no arithmetic | `a2ui_core`'s expression parser, values written as `String()` writes them (a list is `a,b`), calls only to the catalog's functions |
| `formatNumber`, `formatCurrency` | `Intl.NumberFormat(user locale)`; `decimals` sets min and max; `grouping:false` | **ours** (review fix B4/S10): CopilotKit's bodies on `package:intl`; the currency's own digits; CLDR English symbols |
| `formatDate` | TR35 subset: yy/yyyy, M–MMMM, d/dd, E–EEEE, H/HH, h/hh, m, s, a, quoted literals; local time; "YYYY-MM-DD" is local midnight | **ours** (review fix B4): `formatDatePattern` and `dateOf` ported |
| `pluralize` | `zero` only for exactly 0, else `Intl.PluralRules` | **ours** (review fix S10) |
| `openUrl` | http(s) only, user gesture only, new tab | `a2ui_core` hook → `url_launcher` |
| `and`, `or`, `not` | truthiness of ValidationResult `.valid`, else `Boolean(x)` | **ours** (review fix B3) |
| `calc` | an expression over named args: `?:`, `\|\|`, `&&`, `== !=`, `< <= > >=`, `+ -` (string concat), `* / %`, unary `- !`, `^` (right-assoc, binds tighter than unary minus); `pi`, `e`; `min max round floor ceil abs pow sqrt exp ln log10` | **ours**: a `FunctionImplementation` with a small Pratt parser; port the vectors in `core/…/__tests__/calc.test.ts` |
| `series` | `count` (0–1000) copies of `item`, with `${expr}` evaluated per index (`variable` "i", `start` 1); for chart data | **ours**; same test source |

---

## 2. Components

### Conventions that apply to every component

- **Every prop accepts a literal or a dynamic value** (`{"@path"}` or `{"@call"}`), resolved by the engine before
  the renderer sees it. The few that take only literals are marked "literal only" in Appendix A.
- **Child references.** `ChildList` (an id array, or a template `{componentId, path}` repeated per item of a data
  array) and `ComponentId` (one id). They may sit inside arrays of objects: `Tabs.tabs[].child`,
  `Accordion.items[].child`, Table cells `{componentId}` resolved from `cellComponents`. `a2ui_core`'s
  `ComponentRefMap` finds top-level refs and refs one array deep, which covers every case here. Phase 1 adds a test
  that it finds all of them.
- **Events** are `Action` props (`onClick`, `onSubmit`, `onVisible`, `onAction`, `onFollowUp`, …). The renderer calls
  them with the arguments given in Appendix A (`{}` for almost all; `List.action` passes `{index, label, value}`,
  `EntityCard` passes `{label}`, `FollowUp` passes `{message}`). The model's binding adds the event name and context.
  Only 3 playground components fire events: Callout, EmptyState and EventCard, and only when `onAction` is bound.
- **Write-back** (`writable`, not in the exported JSON; taken from the Zod declarations): `value` on 9 standard
  inputs and 5 playground inputs, `selectedIndex` (Tabs), `activeIndex` (Carousel), `open` (Popover, Modal) and
  `selected` (Map). A write to a `{"@path"}` binding updates the data model, and that path becomes user-owned (agent
  writes at or below it are then ignored). A write to a literal is kept locally until the node remounts.
  `a2ui_flutter` exposes this as `props.writable(key)`.
- **Units.** A number means **n × 4px** for every layout length: gap, rowGap, columnGap, padding, width, height,
  min/max sizes, Grid `minChildWidth`, Divider `spacing`, Spacer `minSize`, Badge `maxWidth`/`padding`, Text and
  Title `width`, Image sizes, Video `width`/`maxWidth`, Modal `maxWidth`, PopoverContent `width`, EntityCard
  `width`, ImageGrid `gap`, TableCell and column width/padding, and List `gap`. A number is **px** for `radius`,
  Text `fontSize`, Svg and HtmlView sizes, Chart `height`/`barRadius`/`yAxis.width`, Map `height`, PulseIndicator,
  Favicon and Icon `size`, and List `maxMarkerSize`/`markerSize`. A string is raw CSS (`"12px"`, `"1rem"`, `"50%"`).
  There are no named spacing sizes; xs/sm/md/lg exist only for radius, text, icon, input and badge sizes. The
  playground's own 52 take no spacing props: their spacing is fixed in their renderers.
- **Validation.** `a2ui_core` validates each component update against the catalog, as CopilotKit has done since
  1.85 (`@a2ui/web_core` 0.15). A component that arrives before its required props fails validation until a valid
  update arrives; the playground's agent sends `Blueprint` stand-ins meanwhile (Appendix A, end).

### All 121 components

Columns: child-reference props, `Action` props, the prop written back, whether it takes `checks`, size (S, M or L
for the Flutter port), phase, and packages beyond the Flutter SDK and the package's own foundation. Each name links to
its block in Appendix A: every prop (type, required, default, enum, notes), what the React renderer does, and the
Flutter approach.

| # | Component | Source | Group | Child props | Events | Writes | Checks | Size | Phase | Packages |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | [Box](#box) | standard | Layout | `children` | `onVisible` |  |  | M | 1 |  |
| 2 | [Column](#column) | standard | Layout | `children` | `onVisible` |  |  | S | 1 |  |
| 3 | [Row](#row) | standard | Layout | `children` | `onVisible` |  |  | M | 1 |  |
| 4 | [Grid](#grid) | standard | Layout | `children` | `onVisible` |  |  | M | 1 |  |
| 5 | [GridItem](#griditem) | standard | Layout | `children` | `onVisible` |  |  | S | 1 |  |
| 6 | [Card](#card) | standard | Layout | `children`, `child` | `onVisible` |  |  | M | 1 |  |
| 7 | [Flow](#flow) | standard | Layout | `children` | `onVisible` |  |  | M | 6 |  |
| 8 | [FlowItem](#flowitem) | standard | Layout | `children` | `onVisible` |  |  | S | 6 |  |
| 9 | [Carousel](#carousel) | standard | Layout | `children` | `onVisible` | `activeIndex` |  | M | 4 |  |
| 10 | [CarouselItem](#carouselitem) | standard | Layout | `children` | `onVisible` |  |  | S | 4 |  |
| 11 | [CarouselMediaItem](#carouselmediaitem) | standard | Layout | `children` | `onClick`, `onVisible` |  |  | M | 4 |  |
| 12 | [Spacer](#spacer) | standard | Layout |  |  |  |  | S | 1 |  |
| 13 | [Divider](#divider) | standard | Layout |  |  |  |  | S | 1 |  |
| 14 | [Tabs](#tabs) | standard | Layout | `tabs[].child` |  | `selectedIndex` |  | M | 4 |  |
| 15 | [Title](#title) | standard | Text |  |  |  |  | S | 1 |  |
| 16 | [Text](#text) | standard | Text | `children` |  |  |  | M | 1 |  |
| 17 | [Caption](#caption) | standard | Text |  |  |  |  | S | 1 |  |
| 18 | [Label](#label) | standard | Text |  |  |  |  | S | 1 |  |
| 19 | [Bold](#bold) | standard | Text |  |  |  |  | S | 6 |  |
| 20 | [Italic](#italic) | standard | Text |  |  |  |  | S | 6 |  |
| 21 | [Underline](#underline) | standard | Text |  |  |  |  | S | 6 |  |
| 22 | [Strikethrough](#strikethrough) | standard | Text |  |  |  |  | S | 6 |  |
| 23 | [Badge](#badge) | standard | Text |  |  |  |  | S | 1 |  |
| 24 | [Blockquote](#blockquote) | standard | Text |  |  |  |  | S | 6 |  |
| 25 | [Code](#code) | standard | Text |  |  |  |  | S | 6 |  |
| 26 | [Markdown](#markdown) | standard | Text |  |  |  |  | L | 1 | flutter_markdown_plus, markdown, flutter_math_fork, url_launcher |
| 27 | [Math](#math) | standard | Text |  |  |  |  | M | 6 | flutter_math_fork |
| 28 | [ShimmerText](#shimmertext) | standard | Text |  |  |  |  | S | 6 |  |
| 29 | [Link](#link) | standard | Text |  |  |  |  | S | 1 | url_launcher |
| 30 | [Tooltip](#tooltip) | standard | Text | `trigger`, `content` |  |  |  | M | 4 |  |
| 31 | [Button](#button) | standard | Inputs | `child`, `children` | `onClick` |  | yes | M | 1 | url_launcher |
| 32 | [Pressable](#pressable) | standard | Inputs | `children` | `onClick`, `onVisible` |  |  | M | 4 | url_launcher |
| 33 | [Form](#form) | standard | Inputs | `children` | `onSubmit` |  |  | M | 1 |  |
| 34 | [TextField](#textfield) | standard | Inputs |  |  | `value` | yes | M | 1 |  |
| 35 | [TextArea](#textarea) | standard | Inputs |  |  | `value` | yes | M | 4 |  |
| 36 | [Select](#select) | standard | Inputs |  |  | `value` | yes | M | 1 |  |
| 37 | [CheckBox](#checkbox) | standard | Inputs |  |  | `value` | yes | S | 1 |  |
| 38 | [Radio](#radio) | standard | Inputs |  |  |  |  | S | 4 |  |
| 39 | [RadioGroup](#radiogroup) | standard | Inputs |  |  | `value` | yes | M | 1 |  |
| 40 | [Slider](#slider) | standard | Inputs |  |  | `value` | yes | M | 4 |  |
| 41 | [SegmentedControl](#segmentedcontrol) | standard | Inputs |  |  | `value` | yes | M | 4 |  |
| 42 | [ChoicePicker](#choicepicker) | standard | Inputs |  |  | `value` | yes | M | 4 |  |
| 43 | [DateTimeInput](#datetimeinput) | standard | Inputs |  |  | `value` | yes | L | 4 | intl |
| 44 | [PulseIndicator](#pulseindicator) | standard | Feedback |  |  |  |  | S | 6 |  |
| 45 | [FlashcardFlip](#flashcardflip) | standard | Feedback |  |  |  |  | S | 6 |  |
| 46 | [Popover](#popover) | standard | Feedback | `children` |  | `open` |  | M | 4 |  |
| 47 | [PopoverTrigger](#popovertrigger) | standard | Feedback | `children` |  |  |  | S | 4 |  |
| 48 | [PopoverContent](#popovercontent) | standard | Feedback | `children` |  |  |  | M | 4 |  |
| 49 | [Modal](#modal) | standard | Feedback | `trigger`, `content` |  | `open` |  | L | 4 |  |
| 50 | [Table](#table) | standard | Data | `children`, `cellComponents` |  |  |  | L | 6 |  |
| 51 | [TableSection](#tablesection) | standard | Data | `children` |  |  |  | S | 6 |  |
| 52 | [TableRow](#tablerow) | standard | Data | `children` |  |  |  | S | 6 |  |
| 53 | [TableCell](#tablecell) | standard | Data | `children` |  |  |  | S | 6 |  |
| 54 | [List](#list) | standard | Data | `children` | `action` |  |  | M | 1 |  |
| 55 | [ListItem](#listitem) | standard | Data | `children` | `action` |  |  | M | 1 |  |
| 56 | [Chart](#chart) | standard | Data |  |  |  |  | L | 2 | fl_chart, intl |
| 57 | [Map](#map) | standard | Data |  |  | `selected` |  | L | 3 | flutter_map, latlong2 |
| 58 | [Image](#image) | standard | Media |  | `onOverlayClick` |  |  | M | 1 | url_launcher |
| 59 | [Icon](#icon) | standard | Media |  |  |  |  | M | 1 | path_parsing |
| 60 | [Favicon](#favicon) | standard | Media |  |  |  |  | S | 3 |  |
| 61 | [Svg](#svg) | standard | Media |  |  |  |  | M | 3 |  |
| 62 | [Video](#video) | standard | Media |  |  |  |  | L | 3 | video_player, url_launcher, web (web only) |
| 63 | [AudioPlayer](#audioplayer) | standard | Media |  |  |  |  | M | 3 | video_player |
| 64 | [HtmlView](#htmlview) | standard | Media |  |  |  |  | L | 3 | flutter_widget_from_html_core, flutter_svg, web (web only) |
| 65 | [LinkCard](#linkcard) | standard | Composites |  | `onClick` |  |  | S | 5 | url_launcher |
| 66 | [Citation](#citation) | standard | Composites |  |  |  |  | M | 4 | url_launcher |
| 67 | [FollowUp](#followup) | standard | Composites |  | `onFollowUp` |  |  | S | 4 |  |
| 68 | [EntityCard](#entitycard) | standard | Composites |  | `onAction`, `onClick` |  |  | M | 5 | url_launcher |
| 69 | [ImageGrid](#imagegrid) | standard | Composites |  |  |  |  | M | 3 | url_launcher |
| 70 | [Section](#section) | playground | Layout | `children` |  |  |  | S | 1 |  |
| 71 | [Accordion](#accordion) | playground | Layout | `items[].child` |  |  |  | S | 4 |  |
| 72 | [Heading](#heading) | playground | Content |  |  |  |  | M | 1 |  |
| 73 | [CodeBlock](#codeblock) | playground | Content |  |  |  |  | M | 6 |  |
| 74 | [Quote](#quote) | playground | Content |  |  |  |  | S | 6 | Lucide (`lucideImport`, playground) |
| 75 | [ImageGallery](#imagegallery) | playground | Content |  |  |  |  | S | 3 |  |
| 76 | [VideoEmbed](#videoembed) | playground | Content |  |  |  |  | M | 3 | url_launcher, web (web only) |
| 77 | [Kbd](#kbd) | playground | Content |  |  |  |  | S | 6 |  |
| 78 | [Stat](#stat) | playground | Data display |  |  |  |  | M | 1 | Lucide (`lucideImport`, playground) |
| 79 | [StatGroup](#statgroup) | playground | Data display |  |  |  |  | M | 1 |  |
| 80 | [Avatar](#avatar) | playground | Data display |  |  |  |  | S | 5 |  |
| 81 | [AvatarGroup](#avatargroup) | playground | Data display |  |  |  |  | S | 5 |  |
| 82 | [DataTable](#datatable) | playground | Data display |  |  |  |  | L | 5 | intl |
| 83 | [KeyValueList](#keyvaluelist) | playground | Data display |  |  |  |  | M | 1 |  |
| 84 | [Timeline](#timeline) | playground | Data display |  |  |  |  | S | 5 | Lucide (`lucideImport`, playground) |
| 85 | [Progress](#progress) | playground | Data display |  |  |  |  | S | 5 |  |
| 86 | [RadialProgress](#radialprogress) | playground | Data display |  |  |  |  | S | 5 |  |
| 87 | [Rating](#rating) | playground | Data display |  |  |  |  | S | 5 | Lucide (`lucideImport`, playground) |
| 88 | [TagList](#taglist) | playground | Data display |  |  |  |  | S | 5 |  |
| 89 | [Agenda](#agenda) | playground | Data display |  |  |  |  | M | 5 | intl, Lucide (`lucideImport`, playground) |
| 90 | [ComparisonTable](#comparisontable) | playground | Data display |  |  |  |  | M | 5 | Lucide (`lucideImport`, playground) |
| 91 | [LineChart](#linechart) | playground | Charts |  |  |  |  | L | 2 | fl_chart, intl |
| 92 | [AreaChart](#areachart) | playground | Charts |  |  |  |  | L | 2 | fl_chart, intl |
| 93 | [BarChart](#barchart) | playground | Charts |  |  |  |  | L | 2 | fl_chart, intl |
| 94 | [PieChart](#piechart) | playground | Charts |  |  |  |  | M | 2 | fl_chart, intl |
| 95 | [ScatterChart](#scatterchart) | playground | Charts |  |  |  |  | M | 2 | fl_chart, intl |
| 96 | [Heatmap](#heatmap) | playground | Charts |  |  |  |  | M | 2 | intl |
| 97 | [Sparkline](#sparkline) | playground | Charts |  |  |  |  | M | 2 |  |
| 98 | [RadarChart](#radarchart) | playground | Charts |  |  |  |  | M | 2 | fl_chart |
| 99 | [CandlestickChart](#candlestickchart) | playground | Charts |  |  |  |  | M | 2 | fl_chart, intl |
| 100 | [Treemap](#treemap) | playground | Charts |  |  |  |  | L | 2 | intl |
| 101 | [SankeyChart](#sankeychart) | playground | Charts |  |  |  |  | L | 2 | intl |
| 102 | [Gauge](#gauge) | playground | Charts |  |  |  |  | S | 2 | intl |
| 103 | [MapView](#mapview) | playground | Maps |  |  |  |  | L | 3 | flutter_map, latlong2 |
| 104 | [RouteMap](#routemap) | playground | Maps |  |  |  |  | L | 3 | flutter_map, latlong2 |
| 105 | [LocationCard](#locationcard) | playground | Maps |  |  |  |  | M | 3 | flutter_map, latlong2, url_launcher |
| 106 | [PlaceList](#placelist) | playground | Maps |  |  |  |  | L | 3 | flutter_map, latlong2 |
| 107 | [Combobox](#combobox) | playground | Inputs |  |  | `value` |  | M | 4 |  |
| 108 | [Switch](#switch) | playground | Inputs |  |  | `value` |  | S | 4 |  |
| 109 | [DatePicker](#datepicker) | playground | Inputs |  |  | `value` |  | M | 4 | intl |
| 110 | [ButtonGroup](#buttongroup) | playground | Inputs |  |  | `value` |  | S | 4 |  |
| 111 | [ChipSelect](#chipselect) | playground | Inputs |  |  | `value` |  | S | 4 |  |
| 112 | [Alert](#alert) | playground | Feedback |  |  |  |  | S | 1 | Lucide (`lucideImport`, playground) |
| 113 | [Callout](#callout) | playground | Feedback |  | `onAction` |  |  | S | 1 | Lucide (`lucideImport`, playground) |
| 114 | [Skeleton](#skeleton) | playground | Feedback |  |  |  |  | S | 6 |  |
| 115 | [EmptyState](#emptystate) | playground | Feedback |  | `onAction` |  |  | S | 6 | Lucide (`lucideImport`, playground) |
| 116 | [WeatherCard](#weathercard) | playground | Domain |  |  |  |  | M | 5 | Lucide (`lucideImport`, playground) |
| 117 | [ProfileCard](#profilecard) | playground | Domain |  |  |  |  | M | 5 | url_launcher, Lucide (`lucideImport`, playground) |
| 118 | [ReceiptCard](#receiptcard) | playground | Domain |  |  |  |  | S | 5 | intl, Lucide (`lucideImport`, playground) |
| 119 | [EventCard](#eventcard) | playground | Domain |  | `onAction` |  |  | M | 5 | intl, Lucide (`lucideImport`, playground) |
| 120 | [StockTicker](#stockticker) | playground | Domain |  |  |  |  | M | 5 | intl |
| 121 | [RecipeCard](#recipecard) | playground | Domain |  |  |  |  | M | 5 | Lucide (`lucideImport`, playground) |

### Shared prop groups

Appendix A lists these once here and names them in each component's block.

#### Layout props (30, identical on 13 containers)

Used by Box, Column, Row, Grid, GridItem, Card, Flow, FlowItem, Carousel, CarouselItem, CarouselMediaItem, Pressable, Form. FlowItem and CarouselMediaItem lack `aspectRatio`; Form lacks `onVisible`.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `onVisible` | Action |  | Sent once, the first time the container scrolls into view. Use it to load more content lazily. |
| `align` | enum(start \| center \| end \| baseline \| stretch) |  |  |
| `justify` | enum(start \| center \| end \| spaceBetween \| spaceAround \| spaceEvenly \| stretch) |  |  |
| `wrap` | enum(nowrap \| wrap \| wrap-reverse) |  |  |
| `gap` | number or string |  | 4px steps when a number |
| `rowGap` | number or string |  |  |
| `columnGap` | number or string |  |  |
| `padding` | number or string |  | 4px steps when a number |
| `background` | string |  | Leave it unset. A surface token such as surface, surface-secondary, info, success, warning, danger, discovery, or one with -solid, or a CSS color. Only one summary panel in a Card uses "surface-secondary" |
| `border` | boolean |  |  |
| `borderColor` | enum(default \| subtle \| strong \| info \| warning \| caution \| success \| danger \| discovery) |  |  |
| `radius` | enum(2xs \| xs \| sm \| md \| lg \| xl \| 2xl \| 3xl \| 4xl \| full) or number or string or {topLeft?: string, topRight?: string, bottomLeft?: string, bottomRight?: string} |  |  |
| `width` | number or string |  |  |
| `height` | number or string |  |  |
| `minWidth` | number or string |  |  |
| `maxWidth` | number or string |  |  |
| `minHeight` | number or string |  |  |
| `maxHeight` | number or string |  |  |
| `flex` | number |  |  |
| `weight` | number |  | flex-grow in a Row or Column |
| `aspectRatio` | string |  |  |
| `scrollable` | boolean |  |  |
| `clip` | boolean |  |  |
| `shadow` | boolean |  |  |
| `inline` | boolean |  |  |
| `role` | string |  | ARIA role |
| `flush` | boolean |  | No padding |
| `minSize` | number or string |  | Minimum width and height |
| `maxSize` | number or string |  | Maximum width and height |
| `disableAutoSpacing` | boolean |  | No default gap between children |

#### Typography props (8, identical on Text, Title and ShimmerText)

| Prop | Type | Default | Notes |
|---|---|---|---|
| `color` | string |  | One of default\|prose\|primary\|emphasis\|secondary\|tertiary\|success\|info\|warning\|caution\|danger\|discovery or a CSS color |
| `fontWeight` | enum(normal \| medium \| semibold \| bold) |  |  |
| `textAlign` | enum(start \| center \| end) |  |  |
| `italic` | boolean |  |  |
| `truncate` | boolean |  |  |
| `maxLines` | number |  |  |
| `tabularNums` | boolean |  |  |
| `width` | number or string |  |  |

#### `checks` (on Button, TextField, TextArea, Select, CheckBox, RadioGroup, Slider, SegmentedControl, ChoicePicker, DateTimeInput)

Type: ({condition?: boolean or {valid, message, code, severity}, message?: string})[]. The condition is a boolean binding or a validator call (`required`, `regex`, `length`, `numeric`, `email`, combined with `and`/`or`/`not`). The control shows the first failed **error** check (else the first warning/info) after the field was blurred once or holds a value; a Button is disabled while an error check fails and shows it as its tooltip.

### Packages

The recommended dependency set, chosen for maintenance and licence. Figures are from the pub.dev API on 2026-11-18.

| Package | Version (published) | Publisher | Licence | For | Notes |
|---|---|---|---|---|---|
| `a2ui_flutter` | 0.4.0 (2026-11-17) | labs.flutter.dev | Apache-2.0 / MIT | the renderer | 0.x: pin `^0.4.0` and track releases |
| `a2ui_core` | 0.8.0 (2026-11-17) | labs.flutter.dev | Apache-2.0 | catalog model, validation, basic functions | `Catalog.fromJson` reads the exported document |
| `json_schema_builder` | 0.1.7 (2026-09-01) | labs.flutter.dev | BSD-3 | `Schema` for `ComponentImplementation` | already used by the lab |
| `fl_chart` | 1.3.1 (2026-11-09) | flchart.dev | MIT | Chart, Line/Area/Bar/Pie/Scatter/Radar/Candlestick | 7.2k likes, 2.3M downloads a month. **Not used** since phase 2a: it cannot draw the playground's curves, bands, stacks and arcs (port note 2a-1) |
| `flutter_map` | 8.3.2 (2026-08-27) | fleaflet.dev | BSD-3 | the 5 map components | all 6 platforms, no WebGL, no platform view, golden-testable |
| `latlong2` | 0.10.1 (2026-04-27) | femtopedia.de | Apache-2.0 | coordinates for flutter_map | |
| `flutter_markdown_plus` | 1.0.12 (2026-07-10) | foresightmobile.com | BSD-3 | Markdown | the maintained successor of the discontinued `flutter_markdown` |
| `markdown` | 7.3.1 (2026-03-18) | tools.dart.dev | BSD-3 | GFM parsing, custom math syntax | |
| `flutter_math_fork` | 0.7.4 (2025-05-21) | simpleclub.com | Apache-2.0 | Math, Markdown math | the only maintained KaTeX-class renderer; watch it |
| ~~`flutter_lucide`~~ (dropped 2026-11-21, RULEBOOK §1: lucide-react's own icon nodes) | 1.72.0 (2026-11-12) | voltvave.com | MIT | Lucide icons (Icon and fixed glyphs) | 160/160 points, tracks Lucide releases; no name lookup, so we generate one |
| `url_launcher` | 6.3.3 (2026-10-02) | flutter.dev | BSD-3 | href, openUrl, mailto, tel | Flutter Favorite |
| `video_player` | 2.14.1 (2026-10-02) | flutter.dev | BSD-3 | Video files, AudioPlayer | already a dependency of `a2ui_flutter` |
| `flutter_widget_from_html_core` | 0.17.4 (2026-09-08) | daohoangson.com | MIT | HtmlView on Android, iOS and desktop | static HTML, no JS, which matches `sandbox=""` |
| `flutter_svg` | 2.4.0 (2026-11-13) | flutter.dev | MIT | inline `<svg>` inside HtmlView | not needed for the Svg component (primitives are painted) |
| `intl` | 0.20.3 (2026-06-25) | dart.dev | BSD-3 | number, currency, compact and date formats | |
| `web` | 1.1.2 (2026-10-23) | dart.dev | BSD-3 | web-only iframes (HtmlView, video embeds) | behind conditional imports |
| dev: `very_good_analysis` | 11.0.0 (2026-09-03) | verygood.ventures | MIT | lints | section 8 |
| dev: `alchemist` | 0.15.0 (2026-11-17) | betterment.dev | MIT | golden tests | `golden_toolkit` is discontinued |

Rejected: `syncfusion_flutter_charts` (commercial licence); `graphic` (MIT but no verified publisher, last release
2026-02); `flutter_markdown` (discontinued); `flutter_html` (90/160 points); `maplibre_gl` 0.28.0 (BSD-3, exact
vector styles, but Android, iOS and web only, platform views, no golden tests; it stays an option behind the map
delegate); `vector_map_tiles` (last release 2024-08, no web); `lucide_icons` (2023, 45 points); `flutter_highlight`,
`highlight` (2021) and `re_highlight` (2024-02, 0.0.x) for code highlighting. Instead we port sugar-high, the
playground's own small tokenizer (MIT; see CodeBlock), and expose a hook for apps that want real grammars.

---

## 3. Design systems and theming

### Two token layers

1. **Standard tokens `--a2ui-*`** (`shared/standard/tokens.ts`, `theme.ts`). The 69 standard components read only
   these. A `GenerativeUITheme` sets them: values at the top level apply in both modes, values under `dark` replace
   them in dark mode, and `mapStyle` is an extra key. Variable names must match `^--a2ui-[a-z0-9-]+$`.
2. **Playground tokens `--a2-*` and `--ts-chart-*`** (`src/app/globals.css`, `renderers/renderers.css`), in oklch.
   The 52 playground components read these through Tailwind classes, with many fixed pixel sizes (11–26px text,
   14px card radius).

The playground also re-themes layer 1 with `playgroundTheme` (`src/a2ui/catalog/catalog.ts`): a violet accent
`oklch(0.52 0.2 292)` (dark `oklch(0.72 0.17 292)`), zinc-tinted surfaces and borders, chart colours 1–6 and
`--a2ui-radius-lg: 14px`. So the standard components on a2ui.open.bot do not look like CopilotKit's library defaults
(black accent, `#7fb0f2…` charts).

### Spacing, sizes and radii

- **Spacing:** `spacing(n) = calc(var(--spacing, 0.25rem) * n)`, so a number is n × 4px at a 16px root, and a
  string passes through as CSS. Default gaps: Box, Column and the other containers get 16px at the top level and
  directly inside a Card, and 8px deeper inside a Card (`CardDistanceContext`). Row is always 8px unless set, Grid 16,
  Card 16 (12 when nested), Form 16. `disableAutoSpacing` makes it 0. min-width defaults to 0 and max-width to 100%.
- **Radius** (`--a2ui-radius-*`, px): 2xs 2, xs 4, sm 6, md 8, lg 12 (14 in the playground theme), xl 16, 2xl 20,
  3xl 24, 4xl 32, full 9999. A number is px; a string is CSS; per-corner objects are allowed. Card defaults to xl.
  The playground's own cards use `--a2-radius` 14px.
- **Controls:** height sm 28, md 32, lg 36, xl 40px; font .8125/.875/.875/1em; horizontal padding 10/12/12/18px;
  icon 14/16/18/18px; pill by default (8px with `pill:false`); border `--a2ui-color-border-control`.
- **Shadows:** xs `0 1px 2px rgba(0,0,0,.12)`, sm `0 1px 3px rgba(0,0,0,.12)`, soft `0 1px 3px rgba(0,0,0,.06)`, md
  `0 4px 12px rgba(0,0,0,.08)`. Dark mode raises the alpha (.5/.5/.3/.4).

### Typography

- The surface inherits the host's font family, size, line height and colour; there is no explicit body size, so it
  is the browser's 16px. Text sizes are **em of that base**: 3xs .625/1.2, 2xs .6875/1.273, xs .75/1.333,
  sm .875/1.429, md 1/1.625, lg 1.125/1.556 (size/line-height). Weights normal 400, medium 500, semibold 600,
  bold 700.
- Title: React renders sm as h4 and md/lg as h3 (1.25em/600), and xl to 5xl as h2 (1.5em/600). `TITLE_SCALE`
  (sm .875 … 5xl 3em) exists in tokens.ts but React does not use it; the port matches React.
- Caption: sm .75em, md .8125em, lg .875em (default lg), secondary colour.
- Inline markdown in Text, Caption and Blockquote supports `**b**`, `~~s~~`, `++u++`, `` `code` ``, `*i*`, `_i_`
  (not inside a word) and `[label](url)`. Marks do not nest; an unmatched marker stays literal; unsafe URLs keep only
  the label.
- Font family: standard `-apple-system, ui-sans-serif, system-ui, "Segoe UI", Helvetica, …`; the playground uses
  Geist and Geist Mono. Numbers use tabular figures throughout the playground components.

### Colour tokens (standard layer, CopilotKit defaults)

| Token | Light | Dark |
|---|---|---|
| text default / prose / primary | #0d0d0d | #ececec |
| text secondary · tertiary | #5d5d5d · #8e8e8e | #b4b4b4 · #8e8e8e |
| text success · info · warning (= caution) · danger · discovery | #00805d · #0068bc · #946200 · #c1322c · #7040c1 | #4fd1a5 · #6cb6ff · #e3b341 · #ff7b72 · #bc9cff |
| surface · secondary · tertiary · elevated · inverted · soft | #fff · #f7f7f8 · #ececec · #fff · #0d0d0d · #fcfcfc | #1f1f1f · #2a2a2a · #3a3a3a · #262626 · #f2f2f2 · #232323 |
| tints info / warning / success / danger / discovery | the text colour's RGB at .08 alpha | lighter RGB at .14 |
| `<tone>-solid` | the text colour | #3b8eea · #c99a2e · #2fae86 · #e5534b · #9a6ff0 |
| border default · subtle · strong · control | rgba(0,0,0,.1) · rgba(0,0,0,.05) · #cdcdcd · rgba(0,0,0,.15) | rgba(255,255,255,.12) · .06 · #4a4a4a · .2 |
| accent · on-accent · focus | #0d0d0d · #fff · #0285ff | #f2f2f2 · #0d0d0d · #3b9bff |
| panel (inner panel in a Card) | rgb(252,252,252) | #262626 |
| chart-1 … chart-6 | #7fb0f2 #2f6fd1 #b7cff7 #8bb5a8 #d9b36b #c08bb0 | (none) |
| others | backdrop rgba(0,0,0,.8), overlay rgba(0,0,0,.65), rating #f5a524, highlight green #d3f5e4 / orange #ffe7c7 / pink #fde0ef | highlights #1d4a37 / #4d3418 / #4d2338 |

Colour props (`color`, `background`, `borderColor`) take one of these names or any CSS colour. Inside a Card, a
neutral background becomes the panel colour and a tint drops to 6% alpha.

### Playground tokens and tones

- Surfaces: `--a2-surface` `oklch(1 0 0)` (dark `oklch(0.172 0.005 285)`), `--a2-surface-2` `oklch(0.97 0.003 285)`
  (dark `oklch(0.205 0.006 285)`); lines `--a2-line` ink 9% (dark white 7.5%), `--a2-line-strong` ink 15% (dark
  white 12%), where ink is `oklch(0.21 0.012 285)`; foreground `oklch(0.2 0.008 285)`, muted `oklch(0.47 0.014 285)`.
- `.a2-card`: surface (with a faint sheen in dark), 1px line border, radius 14, shadow `0 1px 2px` ink 6% +
  `0 1px 3px` ink 4%. `.a2-well`: ink 3% fill, line border, radius 10. `.a2-label`: 12.5px, 500, muted.
- **Tones** (`tone` = default, positive, negative, warning, info, accent): accent `oklch(0.52 0.2 292)`, positive
  `oklch(0.52 0.13 160)`, negative `oklch(0.56 0.2 22)`, warning `oklch(0.53 0.14 62)`, info
  `oklch(0.52 0.13 235)` (dark: 0.72/0.78/0.7/0.83/0.76 lightness). Each has text, soft (13% mix, 24% border; accent
  14%/26%), outline (45% border), solid (white text; warning black/80), dot and bar variants. "default" is neutral.
  Progress, RadialProgress and Agenda default to accent; Stat and TagList default to neutral.
- `toneFromText` (DataTable badge cells) matches substrings in order: positive (paid, active, done, complete,
  success, healthy, online, approved, shipped, live, won, pass), negative (fail, overdue, error, declined, cancel,
  churn, lost, blocked, down, critical), warning (pending, trial, review, waiting, draft, at risk, due, paused,
  late), accent (enterprise, pro, scale, premium), info (new, info, beta, starter). Port it as is, including the
  quirk that "approved" also hits "pro".
- Charts: `--ts-chart-1..6` = `oklch(0.55 0.2 292)`, `(0.58 0.13 230)`, `(0.6 0.14 162)`, `(0.7 0.15 72)`,
  `(0.6 0.2 18)`, `(0.6 0.03 285)` (dark 0.72/0.76/0.79/0.83/0.71/0.7). Chart ink, grid, tooltip, heat and code
  colours are in `renderers.css` and `globals.css` (lines 326–336 for code in dark).
- Not on this scale: Alert (Tailwind sky, emerald, amber, rose), the maps (violet and emerald pins and routes) and
  ReceiptCard's status colours.
- Motion: paint-in and skeleton reveal 400ms, chart SVG wipe-in 700ms, KPI glyph pop-in, Heading word stream, and
  shimmer pulses at 1000ms. Everything stops under `prefers-reduced-motion`.

### Design systems in the playground

The "+" menu offers CopilotKit (default), shadcn/ui, Material (Material 3 Expressive) and Bring your own (`?ds=`).
Each one (`src/design-systems/`) does three things:

1. It sets its own `--a2ui-*` values (`themes.ts`).
2. It re-skins `--a2-*` and `.a2-card` under `[data-ds]` (`design-systems.css`).
3. It swaps a few leaves through `useOverride`: the standard Badge, Button and Divider, and the playground's Stat,
   StatGroup, KeyValueList, Heading, Alert, Callout and Progress.

The A2UI never changes, which is the point of a catalog: a contract, not a look.

### The Flutter theme API

- **`A2uiCatalogTheme`**, a `ThemeExtension`, holds both layers as typed fields:
  - standard colours, radii, shadows, control metrics, the spacing step (4.0) and the em base font size (16.0);
  - the font family, the chart palette and the map tile settings;
  - the playground tokens: surfaces, lines, the five tones, `--ts-chart-*`, chart ink, heat and tooltip colours, and
    the code palette.

  It implements `copyWith` and `lerp`, so theme animations work.
- **Presets:**
  - `A2uiCatalogTheme.playground(brightness)` is the default. It matches a2ui.open.bot: `playgroundTheme` plus
    `globals.css`.
  - `A2uiCatalogTheme.standard(brightness)` gives CopilotKit's library defaults.
  - `A2uiCatalogTheme.fromColorScheme(scheme)` maps a Material `ColorScheme` onto the tokens, like the Material design
    system.

  Brightness follows `Theme.of(context)` unless the app passes a theme.
- **Overrides:** `a2uiCatalog(overrides: {name: builder})` swaps any component, as `useOverride` does. With these and
  the theme, an app can build its own "design system" without forking.
- **Colour and length parsing** in the foundation:
  - a token resolver (name → colour, with the in-Card panel rule);
  - a CSS colour parser: hex 3/4/6/8, `rgb[a]()`, `hsl[a]()`, `oklch()` and the 148 named colours;
  - oklch → sRGB with gamut clipping, and `colorMix` in oklch (Heatmap, avatar hues);
  - a CSS length parser: number = steps, `px`, `rem` (× 16), `em` (× the current font size), and `%` where Flutter can
    honour it. Anything else is ignored, never thrown.
- **Text scale:** em sizes multiply the base font size, and `MediaQuery.textScaler` applies on top. Layouts must hold
  at 2.0.

---

## 4. Macros

`FlightCard`, `ProductCard` and `WeatherReport` (`src/a2ui/macros/macros.ts`) are high-level components that only the
model sees. The schemas are in `inference-catalog.json`. The **server** expands each one before anything reaches the
client, following the A2UI Python SDK's `MacroExpander`:

- expansion is recursive, at most 16 levels;
- the root keeps the macro's id, and every other node becomes `${id}__${type}_${n}`;
- dynamic values pass through, so a macro works inside a template.

| Macro | Props | Expands to | Data |
|---|---|---|---|
| FlightCard | airline, flightNumber?, from, to, fromCity?, toCity?, depart, arrive, duration?, stops?, price?, cabin?, date?, badge?, actionLabel?; event `onAction` | Card, Row, Column, Title, Text, Caption, Icon, Badge, Button, Divider | none |
| ProductCard | name, price, compareAt?, image?, rating?, reviews?, badge?, specs?[], actionLabel?; event `onAction` | Card, Row, Image, Title, Text, Caption, Icon, Badge, List, Button | none |
| WeatherReport | location, unit? (C or F) | Card, Row, Column, Title, Caption, Text, Icon, Chart, List | **fetches** a forecast on the server (Open-Meteo) |

**This package expands FlightCard and WeatherReport** via `a2uiKitMacros`
(`lib/src/macros/`). `catalog.json` (the render contract) still does not
list them: a Flutter app talking to a CopilotKit-style agent that already
expanded gets plain components, and a stray macro on the wire fails like
any unknown component. ProductCard still expands only on the server.

1. It ships `inference-catalog.json` as a document, for apps whose Dart code prompts a model.
2. It renders every component the FlightCard and WeatherReport expansions
   use (including Chart).
3. It tests that a stray macro on the wire fails the way an unknown component does: `a2ui_core` reports it, and
   nothing crashes.
4. `fetchWeather` loads Open-Meteo for a live WeatherReport; gallery
   samples expand a fixed Lisbon forecast with no network.

---

## 5. Architecture

### Package layout

```
tech/packages/a2ui_kit/
  lib/
    a2ui_kit.dart                 public exports only
    src/
      catalog.dart                    a2uiCatalog(), a2uiStandardCatalog(), A2uiCatalogOptions
      document/
        catalog_document.g.dart       generated: the exported catalog.json as a const map
        inference_document.g.dart     generated: inference-catalog.json (model-facing, with macros)
        props.g.dart                  generated: a typed view and enums per component
      theme/                          A2uiCatalogTheme, standard and playground tokens, presets
      foundation/
        css/                          colour and length parsing, oklch, token resolver
        layout/                       css_flex render object, grid and flow layout, CardScope
        text/                         inline markdown, em text styles, sugar-high port
        format/                       format.ts port (formatNumber, money, dates), chart tick formatting
        interaction/                  overlay stack, lightbox, visibility (onVisible), focus helpers,
                                      FormScope, check messages, safeHref/openUrl
        icons/                        lucide_names.g.dart (generated), the 56 A2UI aliases
        motion/                       shimmer, pulse, stagger helpers (reduced-motion aware)
      functions/                      calc, series (+ wiring of a2ui_core's basic functions)
      components/
        standard/{layout,text,inputs,feedback,data,media,composites}/
        playground/{layout,content,data_display,charts,maps,inputs,feedback,domain}/
        extras/blueprint.dart         opt-in internal stand-in
      platform/                       conditional imports: *_web.dart / *_io.dart (iframes)
  tool/
    generate.dart                     catalog.json → lib/src/document/*.g.dart (+ --check mode for CI)
    lucide_icons.g.dart               lucide-react 0.525.0 and 1.57.0's icon nodes and names (tool/src/lucide.dart)
    check_upstream.dart               fixture vs https://a2ui.open.bot/catalog.json
  test/  example/  README.md  CHANGELOG.md  LICENSE  NOTICE.md  pubspec.yaml  analysis_options.yaml  .pubignore
```

Each component file holds one builder and its private widgets. The folder mirrors CopilotKit's grouping, so a
reviewer can put a Dart file next to its Zod definition and React renderer.

### Schemas: generated from the export (recommended)

| Option | For | Against |
|---|---|---|
| Hand-port each Zod schema to `json_schema_builder` | readable | 121 schemas and ~1,400 props drift silently; type errors only show at runtime |
| **Generate from the exported JSON Schema** | exact by construction; CopilotKit's own `exportA2UICatalog` made it; one command to update; CI can prove it is in sync | needs a small generator (Dart, in `tool/`) |
| Load the JSON at runtime from an asset | no codegen | asset loading in every app and test, no typed props, no compile-time check that every component has a builder |

**Recommendation: generate.** `tool/generate.dart` reads `test/fixtures/copilotkit/catalog.json` (the one copy) and
writes three outputs:

1. `catalog_document.g.dart`: the document as a `const` map. Each `ComponentImplementation` gets its schema
   **verbatim** from it (`Schema.fromMap(document['components'][name])`), so the validation, the `common_types` refs
   that `a2ui_core` resolves and the child-ref detection are exactly CopilotKit's.
2. `props.g.dart`: one extension type per component over `ComponentProps`, with typed getters, Dart enums with wire
   names (`TextFieldVariant.longText`) and documented defaults. The doc comments come from the schema descriptions.
3. `inference_document.g.dart`, from `inference-catalog.json`.

The generator also asserts:

- 121 components and 16 functions;
- every component has a builder;
- every enum value is handled. This is checked by tests that loop over the generated enum values.

CI runs `dart run tool/generate.dart --check` and fails on any diff. Updating to a new CopilotKit release means
copying the new export into the fixtures, regenerating, and letting the failing tests and the diff show what changed.
`tool/check_upstream.dart` is run by hand, or on a schedule outside CI. It compares the fixture with the live
`/catalog.json` and reports drift. Writable props and event arguments are not in the export, so a small hand-written
table in the generator holds them; the reviewer checks that table against the Zod sources.

### Public API

| Name | Kind | What |
|---|---|---|
| `a2uiCatalog({A2uiCatalogOptions options})` | function → `CatalogImplementation` | all 121 components and 16 functions under `https://copilotkit.ai/a2ui/catalogs/playground/v1`, with title, description and instructions from the document |
| `a2uiStandardCatalog({…})` | function → `CatalogImplementation` | the 69 standard components under `copilotkit/standard@1` (same schemas, no playground instructions) |
| `A2uiCatalogOptions` | class | `overrides` (name → builder), `includeBlueprint` (default false), `htmlMode` (auto / static / iframe), `embedDelegate` (video and iframe embeds), `mapTiles`, `faviconUrl` builder, `codeHighlighter`, `onOpenUrl` policy, `locale` for formatters |
| `A2uiCatalogTheme` | `ThemeExtension` | section 3; presets `playground`, `standard`, `fromColorScheme` |
| `kA2uiPlaygroundCatalogId`, `kA2uiStandardCatalogId` | constants | the two ids |
| `a2uiCatalogDocument`, `a2uiInferenceCatalogDocument` | `Map<String, Object?>` | the exported documents, for inline catalogs in client capabilities and for agents |
| `a2uiCatalogPrompt({bool macros = true})` | function → `String` | the instructions plus one line per component (name, description, props), built from the inference document, for apps that prompt a model directly |
| props views (`TextFieldProps`, …) | extension types | public, so override builders get typed props |

Everything else stays in `src/`. The package re-exports nothing from `a2ui_flutter` beyond what a caller needs to name
the return types.

### Foundation (phase 1, before the first component)

1. **CSS flex in Flutter.** This is the riskiest piece. CSS flex items shrink (`min-width: 0`), wrap, take gaps,
   and stretch on the cross axis; Flutter's `Flex` overflows instead. The plan is a custom `RenderBox`:
   - main-axis grow (`weight`/`flex`) and shrink with `basis: auto`;
   - `wrap`, `gap`/`rowGap`/`columnGap`;
   - `justify` (start, center, end, spaceBetween, spaceAround, spaceEvenly, stretch);
   - `align` (start, center, end, baseline, stretch);
   - min/max constraints.

   A container reads each child's `weight` from `child.props.peek()` and subscribes to it, as `a2ui_flutter`'s
   `_FlexContainer` does, because a `Flexible` must be a direct child of its `Flex`. Unit tests compare the computed
   rectangles with values measured from CSS cases (written down from the CSS spec rules, not from a browser).
2. **Grid and Flow layout:** the auto-fit track formula, spans, dense packing.
3. **Card scope** (nesting and distance) and the default-gap rules.
4. **Text:** the inline-markdown parser, em-based text styles, and the typography props.
5. **Colours, lengths and tokens** (section 3).
6. **Formatting:**
   - a port of the playground's `format.ts`, which is exact:
     - currency has 0 decimals at |v| ≥ 1000, else 2;
     - percent is not ×100 and has at most 1 decimal;
     - compact has at most 1 decimal;
     - number has at most 2 decimals;
     - a unit is appended with no space when it starts with `%` or `°`, else with one space;
   - the standard Chart formatter (fractions for percent, compact at 10,000 and above);
   - `shortLabel` and the date parsing rule: "YYYY-MM-DD" is local midnight.
7. **Interaction:**
   - the overlay stack (Escape closes the newest overlay);
   - the Lightbox;
   - `onVisible`, firing once;
   - `FormScope`: submit, required fields and custom validity;
   - the check message display and the checks rule (first error, else the first warning or info, shown after blur
     or once the field holds a value);
   - `safeHref` (trimmed; http, https and mailto) and `openUrl`.
8. **Icons:** the generated Lucide name map (kebab-case and PascalCase) and the 56 A2UI aliases from
   `media.tsx`/`media.ts`.
9. **Functions:** `calc` and `series`.
10. **Test harness:** a fixture loader, a surface pump helper that applies A2UI messages to an `A2uiSurface`, a fake
    action sink, golden helpers (light/dark × text scale 1.0/2.0 × width 360/720), and an overflow detector.

### Platform notes

| Concern | Web | Android / iOS | Desktop |
|---|---|---|---|
| HtmlView | `HtmlElementView` iframe, `sandbox=""` + `srcdoc` (exact parity) | `flutter_widget_from_html_core` static render (no JS) | same as mobile |
| YouTube / Vimeo (Video, VideoEmbed) | iframe (`youtube-nocookie.com`, `player.vimeo.com`) | poster + open externally; `embedDelegate` for an in-app player | poster + open externally |
| Video files, audio | `video_player` (web build) | `video_player` | macOS via `video_player`; Windows/Linux need a community implementation, so poster + link |
| Maps | flutter_map raster tiles (CORS-enabled tile servers only) | flutter_map | flutter_map |
| Network images from model output | CanvasKit needs CORS. Use `Image.network(webHtmlElementStrategy: fallback)` so images without CORS headers still show | normal | normal |
| Clipboard (Copy buttons) | needs a secure context (https) | normal | normal |
| Opening links | `url_launcher` with `webOnlyWindowName: '_blank'` | external browser | external browser |
| Hover-only behaviour (Tooltip, Citation, AvatarGroup, chart crosshairs) | mouse | long-press or tap equivalents | mouse |

The iframe code lives behind conditional imports (`dart.library.js_interop`), so `pana` sees all six platforms.

---

## 6. Tests

### Fixtures (in this commit, `test/fixtures/copilotkit/`, provenance and MIT notice in `NOTICE.md`)

| File | Use |
|---|---|
| `catalog.json` | the schema source for code generation; catalog tests |
| `inference-catalog.json` | the prompt document; macro schemas |
| `standard-all.json` | one surface with all 69 standard components and a data model (CopilotKit's own React test fixture): render, validation and golden tests |
| `examples.json` | the three worked examples from the generated agent skill. Two contain macros, so they test rejection; the first tests rendering |
| `replays/*.json` | three recorded playground runs (sales dashboard, Tokyo trip, Lisbon weather) with every streamed frame of A2UI operations, including `Blueprint` stand-ins: streaming tests |
| `samples_ts/*.ts` | the playground's per-component samples (all 52 playground components and the standard previews). They are TypeScript with small helpers (series, a seeded random walk), so they are **not JSON yet**. Converting them is a phase 1 task (open question 4) |

### Test types

1. **Catalog tests:**
   - the generated document equals the fixture;
   - `Catalog.fromJson(fixture)` succeeds;
   - 121 builders and 16 functions are registered;
   - `refMap` finds every child prop in the summary table.
2. **Prop parsing tests**, one group per component:
   - every enum value maps;
   - defaults are applied;
   - wrong types fall back without throwing;
   - `@path` and `@call` values resolve;
   - writable props write the right type (a TextField writes a **string** even for numbers).
3. **Widget tests**, per component:
   - the sample renders;
   - each interaction fires the right action with the right arguments;
   - writes update the data model;
   - checks show at the right time;
   - semantics: labels, roles, header, link, checked, expanded;
   - keyboard paths: Tab, Enter/Space, arrows and Escape, where React has them.
4. **Golden tests** with `alchemist`:
   - CI goldens use the Ahem font, so they are stable across machines;
   - platform goldens use real fonts, made on one machine and reviewed by eye;
   - each component is shot in light and dark, at text scale 1.0 and 2.0, at widths 360 and 720.
5. **Robustness:**
   - no `RenderFlex overflowed` and no exception for any fixture at 320px width and text scale 2.0;
   - empty data, partial streaming props and unsafe URLs are handled.
6. **Streaming:** apply the replay frames in order; every intermediate frame renders, and the final frame matches a
   golden.
7. **Parity vectors ported from CopilotKit's tests** (MIT, keep the notice):
   - `core/…/__tests__/{calc,functions,resolve}.test.ts`;
   - `react-core/…/standard/__tests__/{checks,text,inputs,layout,data,media}.test.tsx` (inline markdown, the checks
     rule, Grid columns, Table and Chart data handling);
   - `shared/…/standard/__tests__/{tokens,theme}.test.ts`.
8. **Formatting parity:** a table of input → expected strings for `format.ts`, the Chart formatter and DataTable's
   cell formats. The expected strings are copied from the comments and tests in the source and checked by hand
   against JS `Intl` behaviour (en-US). Dart `intl` can differ on compact rounding and non-USD symbols; any
   difference is documented or worked around.

### Comparing with the real playground

- Every component has a page at `https://a2ui.open.bot/components/<Name>`, with Preview and "A2UI JSON" tabs.
  `?theme=dark` gives dark mode; `?ds=` picks the design system. A per-phase visual check works like this:
  1. Screenshot each preview, light and dark, at a fixed width and 2× DPR. The user, or a browser-capable agent
     when the user allows it, does this; this laptop runs no browser.
  2. Store the screenshots under `test/reference/` (not shipped).
  3. Put the Flutter golden of the same sample next to each, and list the differences in the phase's review notes.

  This is a side-by-side review, not a pixel diff: fonts and antialiasing differ.
- `/catalog.json` on the live site is the drift check (`tool/check_upstream.dart`).
- The three replays are real runs, so the final frame of each is the closest thing to "what users saw".

---

## 7. Review

Every phase gets a **fresh reviewer agent**, which has not seen the implementation conversation. Its inputs:

- the phase's diff;
- the component blocks of Appendix A;
- paths into the sparse clone at `$COPILOTKIT_SRC` (the Zod or declaration file and the React
  renderer file of each component);
- the fixtures.

It reads the source itself; it is not handed the implementer's conclusions. It reports findings by severity. The
implementer fixes them, and a new reviewer re-checks until no blocking finding is left.

The reviewer checks:

1. **Against the Zod definition** (and `catalog.json`):
   - every prop is handled, or documented as ignored exactly where React ignores it (`mask`, `searchable`,
     `visibleItems`, Callout `icon`…);
   - defaults and enum mappings match;
   - required props behave as in CopilotKit (error until valid);
   - child slots, including nested ones;
   - event names and arguments, writable props and their value types;
   - `checks`.
2. **Against the React renderer:**
   - structure and tokens: sizes, paddings, radii, colours in light and dark;
   - interaction order (for example Button: submit → href → copy → onClick);
   - edge cases: empty data, invalid dates, unsafe hrefs, failed images;
   - animations, and what happens under reduced motion;
   - accessibility semantics.

   A deliberate difference (Flutter overlays are never clipped, mobile has no iframe) must be listed in the
   component's doc comment and in the README's "Differences" table.
3. **Fit and finish:**
   - no overflow at 320px or at text scale 2.0;
   - dark mode works;
   - nothing rebuilds the surface needlessly (signal subscriptions, `const`);
   - controllers and listeners are disposed.
4. **Quality:**
   - the lints pass and every public symbol has a doc comment;
   - there are no `dynamic` leaks or unchecked casts;
   - the tests from section 6 exist for each component and fail when the behaviour is broken: the reviewer spot-checks
     by mutating one line.
5. **Licensing:** ported code (sugar-high, the d3-style layouts, CopilotKit test vectors) carries its notice in
   `NOTICE.md`.

---

## 8. Quality gates for pub.dev

- **Lints: `very_good_analysis` 11.0.0** (MIT, verygood.ventures, a dev dependency only).
  - Why: it turns on `strict-casts`, `strict-inference`, `strict-raw-types` and `public_member_api_docs`. That last
    one is the rule pana's documentation score needs.
  - `flutter_lints` would need most of that added by hand.
  - Two rules may be relaxed in `analysis_options.yaml` with a one-line reason each: `lines_longer_than_80_chars`
    for generated files, and `public_member_api_docs` for `*.g.dart` (excluded instead).
- `dart format` clean, `flutter analyze` at **0 issues** (infos included), `flutter test` green, and
  `dart run tool/generate.dart --check` clean.
- **Doc comments** on every public API, with a short example on the entry points. `dart doc` runs with no warnings.
- **pana** 160/160 (run `dart pub global run pana` in phase 1 and at every phase end). That needs:
  - all six platforms supported (iframe code behind conditional imports);
  - an up-to-date SDK constraint;
  - an `example/` app;
  - README, CHANGELOG and LICENSE;
  - no outdated dependency constraints.
- **`example/`:** a gallery app. Its pages:
  - every component from the fixtures;
  - the three replays played back frame by frame;
  - theme and design switches (playground, standard, Material);
  - a text-scale slider.

  It must build for web and Android.
- **README:**
  - what the package is;
  - "renders the CopilotKit A2UI Playground catalog";
  - setup in a few lines;
  - theme and overrides;
  - a platform table and a "Differences from the React renderer" table;
  - credit: "Component definitions, descriptions and samples are from CopilotKit (MIT), © Atai Barkai."
- **CHANGELOG** from 0.1.0. **LICENSE**: MIT with CopilotKit's copyright line kept (drafted in this commit).
  **`NOTICE.md`** lists ported code and data.
- **Name:** must not contain "CopilotKit" (trademark). pubspec `topics`: `a2ui`, `generative-ui`, `ui`, `widgets`.
  Also set `repository`, `issue_tracker`, and `screenshots` (one gallery PNG).
- `.pubignore` keeps `test/fixtures/copilotkit/samples_ts/`, `test/reference/` and large goldens out of the archive.
  `dart pub publish --dry-run` must be clean.

---

## 9. Phases

Sizes are rough Dart lines including tests: S ≈ 200, M ≈ 500, L ≈ 1,100, plus each phase's shared code. One
implementer agent takes 4–8 components at a time (CLAUDE.md: one subagent per feature, one Flutter agent at a time on
this laptop), and a fresh reviewer closes each phase.

**Phase 1, Foundation + most used** (32 components; 13 S, 18 M, 1 L): Box, Column, Row, Grid, GridItem, Card, Spacer, Divider, Title, Text, Caption, Label, Badge, Markdown, Link, Button, Form, TextField, Select, CheckBox, RadioGroup, List, ListItem, Image, Icon, Section, Heading, Stat, StatGroup, KeyValueList, Alert, Callout.

**Phase 2, Charts** (13 components; 1 S, 6 M, 6 L): Chart, LineChart, AreaChart, BarChart, PieChart, ScatterChart, Heatmap, Sparkline, RadarChart, CandlestickChart, Treemap, SankeyChart, Gauge.

**Phase 3, Maps, media, HTML** (13 components; 2 S, 5 M, 6 L): Map, Favicon, Svg, Video, AudioPlayer, HtmlView, ImageGrid, ImageGallery, VideoEmbed, MapView, RouteMap, LocationCard, PlaceList.

**Phase 4, Inputs and interaction** (24 components; 8 S, 14 M, 2 L): Carousel, CarouselItem, CarouselMediaItem, Tabs, Tooltip, Pressable, TextArea, Radio, Slider, SegmentedControl, ChoicePicker, DateTimeInput, Popover, PopoverTrigger, PopoverContent, Modal, Citation, FollowUp, Accordion, Combobox, Switch, DatePicker, ButtonGroup, ChipSelect.

**Phase 5, Data views and domain cards** (18 components; 9 S, 8 M, 1 L): LinkCard, EntityCard, Avatar, AvatarGroup, DataTable, Timeline, Progress, RadialProgress, Rating, TagList, Agenda, ComparisonTable, WeatherCard, ProfileCard, ReceiptCard, EventCard, StockTicker, RecipeCard.

**Phase 6, The rest** (21 components; 17 S, 3 M, 1 L): Flow, FlowItem, Bold, Italic, Underline, Strikethrough, Blockquote, Code, Math, ShimmerText, PulseIndicator, FlashcardFlip, Table, TableSection, TableRow, TableCell, CodeBlock, Quote, Kbd, Skeleton, EmptyState.

| Phase | Shared work besides the components | Rough size |
|---|---|---|
| 1 | package skeleton, generator, theme, the whole foundation list in section 5, test harness, example gallery shell, README/CHANGELOG, first pana run | ~18k lines (foundation ~5k) |
| 2 | chart kit: ChartFrame, palette, legend, tooltip, axis and tick formatting, monotone path, empty and "waiting" states, wipe-in | ~11k |
| 3 | map canvas (tiles, pins, routes, fit and animate), embed delegate, web iframes, HTML modes | ~10k |
| 4 | overlay pieces (popover anchoring, focus trap, modal), roving focus helpers, date and time formats | ~12k |
| 5 | data-table model (sort, filter, paginate), container-query helper, star and ring painters | ~7k |
| 6 | table layout with spans, dense flow packing, sugar-high port | ~6k |

Order inside phase 1: the foundation, then Column/Row/Box/Card/Grid/GridItem/Divider/Spacer, then the text set, then
Image/Icon/Button/Link, then the forms set, then Section/Heading/Stat/StatGroup/KeyValueList/Callout/Alert/List. At
the end of phase 1 the sales-dashboard replay renders everything but its BarChart (phase 2) and DataTable (phase 5),
and the FlightCard and ProductCard expansions render fully.

### Riskiest components (and why)

| Risk | Components | Why | Mitigation |
|---|---|---|---|
| CSS flex semantics | Box, Column, Row, and everything inside them | Flutter's `Flex` does not shrink or wrap like CSS. Every surface overflows or misaligns if this is wrong | custom render object first, rectangle tests, 320px and text-scale-2.0 sweeps over all fixtures |
| Markdown parity | Markdown (and model prose everywhere) | Streamdown = GFM + math + shiki + mermaid + sanitising + streaming repair; Flutter has no single equivalent | flutter_markdown_plus + custom math syntax + our highlighter + a repair pre-pass; mermaid documented as code |
| Maps | Map, MapView, RouteMap, LocationCard, PlaceList | React uses MapLibre vector styles (OpenFreeMap, CARTO GL); a raster look-alike is close but not identical; tile terms matter for a published package | flutter_map with CARTO raster twins by default, a pluggable tile config, `maplibre_gl` possible through the delegate; open question 3 |
| Iframes | HtmlView, Video, VideoEmbed | no sandboxed iframe outside the web | static HTML on mobile/desktop, poster + external open, delegate hook; listed under Differences |
| Chart look | 13 charts | recharts and TanStack Charts details (monotone curves, crosshair, stacked areas, wipe-in) vs fl_chart defaults; Treemap and Sankey need their own layout algorithms | golden review against the live previews; custom painters where fl_chart cannot match |
| TanStack Table behaviour | DataTable | sort cycle, raw-value search, fraction-percent detection | port the rules, test them one by one |
| Dates and validation | DateTimeInput, DatePicker | wire formats, cross-midnight time slots, custom validity blocking submit, the UTC summary quirk | dedicated tests per rule |
| Overlays and focus | Modal, Popover, Tooltip, Citation, Lightbox | focus trap and restore, Escape order, capture-phase opening | the shared overlay stack, keyboard tests |
| Formatting parity | Stat, KeyValueList, charts, ReceiptCard, StockTicker | JS `Intl` vs Dart `intl` (compact rounding, currency symbols) | formatting parity tests (section 6) |
| Icons | Icon, Stat, Timeline | Lucide versions differ (react-core 0.525.0, playground 1.57.0): resolved 2026-11-21, each renderer draws its own release's icon nodes, stroke width included (INV-006) | generated map + alias table + a test over the names used in fixtures; strokeWeight documented |

---

## 10. Decisions and open questions

**Decided by the user (2026-11-18):**
- Port all 121 components, phase by phase, each phase checked by a separate reviewer before the next starts.
- The package is named **`a2ui_kit`**.
- The default look is the **hosted playground's** (violet accent); CopilotKit's library defaults ship too.
- The 12 TypeScript samples are **converted to JSON by hand**, by reading them. Nothing from CopilotKit's repository
  is run on the laptop.

**Decided by the session owner (2026-11-18, phase 1b):**
- **Hyphenated component ids** (`spacer-l`): a2ui_kit maps them to identifiers and back (`A2uiIdNormalizer`, port
  note 1b-1). Upstream `a2ui_core` 0.8.0 is stricter than CopilotKit: under A2UI 1.0 it accepts only UAX #31
  identifiers as component ids, while CopilotKit takes any string and its own data uses hyphens.
- **Title in the playground look**: a screenshot of https://a2ui.open.bot/components/Title shows it at the
  surrounding text's size and weight, as phase 1a built it (port note 1a-2). The standard look keeps CopilotKit's
  heading sizes.

**Still open (needed by phase 3 and before publishing):**

1. (Decided: `a2ui_kit`.)
2. **Who is the copyright holder and publisher?** The LICENSE draft says "The a2ui_kit authors". pub.dev can
   publish under a verified publisher (a domain you own) or a personal Google account.
3. **Default map tiles.**
   - (a) CARTO raster (light_all / voyager / dark_all) with attribution. It needs no key, but CARTO's free use is
     limited and commercial use needs their licence.
   - (b) No default: the app must pass a tile URL.
   - (c) MapLibre vector styles through `maplibre_gl`, with OpenFreeMap as in React. That is the exact look, but no
     desktop.

   Recommendation: (a) with a clear README note and a one-line override.
4. (Decided: the samples are converted by hand.)
5. (Decided: the playground's look is the default.)

---

## 11. Port notes

Where the code departs from this plan, or cannot match CopilotKit, found while building. Newest phase first.

### Phase 2a (the chart foundation, Chart, LineChart, AreaChart, BarChart, PieChart, ScatterChart, Sparkline)

**Decisions taken**

1. **No `fl_chart`: every chart is a `CustomPaint`** of a scene built for its size (`foundation/chart/plot.dart`:
   `PlotScene`, `ChartPlot`). Per chart, what `fl_chart` 1.3 cannot reach:
   - LineChart, AreaChart, Sparkline: the playground's curve is chart-kit's Fritsch-Carlson monotone cubic; `fl_chart`'s
     `isCurved` is a Catmull-Rom spline with a smoothness factor (`preventCurveOverShooting` only flattens its control
     points), so the lines would bend differently. Stacked areas need a 1px surface line between bands.
   - BarChart: TanStack's band scale (padding .24 or .32), group padding .12 and thickness caps (18, 40, 22), and the
     4px rounding of only a stack's outer ends; `fl_chart` sizes rods in pixels with fixed group spacing.
   - PieChart: d3-style arcs with a pad angle (.025 rad) and rounded corners (4px, 2px); `fl_chart` has neither.
   - ScatterChart: `fl_chart` could draw the dots, but not the axes, tooltip and focus states the other charts share;
     two axis systems would drift apart.
   - Chart (standard): recharts' own geometry (nice ticks, bands with 10% gaps and 4px bar gaps, `monotone` =
     d3's `curveMonotoneX`, sectors with recharts' corner rounding, legend and tooltip).

   `fl_chart` is therefore not a dependency. The phase 2b charts (Heatmap: band × band cells; RadarChart: polar
   scenes; CandlestickChart: bands; Treemap, SankeyChart: layouts; Gauge: an arc) fit the same `PlotScene`.
2. **The foundation** (`lib/src/foundation/chart/`): `scale.dart` (d3's `ticks`, `tickIncrement`, `nice`, band and
   point scales; recharts' nice and fixed ticks and its number-axis domain rule), `curve.dart` (chart-kit's monotone
   cubic and d3's `curveMonotoneX`), `arc.dart` (d3's `arc` with pad angle and corners; recharts' `Sector`),
   `plot.dart` (the interactive host: pointer, tap and arrow-key focus, tooltip placement, the 700ms `ChartReveal`
   wipe, the `ChartTableSemantics` hidden table, `ChartText`). The playground's frame, legend, empty state, shimmer,
   boundary and tooltip are `components/playground/charts/chart_kit.dart`; the number formats (`format.ts`,
   `tickFormatter`, `shortLabel`, `makeFormatter`, en-US compact notation) are `foundation/format/chart_format.dart`,
   on the shared shortest-decimal rounding.
3. **Colours:** `A2uiChartColors` (`A2uiPlaygroundTokens.charts`) holds `renderers.css`'s `--a2-chart-*`,
   `--a2-heat-*` and `--a2-tooltip-*`, light and dark, and the shimmer (`--gen-strong` at 12%). The standard Chart
   reads `--a2ui-chart-1..6` and the text, border and cursor tokens of `A2uiKitTheme`.

**What is not in the source, and was rebuilt** (each marked `TODO(port)` where it sits)

4. **TanStack Charts 1.1 is not in the clone,** only the playground's chart definitions. Ported as stated: scales,
   paddings, tick counts, curves, stroke widths, opacities, gradients (`objectBoundingBox`), focus modes and states,
   tooltip rows, heights, label cuts. Rebuilt by judgement: the margins (8px above and right), the tick text (11px,
   tabular), where axis titles sit, the crosshair's stroke, the size of line points (the Sparkline's end dot), label
   thinning (4px apart), the tooltip's inside (its chrome is `TOOLTIP_VARS`), the scatter focus distance (40px), the
   nice count (`nice(5)` as the ticks' count), stack offsets (bars diverge from 0, areas stack from 0) and the pie's
   order (data order; d3's pie would sort by value). TanStack's own SVG transitions (`svgAnimation`) are not drawn;
   the CSS grow-in is.
5. **recharts 3.10 and d3 are not in the clone either.** Their algorithms are ported from their published sources
   as remembered, with recharts' decimal.js arithmetic stood in for by rounding to 12 significant digits. The parity
   tests from `chart.test.tsx` and `chart-scatter.test.tsx` (`test/parity/`) pin the geometry they assert; the rest
   should be checked against the libraries. One consequence to check on the live playground: CopilotKit passes
   `domain={[min ?? "auto", max ?? "auto"]}`, replacing recharts' default `[0, "auto"]`, so an axis runs over the
   data's own range made nice and the lowest bar can be 0px tall (the "Signups by week" sample's W1).
6. **The recharts tooltip** keeps recharts' white box in the dark, with the category in the surface's text colour,
   as CopilotKit leaves it (`BUG(port)`).

**What Flutter does differently** (each also in the README's Differences table)

7. **Accessibility:** every chart's drawing is an image named by its title (TanStack's `ariaLabel`, the standard
   Chart's `figcaption`) followed by hidden 1px rows that read each cell after its column (`ChartTableSemantics`);
   the standard Chart's drawing is excluded, as its `aria-hidden` is. The drawing takes the keyboard focus: the arrow
   keys move between x groups (or points, or slices) and Escape clears the focus.
8. **Painted text** (axis ticks, value labels) is `TextPainter` text: alchemist's CI goldens draw it in black.
9. **Sizing:** a drawing's width is the width offered (320 when unbounded, recharts' starting width); its minimum
   intrinsic width is 0 and its maximum 320, so a chart in a Row or Grid sizes as `w-full min-w-0` does. The plot's
   `LayoutBuilder` never answers intrinsic or dry layout questions itself (`_PlotSizer`).
10. **The standard Chart** has no lazy loading, so neither the placeholder nor the visible data-table fallback.

**Found for later phases**

11. Phase 2b's Heatmap needs `color-mix(in oklch)` (`A2uiChartColors.heatLow` is in place); Treemap and SankeyChart
    need their layouts and `guardChart`'s "Waiting for complete data" for half-sent links.

### Phase 1 second review fixes

1. **Ownership** ends only with `deleteSurface`, as in CopilotKit: a `createSurface` for a surface that exists, which
   `a2ui_core` refuses, no longer lets later writes in the batch through. A v1.0 `updateDataModel` without `value`
   passes as sent (the processor reports it) instead of gaining the merged value.
2. **`formatNumber` and `formatCurrency`** round the shortest decimal half away from zero before `package:intl`
   formats it (`foundation/format/decimal.dart`, shared with `formatPlaygroundNumber`), so `1.005` at two decimals is
   "1.01" as in `Intl.NumberFormat`.
3. **The date names' bundle cost** (finding N10): `formatting.dart` imports `date_symbol_data_local.dart` for month and
   weekday names. A release `flutter build web` of the example measured `main.dart.js` at 4,973,863 bytes with the
   import and 4,974,002 bytes with English names only (the difference is noise from an unrelated edit between the
   builds): `a2ui_core` 0.8.0 already imports the same data (`basic_catalog/locale_formatting.dart` calls
   `dateTimeSymbolMap()`), so every app on it pays for it whatever a2ui_kit does. The import stays.
4. **Tests that passed without testing.** After an `updateComponents` that resolves a pending child of a Form, the
   TextField beside it gets a new `EditableText` state a frame later (seen in the tests: the old state is gone), so
   text entered before that frame never reaches the field. Phase 1's "default button" test typed too early and passed
   without submitting; it and the new tree-order tests now settle first and check that the text arrived. **Found for
   later:** why the field's editable text is rebuilt is not investigated; if a user is typing when the agent streams a
   sibling in, the keyboard connection may drop.

### Phase 1 review fixes

1. **Functions** are all the kit's now, but `openUrl` (`a2ui_core`'s, behind the scheme check): CopilotKit's
   formatters, `pluralize`, `and`, `or`, `not` and `formatString` are ported. A `DocumentFunction` keeps the
   document's definition (export and message validation are unchanged) but checks resolved args against no schema,
   as CopilotKit's renderer checks none: `and` of `["Ada", true]` is true, not a schema error. Where CopilotKit asks
   `Intl` in the browser's locale, the port asks `package:intl` in `A2uiKitOptions.locale`. English currency
   symbols follow CLDR (`CA$`, a no-break space after a symbol that ends in a letter); other locales take
   `package:intl`'s simple symbols. `formatDate` reads ISO 8601 text and millisecond timestamps; `Date`'s
   engine-specific forms ("Oct 19, 2026") are not read. Fraction digits above 15 are cut to 15 (`package:intl`'s
   limit; `Intl` takes 100). `formatString` of null is "" (CopilotKit throws), so a template still streaming in
   does not report an error.
2. **User-owned data.** `A2uiUserOwnedData` ports the surface manager's owned values. Ownership is kept per
   `SurfaceModel` (an `Expando`), so a new surface for an old id starts with none; a `createSurface` or
   `deleteSurface` earlier in the same batch counts too. CopilotKit's forbidden path segments (`__proto__`…) need no
   check: `a2ui_core`'s `DataModel` refuses them, and a refused write is not marked. The app must pass the agent's
   messages through `filterMessages`; without it the agent still overwrites what the user typed.
3. **Literal values** keep the user's edit until the control is rebuilt from scratch (CopilotKit: until
   remount). A number field writes "" while its text is not an HTML valid floating-point number (`-`, `1e`, `.`)
   and blocks a Form with "Please enter a number."
4. **Table ids.** The normaliser rewrites the `componentId` (or `id`) of Table columns and row cells, in the props
   and in the data a `rows` binding reads (absolute paths, and relative ones by their last segments). Data that
   arrives before the Table that reads it is not rewritten.
5. **Scrolling.** A scrollable container's scroll view is a flex item with min width and height 0, so a
   `height` or `maxHeight` box scrolls. CSS's `overflow: auto` scrolls both axes; the port scrolls the main axis
   (a Grid: vertically).
6. **KPI values** shrink below the 14px floor (scaled) when it would push them out of their container; React
   lets them overflow.
7. **A List's line** is a CSS flex row (`space-between`, baseline): a value wider than the row overflows it, as in a
   browser.
8. **Links and the overlay button** take the keyboard focus (`Activatable`). A span cannot hold the focus, so
   each inline link's focus node is an empty widget at the Text's start: the focus scrolls there, and the link is
   tinted, not outlined.
9. **The key/value row rule** applies only when `A2uiKitTheme.keyValueRows` is set (the standard look): the
   playground wraps each component in a `display: contents` element that the rule's child selector does not see
   through.
10. **Not drawn:** the dark playground card's `inset 0 1px 0` highlight (Flutter's shadows have no inset); Grid's
    `rows`.
11. **The repository's `.gitignore` drops every `media/` folder**, so `lib/src/components/standard/media/` was not
    committed in phase 1b; the package's `.gitignore` re-includes it.

### Phase 1b (the other 19 phase 1 components, functions, icons, markdown, forms, ids)

**Decisions taken**

1. **Component ids: `A2uiIdNormalizer`** (`lib/src/ids/id_normalizer.dart`, public). `a2ui_core` 0.8.0 is stricter
   than CopilotKit (section 10). The app feeds the agent's messages through `normalizeMessages` and maps what goes
   back with `outboundAction`, `outboundError` and `outboundValue`. An identifier stays as it is; any other id gets
   each character an identifier cannot hold replaced with `_` (`spacer-l` → `spacer_l`, `2col` → `_2col`), and
   `_2`, `_3`… when the name is taken, also by a real id that arrives later, so the map stays one to one for the
   normaliser's life (one per conversation). Rewritten: each component's `id`; the child references the catalog's
   schemas declare (`refMap`: single ids, id lists, `{componentId, path}` templates, ids in arrays of objects such
   as `tabs[].child`), in the v1.0 and v0.9 component shapes; and `{"componentId"}` cells (Table rows) in component
   props and the data model. Mapped back: an action's `sourceComponentId`; an error's quoted ids
   (`'mapCard_title'`), path segments and `details` strings; cells in data-model values. Not touched: an action's
   context (the model's own values) and any other string. `standard-all.json` and every frame of the tokyo-trip
   replay validate and render through it without the tests' `withIdentifierIds` (`test/ids/`); the older tests
   keep that helper.
2. **Title** stays as built in 1a (section 10).

**Departures from this plan**

3. **59 A2UI icon names**, not 56: `A2UI_ICONS` in react-core's `media.tsx` has 59 entries.
4. **The five validators are ports of CopilotKit's** (`required`, `regex`, `length`, `numeric`, `email`;
   `lib/src/functions/validators.dart`), not `a2ui_core`'s, so a failed check shows CopilotKit's message and code
   ("Required"/`required`, "At least 3 characters"/`tooShort`…). The other nine basic functions stay
   `a2ui_core`'s.
5. **`calc` and `series`** are ports of `calc.ts` with its test vectors, keeping JavaScript's number rules:
   `Math.round` rounds halves up (`round(-2.5)` is -2), `Number()` reads `" 12 "`, `0x10` and `1e3`, numbers join
   text as `String()` writes them (`3`, not `3.0`). Numbers come back as doubles.
6. **Writable props and event arguments** are a hand-written table in the generator, checked against the catalog
   (every `Action` prop must be named; a writable prop must take a binding) and emitted as
   `lib/src/document/behaviour.g.dart` (`writableProps`, `eventArguments`, both public).
7. **Lucide icons** (`tool/src/lucide.dart` → `lucide_icons.g.dart`, regenerated by `tool/generate.dart`; superseded
   the flutter_lucide font on 2026-11-21, RULEBOOK §1): lucide-react's own icon nodes, read from the published
   packages CopilotKit's lockfiles pin (0.525.0, react-core's; 1.57.0, the playground's), in one node table with each
   release's `icons` map and its exported aliases. `LucideRelease.reactCore` draws for the standard components (the
   Icon among them, in either look: the playground installs react-core 1.85.0, whose lucide-react is 0.525.0),
   `LucideRelease.playground` for the playground's own. A name is looked up as CopilotKit's `kebabToPascal` does,
   in that release's `icons` only (an alias such as `alert-circle` draws nothing, as in React); a renderer's static
   import (`AlertTriangle`) goes through `lucideImport`. `LucideGlyph` strokes each element as lucide-react's `<svg>`
   (round caps and joins, the stroke width on the 24 grid, `fill="currentColor"` dots in the text colour). Only the
   Icon component reads A2UI names (`arrowBack`); Button, Select and List icons take Lucide names, as in React.

**What Flutter does differently** (each also in the README's Differences table where users see it)

8. **Checks** (changed in the phase 1 review) are CopilotKit's `firstFailedCheck`, ported: the builder reads the
   rules as the agent wrote them and resolves each `condition` and `message` itself in a quiet data context (the
   engine resolves them too and reports their errors once), so a rule without a condition, or one whose condition
   is not known yet (an unset `@path`), passes; `false` fails with the rule's message; a failed validation result
   fails with the rule's message, else its own, at its severity. `a2ui_core`'s `validationResults` are not read:
   they cannot tell an unknown condition from a false one. A condition of any other type (a string) passes, where
   CopilotKit's Zod schema rejects the prop.
9. **Event arguments.** `a2ui_core`'s action closures take no arguments, so a List pick resolves an `{"event"}`
   binding itself and puts `{index, label, value}` into its context (the binding's own entries win), as
   `invokeBoundEvent` does. A `{"functionCall"}` binding gets them in its args, its own args winning (since
   the phase 1 review).
10. **Forms** emulate the browser's constraint validation, which CopilotKit leaves to the native `<form>`: before
    `onSubmit`, a required TextField, Select, CheckBox or RadioGroup, an `email` or `url` TextField that holds no
    email address or URL, stops the submit; the first such field shows Chrome's English message under it ("Please
    fill out this field.") in place of the browser's bubble and takes the focus. Disabled fields are exempt;
    `checks` never stop a Form. Enter in a single-line field submits as HTML's implicit submission does (with a
    submit button, unless the first is disabled; without one, when it is the form's one single-line field).
    DateTimeInput's and ChoicePicker's custom validity come with them in phase 4.
11. **TextField**: a literal `value` keeps the user's edit until the literal changes (CopilotKit: until the node
    remounts). `name` and `mask` are ignored, as there is no native form post (React ignores `mask` too).
    `longText` is a three-row text area. A field's text is drawn by Material's `TextField`, so it needs Material
    localizations: a surface supplies English ones when the app has none (the Select's menu too).
12. **Select** opens a Material menu where the browser opens its native list; Up and Down change the value without
    opening it, as a native select does on the desktop. With `block: false` it is as wide as the chosen label, not
    the widest option. `searchable` is ignored, as in React.
13. **CheckBox and RadioGroup** draw CopilotKit's 20px controls with a painter. A RadioGroup has one tab stop (the
    chosen radio); the arrow keys choose the next or previous option, wrapping. A disabled group is inert but not
    greyed (CopilotKit's disabled fieldset has no style). Focus rings follow Flutter's highlight mode (keyboard
    focus), like `:focus-visible`; a text field's shows whenever it is focused.
14. **Image** sizes itself as CSS sizes an `<img>` (`RenderReplacedBox`: width, height, limits, `aspect-ratio`
    and the image's own size, the ratio kept when one side is clamped or imposed by the parent). Its own size comes
    from the image stream; on the web, an image without CORS headers falls back to an `<img>` element whose size
    Flutter cannot read, so it counts as CSS's 300×150. A failed image without `fallback` shows its description
    (a browser draws a broken-image sign). The lightbox is a route of the root `Navigator` (Escape and a click
    close it).
15. **Markdown** is `flutter_markdown_plus` with the GitHub-flavoured extension set (tables, task lists,
    strikethrough, autolinks) and `$$…$$` math by `flutter_math_fork`, inline and as a block (Streamdown's default:
    single dollars are not math). The styles are Streamdown 1.x's default components (`text-3xl` to `text-sm`
    semibold headings, 16px between blocks, accent underlined links, muted inline code, a 4px quote border, bordered
    tables), **written from memory of Streamdown's source**, which is not in the sparse clone, and not compared with
    the playground: whether the playground's Tailwind build even generates those classes is unknown. Not ported:
    shiki highlighting (code is plain until the sugar-high port, phase 6), mermaid (drawn as code), raw HTML (shown
    as text), and the copy and download buttons of code blocks and tables. `streaming` runs a subset of `remend`
    (`repairIncompleteMarkdown`: open fences and math blocks, `**`, `__`, `~~`, `` ` ``, `*`, half-sent links and
    images). Links open only for http, https and mailto URLs.
16. **List** draws the browser's outside marker itself (`•` or `n.` in the 1.5em padding, top-aligned to the first
    line, so on its baseline); a non-ListItem child of a bullet List gets the padding without a marker. A
    horizontal list's items align to the top (CSS stretches them). The list is a list for screen readers.
17. **Stat and StatGroup** ("@container"): a card's content does not size it along the inline axis
    (`InlineSizeContainer`), and the KPI value's font (`clamp(14px, fit cqi, max)`) follows the width its parent
    allows, which is the card's content width (`KpiLine`, the cell's column). The text scale raises the 14px floor
    and the ceiling; the fit term still keeps the value in the card. Each glyph is its own box, as CopilotKit's
    spans are, and pops in (500ms, 70ms apart, the same overshoot) without the 2px blur. A phrase wraps at spaces
    but, unlike `word-break: keep-all`, Flutter may break a word too long for the card.
18. **Heading**'s words fade in (350ms, 60ms apart, only the new ones when the text grows) without the 1px blur;
    `text-wrap: balance` and `pretty` have no Flutter equivalent.
19. **KeyValueList** lays its rows out in one render object, by the card's content width (stacked under 256px; 2
    columns from 448px and 3 from 672px when `columns` allows); the dashed lines are 3px dashes 3px apart.
20. **Alert and Callout** use Tailwind 4's sky, emerald, amber, rose and violet at the playground's strengths, as
    theme tokens (`A2uiPlaygroundTokens.alerts`, `.callout`); the Callout's button is shadcn's secondary `sm`
    (`secondary` and `secondaryForeground` tokens). No hover colours.
21. **Entrance animations** (`a2-enter`, the panel and skeleton reveals) belong to the playground's surface host,
    not to its components: not ported.
22. **`fromColorScheme`** follows the playground's Material design system (`themes.ts`, `design-systems.css`).
    Material has no tone 80 colour role for the error and tertiary colours, so their light borders mix the
    container with the colour; success and warning, which Material has no roles for, are the design system's own
    greens and ambers. The design system's leaf overrides (its Badge, Button, Heading…) are not part of a theme;
    `A2uiKitOptions.overrides` is the way.
23. **Goldens**: alchemist's CI goldens draw text painted outside a `RenderParagraph` (the KPI values, a text
    field's text) in black; the widget tests check those colours.

**Found for later phases**

24. `Blueprint` (the playground agent's stand-in) draws when `A2uiKitOptions.includeBlueprint` is set, and
    stays out of the exported catalog. The gallery and the replays turn it on. See Appendix A.
25. `standard-all.json`'s TextArea draws nothing until phase 4, though TextField's `longText` already is one.
26. `a2ui_flutter` does not export its write-back helper, so a2ui_kit has its own (`valueWriter`).

### Phase 1a (foundation, layout and text basics)

**Needs a decision**

1. **Component ids.** `a2ui_core` 0.8.0 validates A2UI 1.0 payloads strictly: a component id must be a UAX #31
   identifier (`validator.dart`, `_checkComponentHeader`). CopilotKit accepts any string, and its own data uses
   hyphens: `standard-all.json` (`spacer-l`, `gi1-t`) and the recorded `tokyo-trip` replay (`mapCard-title`). So a real
   playground surface can fail validation in a Flutter app, whatever this package renders. The tests rewrite such ids
   (`withIdentifierIds` in `test/helpers/harness.dart`). Options: ask a2ui_core to relax the id rule (it is not in the
   catalog's control), or add an id normalizer to a2ui_kit that rewrites ids before processing and maps them back in
   outbound actions (`sourceComponentId`). **Resolved in phase 1b:** the normaliser (phase 1b note 1).
2. **Title in the playground look.** The playground's `globals.css` (lines 238–247) reverts every `h2`–`h4` in a
   surface to the layered styles, `revert-layer`, and Tailwind's preflight there sets `font-size: inherit;
   font-weight: inherit`. So on a2ui.open.bot a standard Title takes the size and weight of the text around it, not the
   1.5/1.25/1em at 600 of section 3. `A2uiKitTypography.playground()` follows the CSS (headings inherit);
   `A2uiKitTypography.standard()` keeps CopilotKit's fallbacks. **Settled in phase 1b** by a screenshot of
   `/components/Title`: the playground's Title takes the surrounding size and weight, as built.

**Departures from this plan**

3. **Names follow the package name.** `a2uiKitCatalog`, `a2uiKitStandardCatalog`, `A2uiKitOptions`, `A2uiKitTheme`,
   `A2uiKitLook`, `a2uiKitCatalogDocument`, `a2uiKitInferenceCatalogDocument`, `a2uiKitCatalogPrompt` replace
   `a2uiCatalog`, `A2uiCatalogTheme` and the rest of section 5, which predate the name. The two id constants keep
   their names.
4. **The documents are JSON text, decoded once,** not `const` map literals: the same content (a test compares it with
   the fixture), and the analyzer stays quick with a 520 KB literal. `catalog.toJson()` writes the fixture back.
5. **Props views** cover top-level props: arrays and objects stay raw (`List<Object?>`, `Map`), unions of types are
   `Object?`, and a "string or number" (Text `text`) is a `String`. Defaults come from the schema descriptions
   ("Default …", 109 props). These are documented defaults, not always React's behaviour for an absent prop: Text
   `size` reads `md`, but React inherits the size when it is unset, so the Text builder reads the raw prop.
   Shared enums are named in a table in the generator (`sharedEnumNames`); a new shared value set stops the
   generator until it is named. `default` becomes `default_`, a leading digit a word (`2xl` → `twoXl`).
6. **Functions.** The 14 basic functions are `a2ui_core`'s, wrapped so that each keeps the exported definition
   (CopilotKit's argument schemas, which differ from a2ui_core's). `openUrl` opens http(s) only, as CopilotKit's does
   (a2ui_core also allows `mailto:` and `tel:`). `calc` and `series` are declared and fail with an execution error
   until they are ported (phase 1b).
7. **Unported components** are in the catalog, so they validate, and draw nothing (`SizedBox.shrink`).
8. **Goldens are CI goldens only** (text as blocks, no shadows), the same on every machine. Platform goldens with real
   fonts need a by-eye review, which this laptop does not do; generate them on a reviewer's machine.

**CSS that Flutter does differently** (each also in the README's Differences table where users see it)

9. **Flex layout** is `RenderCssFlex`, the CSS Flexible Box algorithm (section 9: flex base and hypothetical sizes,
   line breaking, resolving flexible lengths with min/max freezing, line cross sizes, stretch, `justify-content`,
   `align-items`/`align-self`, baseline in rows, auto start margins, `wrap-reverse`, RTL). A child's max-content width
   is its maximum intrinsic width and its min-content width its minimum intrinsic width; a column child's content
   height is its height at its used width. The parent always hands a child tight width constraints (stretched or
   fit-content), so a child never needs to know what it is in; a box given loose constraints fills them, as a block
   does, unless it is `inline`. Not modelled: `safe` alignment (with negative free space `spaceAround` and
   `spaceEvenly` centre, as Flexbox Level 1 says), percentage heights against an indefinite height, `align-content`
   other than CSS's `normal`. The rectangle tests in `test/layout/` were computed by hand from the CSS rules.
10. **`scrollable`** wraps the content in a scroll view along the main axis: the box stays, the padded content scrolls.
    In CSS the items first shrink to the box and only the rest scrolls; here they keep their content size along the
    scroll axis.
11. **Grid** is `RenderCssGrid`: CopilotKit's auto-fit template formula, empty auto-fit columns collapsing, sparse
    row-by-row auto-placement, spans clamped to the rendered columns (which is the `1 / -1` rule, so the React
    `GridColumnsContext` is not needed), row spans spreading what they lack evenly. `rows` is accepted and ignored (all
    rows are auto). String templates: lengths, `fr`, `auto` and the content keywords (as `1fr`), `minmax()`,
    `repeat(n, …)` and `repeat(auto-fill|auto-fit, minmax(L, 1fr))`; anything else is equal columns. With an
    indefinite width (inside a Row) a Grid is one column wide, as CSS's auto-repeat is.
12. **Grid and GridItem** wire neither `onVisible` nor `role`, as in React.
13. **`onVisible`** (`VisibleOnce`) fires once, after the first frame in which the box overlaps the view and every
    enclosing scrollable; it rechecks on scroll.
14. **`role`** maps only the ARIA roles Flutter can express without semantics-role checks failing: heading, button,
    link, img, list, form, dialog, alertdialog, tabpanel. React's implicit `group` for a named container has no Flutter
    role; `a2ui_flutter`'s `NodeView` makes a labelled node a semantics container instead. A Divider has no separator
    semantics in Flutter.
15. **Type.** CopilotKit's surface inherits the page's font, size, line height and colour. The first a2ui_kit
    component of a surface installs a `DefaultTextStyle` from the theme instead: 16px, line height 1.5 in the
    playground look (Tailwind's `html`), the font's own in the standard look, and the default text colour. Geist is not
    bundled. Inline marks follow the page too: in the playground (preflight) links keep the text colour without an
    underline and code is 1em monospace; the standard look uses a browser's defaults (`#0000ee` underlined links, 13px
    code).
16. **Colours.** `oklch()` is converted with the OKLab matrices and clipped per channel; browsers gamut-map (the dark
    playground accent `oklch(0.72 0.17 292)` is outside sRGB). Shadows convert CSS blur to Flutter's blur radius so
    the Gaussian is the same.
17. **Lengths.** `rem` is 16px; spacing does not follow the user's font-size setting as CSS's `0.25rem` steps would:
    text scale scales text only. Line heights in pixels scale with the text.
18. **Faithful oddities, kept:** a Badge directly in a stretching Column is as wide as the column (CSS blockifies the
    `inline-flex`); a block Text's `highlight` fills its whole box; a horizontal Divider in a Row is 100% wide and does
    not shrink.
19. **Found for later phases:** `--a2ui-color-shimmer` has two fallbacks in CopilotKit (`#d9d9d9` in ShimmerText,
    `rgba(255,255,255,.55)` in `tokens.ts`); the theme holds the second. A mid-stream frame of the `tokyo-trip` replay
    sends an Agenda that fails its schema; a2ui_core reports it.

---

## Appendix A: every component and prop

Generated from `test/fixtures/copilotkit/catalog.json` with the React and Flutter notes of this plan. Types leave out
the `{"@path"}` / `{"@call"}` alternative that every prop has. "Default" comes from the schema; where the schema says
nothing, the renderer's default is in the React note. Shared groups (Layout props, Typography props, `checks`) are
in section 2.

### Standard: Layout

#### Box

*Standard · Layout · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A flex container. It stacks its children in a column (direction "row" puts them in a row). Use it to group children with gap, padding, border, radius or background.

**Children:** `children` (ChildList) · **Events:** `onVisible` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `direction` | enum(col \| row) | `"col"` | Default "col" |

- **React:** A flex `div` (column by default) through `layoutStyle`. Default gap: 16px outside a Card and for a container directly in a Card, 8px deeper; `disableAutoSpacing` sets 0. Inside a Card a bordered Box becomes the inner panel (padding `padding ?? 12px`, radius 8, panel fill, no border). `onVisible` fires once (IntersectionObserver).
- **Flutter:** `A2uiFlexBox` on the foundation's CSS-flex render object (grow, shrink, wrap, gap, baseline). Card depth via an `InheritedWidget` (`CardScope`: nested?, distance). `onVisible` through a visibility detector built on `RenderAbstractViewport`/scroll notifications (no package).
- **Packages:** SDK only

#### Column

*Standard · Layout · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A vertical flex container. Its default gap already separates sections, so do not add padding, background or a Spacer for space.

**Children:** `children` (ChildList) · **Events:** `onVisible` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |

- **React:** A column container with the default-gap rule.
- **Flutter:** Thin wrapper over `A2uiFlexBox` (direction column).
- **Packages:** SDK only

#### Row

*Standard · Layout · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A horizontal flex container. Label and value pair: justify "spaceBetween", a Caption left and a Text with fontWeight "medium" right. Buttons go in a Row at the bottom of a Card: one variant "primary", the others default or "borderless".

**Children:** `children` (ChildList) · **Events:** `onVisible` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |

- **React:** A row container; align-items center unless `align` is set; gap always 8px unless set. `data-a2ui-row=<justify>`: in a `spaceBetween` Row, the last Text (not the only child) is pushed right with `margin-inline-start:auto` (the key/value row idiom).
- **Flutter:** `A2uiFlexBox` (row) with children that shrink like CSS `flex: 0 1 auto` (Text gets `Flexible(fit: loose)`), and the spaceBetween last-Text rule. Overflow must never throw: test long text at 320px and text scale 2.0.
- **Packages:** SDK only

#### Grid

*Standard · Layout · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A CSS grid container. On a narrow screen, its columns collapse towards one column.

**Children:** `children` (ChildList) · **Events:** `onVisible` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `columns` | number or string | `2` | Column count or CSS template. Default 2 |
| `minChildWidth` | number or string |  |  |
| `rows` | number or string |  |  |

- **React:** CSS grid. Numeric `columns` (default 2): auto-fit tracks with min width T = round(max(120, 520/n)), so rendered columns = clamp(floor((W+gap)/(T+gap)), 1, n). String `columns` is a raw template; `minChildWidth` uses auto-fill; gap 16. A ResizeObserver hands the rendered track count to GridItems. `onVisible` declared but not wired.
- **Flutter:** `LayoutBuilder` computing the track count with the same formula, rows built as `Row`s of `Expanded` cells (equal height per row via `IntrinsicHeight` only when needed) or a custom `RenderBox`; the count goes to GridItems through an `InheritedWidget`. A raw CSS template string: support `repeat(n, 1fr)`, `Npx`, `Nfr`; anything else falls back to equal columns.
- **Packages:** SDK only

#### GridItem

*Standard · Layout · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A cell of a Grid, with an optional span. A span that covers all rendered columns fills the row.

**Children:** `children` (ChildList) · **Events:** `onVisible` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `span` | number |  |  |
| `rowSpan` | number |  |  |

- **React:** A column flex cell. `span` >= rendered columns becomes a full row (`1 / -1`), else `span N`; `rowSpan` → `span N`.
- **Flutter:** Reads the track count from Grid's scope; spans handled by the Grid layout (row spans: v1 supports them in the custom grid render object, or documents a fallback).
- **Packages:** SDK only

#### Card

*Standard · Layout · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A bordered panel, only for an interactive panel (controls, a form, a configurator); tables, charts and text need none. Give it a Title and a Caption. Separate groups with a Divider or the gap, never a nested Card or bordered Box. Variant "section": no box; "outline": always a box. In markdown mode, without controls it renders as "section" unless variant or border is set.

**Children:** `children` (ChildList), `child` (ComponentId) · **Events:** `onVisible` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `child` | ComponentId |  |  |
| `variant` | enum(default \| outline \| section \| soft \| elevated \| transparent) |  |  |
| `shadowStyle` | enum(none \| sm \| md) |  | Overrides the shadow of the variant |
| `size` | enum(sm \| md \| lg) | `"md"` | The padding preset: 8, 16 or 24px. Default "md" |

- **React:** Single `child` slot first, then `children`. Top level: column, gap 16, padding by size sm 8 / md 16 / lg 24 (`flush` 0), radius `xl` (16px), 1px border, `soft` → surface-secondary, `elevated` → soft shadow, `shadowStyle` none/sm/md wins. Nested Card (not `outline`) flattens: no border/shadow, gap 12. `section` variant: no box. Provides card nesting/distance to its subtree.
- **Flutter:** `DecoratedBox` + `Padding` + `A2uiFlexBox`; `CardScope` inherited widget carries nesting and distance; variants and size map to tokens.
- **Packages:** SDK only

#### Flow

*Standard · Layout · size M · phase 6 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A masonry-like grid that packs cells of different sizes. Put FlowItem children in it.

**Children:** `children` (ChildList) · **Events:** `onVisible` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `columns` | number |  |  |
| `rows` | number |  |  |
| `layout` | enum(pack \| fixed) | `"pack"` | Default "pack" |

- **React:** A grid using Grid's auto-fit template; `columns` default 3; gap `gap ?? 4` steps (16px); `layout` pack (default, dense auto-flow) or fixed. `rows` unused.
- **Flutter:** Reuse the Grid layout with a dense-packing placement pass (spans 1–n, rowSpan).
- **Packages:** SDK only

#### FlowItem

*Standard · Layout · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A cell of a Flow, with an optional span.

**Children:** `children` (ChildList) · **Events:** `onVisible` · **Layout props:** all 30 except `aspectRatio`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `span` | number |  |  |
| `rowSpan` | number |  |  |
| `aspectMode` | enum(soft \| fixed) |  |  |
| `aspectRatio` | string | `"1 / 1"` | Default "1 / 1" |

- **React:** A column container with span/rowSpan; aspect-ratio defaults to 1 / 1. `aspectMode` unused.
- **Flutter:** `AspectRatio` cell inside Flow.
- **Packages:** SDK only

#### Carousel

*Standard · Layout · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A horizontally scrolling row that snaps to its CarouselItem or CarouselMediaItem children, with arrows. Bind activeIndex to read or set the slide in view.

**Children:** `children` (ChildList) · **Events:** `onVisible` · **Writes back:** `activeIndex` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `activeIndex` | number |  | The index of the slide in view. Bind it with { "@path": "/x" } to read or set it |
| `label` | string |  | A short name of the carousel for screen readers |
| `visibleItems` | number |  |  |
| `showArrows` | boolean | `true` | Default true |
| `previousLabel` | string | `"Previous"` | Default "Previous" |
| `nextLabel` | string | `"Next"` | Default "Next" |
| `snap` | enum(none \| proximity \| mandatory) |  |  |
| `snapAlign` | enum(start \| center \| end) |  |  |

- **React:** A horizontal scroller (scrollbar hidden), gap 8, scroll-snap proximity; 32px circular arrow buttons inset 4px, shown only when the scroller can move (.15s fade). `activeIndex` writable: a prop change smooth-scrolls; scrolling (debounced 120ms) writes the nearest slide. Region role + `aria-roledescription=carousel` with `label`. No autoplay; `visibleItems`, `snapAlign` unused.
- **Flutter:** Horizontal `ListView` with a snapping `ScrollPhysics` (nearest left edge), `AnimatedOpacity` arrows, `NotificationListener<ScrollEndNotification>` to write `activeIndex`, `Semantics(label)`.
- **Packages:** SDK only

#### CarouselItem

*Standard · Layout · size S · phase 4 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A slide of a Carousel.

**Children:** `children` (ChildList) · **Events:** `onVisible` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |

- **React:** A column container with `flex: 0 0 auto`, snap-align start; sized by its content.
- **Flutter:** Intrinsic-width child of the Carousel list.
- **Packages:** SDK only

#### CarouselMediaItem

*Standard · Layout · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A Carousel slide: an image with its children (a Caption, a Text) under it. size "sm" 160px, "md" 240px (default), "lg" 320px wide. A click opens all slides full-screen, unless href or onClick is set.

**Children:** `children` (ChildList) · **Events:** `onClick`, `onVisible` · **Layout props:** all 30 except `aspectRatio` · **Required:** `url`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `url` **(required)** | string |  | Image URL |
| `children` | ChildList |  |  |
| `onClick` | Action |  | Sent when the user clicks the image. It replaces the full-screen view. |
| `description` | string |  | What the image shows, for screen readers |
| `href` | string |  | Opens this URL in a new tab |
| `lightbox` | boolean | `true` | Default true: a click opens all slides full-screen |
| `aspectRatio` | string | `"4 / 3"` | Default "4 / 3" |
| `size` | enum(sm \| md \| lg) | `"md"` | The width: "sm" 160px, "md" 240px, "lg" 320px. Default "md" |

- **React:** A column of fixed width (sm 160 / md 240 / lg 320), gap 8: lazy cover image (aspect 4/3, radius 12) then `children`. Image click: `href` → openUrl (http, https, mailto), else bound `onClick`, else a Lightbox over every media image of the same carousel (unless `lightbox:false`).
- **Flutter:** Registers its image with the enclosing Carousel scope so the lightbox can page through siblings; shared `A2uiLightbox` (PageView + InteractiveViewer).
- **Packages:** SDK only

#### Spacer

*Standard · Layout · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> Flexible empty space. You almost never need it: use the default gap.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `minSize` | number or string |  |  |

- **React:** `flex: 1`, min width and height `minSize ?? 2` steps (8px), aria-hidden.
- **Flutter:** `Expanded`-like flex child with a minimum `SizedBox`; excluded from semantics.
- **Packages:** SDK only

#### Divider

*Standard · Layout · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> A line between two groups: horizontal, or vertical with axis "vertical" in a Row.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `axis` | enum(horizontal \| vertical) | `"horizontal"` | Default "horizontal" |
| `spacing` | number or string |  |  |
| `weight` | number |  | flex-grow in a Row or Column |
| `color` | enum(default \| subtle \| strong \| info \| warning \| caution \| success \| danger \| discovery) |  |  |
| `size` | number |  |  |
| `flush` | boolean |  |  |

- **React:** An `hr`: horizontal 1px (`size`) top border in `color ?? subtle`, margin `spacing ?? 8px` above and below; vertical with `axis` vertical; `flush` → margin 0.
- **Flutter:** `Container` with a one-side border (not Material `Divider`, whose metrics differ); vertical variant needs a bounded cross axis (IntrinsicHeight in a Row).
- **Packages:** SDK only

#### Tabs

*Standard · Layout · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/layout.ts`*

> Tabs that show one panel at a time. Each tab has a title and the id of its panel component: "tabs":[{"title":"Specs","child":"specs"}].

**Children:** `tabs[].child` (ComponentId) · **Writes back:** `selectedIndex` · **Required:** `tabs`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `tabs` **(required)** | {title: string, child: ComponentId}[] |  | One entry per tab |
| `selectedIndex` | number | `0` | The open tab. Default 0. Bind it with { "@path": "/x" } to read it |
| `weight` | number |  | flex-grow in a Row or Column |

- **React:** A tablist (gap 4, bottom border, horizontal scroll) and only the selected panel mounted. Tab: padding 8×12, 2px bottom border when selected, weight 500. `selectedIndex` writable and local, clamped. Roving tabindex; arrows wrap, Home/End.
- **Flutter:** Custom tab row (not Material `TabBar`, to match metrics) + `IndexedStack`-free single panel (match React: only the selected panel is built); `Shortcuts`/`FocusTraversalGroup` for arrows.
- **Packages:** SDK only

### Standard: Text

#### Title

*Standard · Text · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> A heading in a Card or next to another component; a heading alone is markdown. Size "2xl" at most once per surface, "lg" for sections. "sm" is an h4, "md"/"lg" an h3 (default "md"), "xl" and up an h2. Bold unless strong is false.

**Typography props:** all 8 · **Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  | Heading text |
| `size` | enum(sm \| md \| lg \| xl \| 2xl \| 3xl \| 4xl \| 5xl) | `"md"` | Default "md" |
| `strong` | boolean | `true` | Default true |

- **React:** Tag by size: sm h4, md/lg h3, xl–5xl h2; no inline size: host heading CSS (h2 1.5em/600, h3 1.25em/600, h4 1em/600). `TITLE_SCALE` exists in tokens.ts but React ignores it. `strong:false` → 400.
- **Flutter:** `Text` with the heading style for its tag level (matching React, not `TITLE_SCALE`); typography props shared with Text; `Semantics(header: true)`.
- **Packages:** SDK only

#### Text

*Standard · Text · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> Body text in a Card or next to another component; a paragraph alone is markdown outside the fence. Color "default" or "secondary". `text` takes inline markdown (**bold**, *italic*, ~~strike~~, ++underline++, `code`, [link](url)). `children` ids render inline after it, e.g. a Badge.

**Children:** `children` (ChildList) · **Typography props:** all 8

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string or number |  | Text with inline markdown. A bound number shows as text |
| `children` | ChildList |  |  |
| `weight` | number |  | flex-grow in a Row or Column |
| `size` | enum(3xs \| 2xs \| xs \| sm \| md \| lg) | `"md"` | Default "md" |
| `fontSize` | number or string |  | Pixels when a number. Wins over size |
| `lineHeight` | number or string |  | A unitless ratio, or CSS |
| `minLines` | number |  | Reserves the height of this many lines |
| `strong` | boolean | `false` | Default false |
| `underline` | boolean |  |  |
| `lineThrough` | boolean |  |  |
| `inline` | boolean |  |  |
| `preserveWhitespace` | boolean |  |  |
| `highlight` | enum(green \| orange \| pink) or boolean |  |  |

- **React:** A block `span` (inline with `inline`), `flex: weight 1 auto`, min-width 0. `size` → text scale (no size inherits), `fontSize` px wins, `lineHeight`, `minLines` → min-height n×1.5em, `strong` 600, decorations, `preserveWhitespace`, `highlight` (green/orange/pink). `text` is rendered with inline markdown; `children` render inline after the text.
- **Flutter:** `Text.rich` from the foundation's inline-markdown parser (port of `renderInlineMarkdown`); inline children via `WidgetSpan`; links as `TextSpan` recognizers + `Semantics(link: true)`.
- **Packages:** SDK only

#### Caption

*Standard · Text · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> Small secondary text: a hint under a control, or a label in a Row. `text` can have inline markdown.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string or number |  | Caption text |
| `color` | string |  | One of default\|prose\|primary\|emphasis\|secondary\|tertiary\|success\|info\|warning\|caution\|danger\|discovery or a CSS color |
| `size` | enum(sm \| md \| lg) | `"lg"` | Default "lg" |
| `fontWeight` | enum(normal \| medium \| semibold \| bold) | `"normal"` | Default "normal" |
| `textAlign` | enum(start \| center \| end) |  |  |
| `truncate` | boolean |  |  |
| `maxLines` | number |  |  |

- **React:** Block span; sm .75em / md .8125em / lg .875em (default lg); secondary colour; inline markdown.
- **Flutter:** Same text pipeline as Text.
- **Packages:** SDK only

#### Label

*Standard · Text · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> The label of a form field.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string or number |  | Label text |
| `htmlFor` | string |  |  |
| `color` | string |  | One of default\|prose\|primary\|emphasis\|secondary\|tertiary\|success\|info\|warning\|caution\|danger\|discovery or a CSS color |
| `size` | enum(3xs \| 2xs \| xs \| sm \| md \| lg) | `"sm"` | Default "sm" |
| `fontWeight` | enum(normal \| medium \| semibold \| bold) | `"medium"` | Default "medium" |
| `textAlign` | enum(start \| center \| end) |  |  |
| `truncate` | boolean |  |  |
| `width` | number or string |  |  |

- **React:** A `<label htmlFor>`: sm text, secondary, weight 500. `htmlFor` cannot reach standard inputs (generated ids).
- **Flutter:** `Text`; `htmlFor` is accepted and ignored (documented), as in React in practice.
- **Packages:** SDK only

#### Bold

*Standard · Text · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> Bold inline text.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  |  |
| `fontWeight` | enum(normal \| medium \| semibold \| bold) |  |  |

- **React:** `strong` around raw text (no markdown); takes `fontWeight`.
- **Flutter:** `Text` with weight.
- **Packages:** SDK only

#### Italic

*Standard · Text · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> Italic inline text.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  |  |

- **React:** `em` around raw text.
- **Flutter:** `Text` italic.
- **Packages:** SDK only

#### Underline

*Standard · Text · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> Underlined inline text.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  |  |

- **React:** `u` around raw text.
- **Flutter:** `Text` underlined.
- **Packages:** SDK only

#### Strikethrough

*Standard · Text · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> Struck-through inline text.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  |  |

- **React:** `s` around raw text.
- **Flutter:** `Text` with line-through.
- **Packages:** SDK only

#### Badge

*Standard · Text · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> A small status pill. Use the colors success, danger and warning only to show a status, not for decoration.

**Required:** `label`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` **(required)** | string |  | Badge text |
| `variant` | enum(soft \| solid \| outline) | `"soft"` | Default "soft" |
| `color` | enum(secondary \| success \| danger \| warning \| info \| discovery) | `"secondary"` | Default "secondary" |
| `size` | enum(sm \| md \| lg) | `"md"` | Default "md" |
| `pill` | boolean | `true` | Default true |
| `fontWeight` | enum(normal \| medium \| semibold \| bold) | `"medium"` | Default "medium" |
| `maxWidth` | number or string |  |  |
| `padding` | number or string |  |  |

- **React:** Inline-flex pill (radius full; `pill:false` 6px), sizes sm 18px / md 20px / lg 24px min-height, letter-spacing .3px, weight 500. soft (tint bg + colour text; secondary = rgba(0,0,0,.05)), solid (`<color>-solid` bg, on-accent text), outline (1px border).
- **Flutter:** `DecoratedBox` + `Text`; colour from the token resolver.
- **Packages:** SDK only

#### Blockquote

*Standard · Text · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> A block quotation with a line on the left. `text` can have inline markdown.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  | The quoted text, with inline markdown |

- **React:** 3px strong left border, padding-left 12, secondary colour, inline markdown.
- **Flutter:** `DecoratedBox` + inline-markdown text.
- **Packages:** SDK only

#### Code

*Standard · Text · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> A block of code in a monospace font.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  | Source code |
| `language` | string |  |  |

- **React:** A focusable `pre`: padding 12, radius 8, surface-secondary, horizontal scroll, .8125em; `language` only as `data-language`, no highlighting.
- **Flutter:** `SingleChildScrollView(horizontal)` + monospace `SelectableText`.
- **Packages:** SDK only

#### Markdown

*Standard · Text · size L · phase 1 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> A block of GitHub-flavored markdown. Use it only next to other components, for example in a table cell or next to a chart. Markdown alone goes outside the fence.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  | Markdown source |
| `streaming` | boolean | `false` | Default false |

- **React:** Streamdown (^1.3; GFM tables/strikethrough/task lists/autolinks, remark-math + KaTeX, shiki code highlighting, mermaid, rehype sanitize/harden, `remend` repair of incomplete markdown while `streaming`). Host prose margins kept here only; first/last child lose margins.
- **Flutter:** `flutter_markdown_plus` with the `markdown` package's GitHub-flavoured extension set; custom inline/block math syntaxes rendered by `flutter_math_fork`; code fences through the shared highlighter (sugar-high port, pluggable); a small `repairIncompleteMarkdown()` pre-pass for `streaming` (close `**`, `` ` ``, fences, `$$`). Mermaid fences render as code (documented gap). Links through `safeHref`.
- **Packages:** flutter_markdown_plus, markdown, flutter_math_fork, url_launcher

#### Math

*Standard · Text · size M · phase 6 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> A TeX math formula, typeset with KaTeX. Set block to true for a centered formula on its own line.

**Required:** `value`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` **(required)** | string |  | TeX source |
| `block` | boolean | `false` | Default false |

- **React:** `katex.renderToString(value, {displayMode: block, throwOnError: false, trust: false})`; block → centred div; invalid TeX → red source text.
- **Flutter:** `Math.tex(value, mathStyle: block ? display : text, onErrorFallback: red source)`.
- **Packages:** flutter_math_fork

#### ShimmerText

*Standard · Text · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> Text with a moving shimmer. It shows that something is loading or pending.

**Typography props:** all 8 · **Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  |  |
| `size` | enum(3xs \| 2xs \| xs \| sm \| md \| lg) | `"md"` | Default "md" |
| `lineThrough` | boolean |  |  |

- **React:** Gradient-clipped text: base colour 0–40%, highlight `var(--a2ui-color-shimmer, #d9d9d9)` at 50%, base 60–100%; background-size 200%, 1.5s linear infinite; reduced motion → static.
- **Flutter:** `ShaderMask` with an animated `LinearGradient`; honours `MediaQuery.disableAnimations`.
- **Packages:** SDK only

#### Link

*Standard · Text · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> A link. Only http, https and mailto URLs work. It opens in a new tab.

**Required:** `href`, `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  | Link text |
| `href` **(required)** | string |  | URL |
| `title` | string |  |  |

- **React:** `safeHref` (trimmed; http, https, mailto only), else a plain span. Text `text || href`, info colour, new tab, visually hidden " (opens in a new tab)".
- **Flutter:** Tappable text (`GestureDetector`/`Link` widget from url_launcher) + `Semantics(link: true, hint: 'opens in a new tab')`; launch with `LaunchMode.externalApplication`.
- **Packages:** url_launcher

#### Tooltip

*Standard · Text · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/text.ts`*

> Shows `content` when the user points at or focuses `trigger`. `trigger`: one child id, a Text, Icon or Badge (not a Button or Link). `content`: one child id of short text, no links or buttons.

**Children:** `trigger` (ComponentId), `content` (ComponentId)

| Prop | Type | Default | Notes |
|---|---|---|---|
| `trigger` | ComponentId |  |  |
| `content` | ComponentId |  |  |

- **React:** Slots `trigger` and `content`. Tip above, centred, 6px hover bridge, z 10; panel max-width 240, padding 4×8, radius 6, inverted surface, xs text. Opens on hover or focus, closes on leave/blur/Escape; no delay.
- **Flutter:** `OverlayPortal` anchored with `CompositedTransformFollower` (not Material `Tooltip`, which takes text only); long-press opens on touch.
- **Packages:** SDK only

### Standard: Inputs

#### Button

*Standard · Inputs · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> Sends its onClick event; with href it opens the URL, with copy it copies the text. Variant "primary" for the one main Button in a Row. submit true submits the Form around it. Its children render instead of the label. With checks it is disabled while a check fails.

**Children:** `child` (ComponentId), `children` (ChildList) · **Events:** `onClick` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The button text |
| `onClick` | Action |  | Sent when the user clicks the button. |
| `text` | string |  | Same as label. Used when label is not set |
| `variant` | enum(default \| primary \| soft \| borderless) | `"default"` | Default "default": outlined. "primary" is filled, for the one main action. "borderless" has no box, like a link |
| `block` | boolean |  | Full width |
| `disabled` | boolean |  |  |
| `loading` | boolean |  |  |
| `submit` | boolean |  | Submits the Form around it. The Form sends its onSubmit event |
| `icon` | string |  | Lucide icon name |
| `uniform` | boolean |  | A square button, for an icon |
| `href` | string |  | Opens this URL in a new tab on click, instead of onClick |
| `copy` | string |  | Copies this text to the clipboard on click and shows a check mark, instead of onClick |
| `child` | ComponentId |  |  |
| `children` | ChildList |  |  |
| `color` | enum(primary \| secondary \| danger) | `"primary"` | Default "primary" |
| `size` | enum(sm \| md \| lg) | `"lg"` | Default "lg" |
| `weight` | number |  | flex-grow in a Row or Column |
| `pill` | boolean | `true` | Default true |

- **React:** Inline-flex button (block → full width), gap 6, weight 500; size default lg (min-height 28/32/36, padding padX+4); `uniform` → square. Variants primary/soft/default/borderless (+ danger). Lucide `icon` first; content = `child`, else `children`, else `label ?? text`. Disabled when `disabled`, `loading` (aria-busy only, no spinner) or the first failed check is an error; `title` shows the first failed check. Click order: form `submit` → `href` → `copy` (check icon 1500ms) → `onClick({})`.
- **Flutter:** Custom pressable (`FocusableActionDetector` + `InkWell`-free `GestureDetector`, to match the flat look) with the same click order; Form submit through the `A2uiFormScope`; clipboard via `Clipboard.setData`.
- **Packages:** url_launcher

#### Pressable

*Standard · Inputs · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A layout container that the user can click or press with Enter or Space. It sends its onClick event, or opens href. A control inside it sends only its own event.

**Children:** `children` (ChildList) · **Events:** `onClick`, `onVisible` · **Layout props:** all 30

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `onClick` | Action |  | Sent when the user clicks or presses the container. |
| `href` | string |  | Opens this URL in a new tab on click, instead of onClick |
| `disabled` | boolean |  |  |
| `tooltip` | string |  | Shown on hover |
| `ariaPressed` | boolean |  | For a toggle |
| `hoverBackground` | string |  |  |
| `insetBorder` | boolean |  | A 1px border inside the box |

- **React:** A `div role=button` (can contain controls), column layout, no default gap; Enter/Space when it is the target; `href` → openUrl else `onClick`; `hoverBackground`, `insetBorder`, `tooltip` → title, `ariaPressed`; `onVisible` wired.
- **Flutter:** `A2uiFlexBox` inside `FocusableActionDetector` + `MouseRegion`; inner controls win the gesture arena.
- **Packages:** url_launcher

#### Form

*Standard · Inputs · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A layout container that is a form. It sends onSubmit when the user submits (a Button with submit true, or Enter in a field). Put its field values in the event context with { "@path": "/x" }.

**Children:** `children` (ChildList) · **Events:** `onSubmit` · **Layout props:** all 30 except `onVisible`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `onSubmit` | Action |  | Sent when the user submits the form. |
| `label` | string |  | A short name of the form for screen readers |

- **React:** A `<form>`, column, gap `gap ?? 16`. Native submit → preventDefault → `onSubmit({})`. Native constraint validation first (required, email/url types, date min/max, custom validity of DateTimeInput and ChoicePicker). `checks` never block a Form. Enter in a field submits.
- **Flutter:** `A2uiFormScope` (inherited) that fields register with: `required`/type validators and the custom-validity hooks run before `onSubmit`; `TextField.onSubmitted` triggers submit.
- **Packages:** SDK only

#### TextField

*Standard · Inputs · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A text input, single-line unless variant is "longText". Bind value with { "@path": "/x" } to read what the user typed. Give it a label.

**Writes back:** `value` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The visible label of the field. Always set it |
| `value` | string or number |  | Bind it with { "@path": "/x" } to read what the user typed |
| `placeholder` | string |  |  |
| `variant` | enum(shortText \| longText \| number \| obscured \| email \| url \| tel) | `"shortText"` | Default "shortText". "longText" is a multi-line field, "obscured" a password |
| `name` | string |  |  |
| `required` | boolean |  |  |
| `disabled` | boolean |  |  |
| `invalid` | boolean |  |  |
| `autoSelect` | boolean |  |  |
| `mask` | string |  |  |
| `weight` | number |  | flex-grow in a Row or Column |
| `size` | enum(sm \| md \| lg \| xl) | `"xl"` | Default "xl" |
| `pill` | boolean | `true` | Default true |

- **React:** An `input`; type from `variant` (shortText/number/obscured/email/url/tel; `longText` renders a TextArea). Default size xl (40px), pill. `aria-label` = placeholder when no label. `autoSelect`. Writes `value` as a string (also for numbers). `mask` unused. Checks: message after first blur or when non-empty.
- **Flutter:** `TextField` with a custom `InputDecoration` matching control metrics; keyboard types per variant; `obscureText`; writes through `props.writable('value')`; check display via the shared `A2uiCheckMessage`.
- **Packages:** SDK only

#### TextArea

*Standard · Inputs · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A multi-line text input. Bind value with { "@path": "/x" } to read what the user typed. Give it a label.

**Writes back:** `value` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The visible label of the field. Always set it |
| `value` | string |  | Bind it with { "@path": "/x" } to read what the user entered |
| `placeholder` | string |  |  |
| `rows` | number | `3` | Default 3 |
| `maxRows` | number |  |  |
| `autoResize` | boolean |  |  |
| `name` | string |  |  |
| `required` | boolean |  |  |
| `disabled` | boolean |  |  |
| `invalid` | boolean |  |  |
| `weight` | number |  | flex-grow in a Row or Column |
| `size` | enum(sm \| md \| lg \| xl) | `"xl"` | Default "xl" |

- **React:** `textarea`, rows 3, padding (padX/2)×padX, radius 8, line-height 1.5; resize vertical or `autoResize`; `maxRows`. Writes a string.
- **Flutter:** Multiline `TextField` (`minLines`/`maxLines`).
- **Packages:** SDK only

#### Select

*Standard · Inputs · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A dropdown list of options. Bind value with { "@path": "/x" } to read the chosen option. Give it a label.

**Writes back:** `value` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The visible label of the field. Always set it |
| `options` | (string or {value: string, label?: string, description?: string})[] |  |  |
| `value` | string |  | Bind it with { "@path": "/x" } to read what the user entered |
| `placeholder` | string |  |  |
| `name` | string |  |  |
| `required` | boolean |  |  |
| `disabled` | boolean |  |  |
| `clearable` | boolean |  |  |
| `clearLabel` | string |  | The label of the empty option |
| `searchable` | boolean |  |  |
| `icon` | string |  | Lucide icon shown before the value |
| `block` | boolean |  | Full width |
| `size` | enum(sm \| md \| lg \| xl) | `"xl"` | Default "xl" |
| `pill` | boolean | `true` | Default true |

- **React:** A native `select`, chevron 12px at right; empty option when `placeholder`/`clearable`/empty value; option `description` → title; leading 16px icon. Writes a string. `searchable`, `weight` unused.
- **Flutter:** `DropdownMenu`/`MenuAnchor` styled as the control; clear item; option tooltips.
- **Packages:** SDK only

#### CheckBox

*Standard · Inputs · size S · phase 1 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A checkbox with a label. Bind value with { "@path": "/x" } to read its state, true or false.

**Writes back:** `value` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The label text. Always set it |
| `value` | boolean |  | True when checked. Bind it with { "@path": "/x" } to read the state of the box |
| `name` | string |  |  |
| `disabled` | boolean |  |  |
| `required` | boolean |  |  |
| `shape` | enum(round \| square) | `"round"` | Default "round" |
| `weight` | number |  | flex-grow in a Row or Column |
| `lineThrough` | boolean | `false` | Default false. Strikes the label when the box is checked |

- **React:** Custom 20px box (round by default, square 6px), accent fill + white check; `lineThrough` strikes the label when checked. Writes a bool.
- **Flutter:** Custom painted box in a `Semantics(checked:)` row (Material `Checkbox` is square only).
- **Packages:** SDK only

#### Radio

*Standard · Inputs · size S · phase 4 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> One radio button. Use RadioGroup instead, because it keeps the chosen value.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  |  |
| `value` | string |  |  |
| `disabled` | boolean |  |  |
| `required` | boolean |  |  |

- **React:** A single uncontrolled radio with no name: practically inert alone.
- **Flutter:** Render a disabled-looking radio row; documented as inert, as in React.
- **Packages:** SDK only

#### RadioGroup

*Standard · Inputs · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A group of radio buttons. The user chooses one option. Bind value with { "@path": "/x" } to read it. Give it a label.

**Writes back:** `value` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The visible label of the field. Always set it |
| `options` | (string or {value: string, label?: string, description?: string})[] |  |  |
| `value` | string |  | Bind it with { "@path": "/x" } to read what the user entered |
| `name` | string |  |  |
| `direction` | enum(row \| col) | `"row"` | Default "row" |
| `variant` | enum(list \| pills \| cards) |  |  |
| `disabled` | boolean |  |  |
| `required` | boolean |  |  |

- **React:** A `fieldset` + `legend`, native radios (arrow keys), direction row (wraps) or col; variants list / pills / cards (accent border when selected). Writes the option value.
- **Flutter:** Custom group with `RadioGroup`-style roving focus (`FocusTraversalGroup` + arrow `Shortcuts`), three variants.
- **Packages:** SDK only

#### Slider

*Standard · Inputs · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A range slider for a number between min and max. Bind value with { "@path": "/x" } to read the number. Give it a label.

**Writes back:** `value` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The visible label of the field. Always set it |
| `value` | number |  | Bind it with { "@path": "/x" } to read the number |
| `min` | number | `0` | Default 0 |
| `max` | number | `100` | Default 100 |
| `step` | number | `1` | Default 1 |
| `steps` | integer |  | The number of equal divisions between min and max, instead of step |
| `unit` | string |  | Unit after the value, for example "%" |
| `marks` | {value: number, label?: string}[] |  |  |
| `sliderStyle` | enum(continuous \| discrete) | `"continuous"` | Default "continuous" |
| `disabled` | boolean |  |  |
| `name` | string |  |  |
| `weight` | number |  | flex-grow in a Row or Column |

- **React:** Header (label left; value + unit right when label or unit set), 24px native range: pill track rgba(0,0,0,.04), no fill, 20px thumb; `step = (max−min)/steps` or `step ?? 1`; marks row (+ datalist for `sliderStyle: discrete`). Writes a number.
- **Flutter:** Material `Slider` with a custom `SliderThemeData` (no active fill, flat thumb) and a marks row.
- **Packages:** SDK only

#### SegmentedControl

*Standard · Inputs · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A row of segments. The user chooses one option. Use it for 2 to 5 short options. Bind value with { "@path": "/x" } to read it.

**Writes back:** `value` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The visible label of the field. Always set it |
| `options` | (string or {value: string, label?: string, description?: string})[] |  |  |
| `value` | string |  | Bind it with { "@path": "/x" } to read what the user entered |
| `block` | boolean |  | Full width |
| `variant` | enum(solid \| soft \| outline \| ghost) | `"ghost"` | Default "ghost" |
| `disabled` | boolean |  |  |
| `size` | enum(sm \| md \| lg \| xl) | `"lg"` | Default "lg" |
| `pill` | boolean | `true` | Default true |

- **React:** `role=radiogroup` track (surface-secondary, padding 2, gap 2), segments `role=radio`; solid → accent fill; others → surface + xs shadow; roving tabindex with arrows/Home/End. Writes the value.
- **Flutter:** Custom segmented row (Material `SegmentedButton` differs in look).
- **Packages:** SDK only

#### ChoicePicker

*Standard · Inputs · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> Options as checkboxes or chips: pick one, or several with variant "multipleSelection". Its value is the list of chosen values. Give it a label.

**Writes back:** `value` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The visible label of the field. Always set it |
| `options` | (string or {value: string, label?: string, description?: string})[] |  |  |
| `value` | string[] |  | The chosen option values. Bind it with { "@path": "/x" } to a string list |
| `variant` | enum(multipleSelection \| mutuallyExclusive) | `"mutuallyExclusive"` | Default "mutuallyExclusive": the user picks one option |
| `displayStyle` | enum(checkbox \| chips) | `"checkbox"` | Default "checkbox". "chips" shows the options as pills |
| `filterable` | boolean | `false` | Default false. Shows a field that filters the options |
| `disabled` | boolean |  |  |
| `required` | boolean |  |  |
| `weight` | number |  | flex-grow in a Row or Column |

- **React:** `value` is a string list. mutuallyExclusive (radios; clicking the selected clears to []), multipleSelection (checkboxes), `displayStyle: chips` (toggle pills); `filterable` search box ("Filter…"); `required` blocks Form submit.
- **Flutter:** Radios/checkboxes/chips over the same option model; filter `TextField`; registers a required validator with `A2uiFormScope`.
- **Packages:** SDK only

#### DateTimeInput

*Standard · Inputs · size L · phase 4 · definition `packages/shared/src/generative-ui/standard/inputs.ts`*

> A date picker, a time picker with enableTime, or both. timeStep (minutes) offers fixed times, e.g. 30 for a booking. The value is ISO 8601. Give it a label.

**Writes back:** `value` · **`checks`:** yes

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | The visible label of the field. Always set it |
| `value` | string |  | ISO 8601: "YYYY-MM-DD", "HH:MM" or "YYYY-MM-DDTHH:MM". Bind it with { "@path": "/x" } |
| `enableDate` | boolean | `true` | The user picks a date. Default true unless only enableTime is set |
| `enableTime` | boolean |  | The user picks a time |
| `timeStep` | integer |  | Minutes between the times the user can pick, e.g. 15 or 30. Shows the time as a list |
| `min` | string |  | The earliest value, ISO 8601 |
| `max` | string |  | The latest value, ISO 8601 |
| `placeholder` | string |  |  |
| `disabled` | boolean |  |  |
| `required` | boolean |  |  |
| `clearable` | boolean |  |  |
| `block` | boolean |  | Full width |
| `weight` | number |  | flex-grow in a Row or Column |

- **React:** date / time / datetime modes; separate fields; `timeStep` → select of slots (wraps midnight). Writes "YYYY-MM-DD", "HH:MM" or "YYYY-MM-DDTHH:MM" ("" until both parts set). min/max ISO; errors "Pick a time from X to Y", "Pick a date too"/"Pick a time too" block submit. Summary line in the user's locale (formatted in UTC!). `clearable`.
- **Flutter:** Two field buttons opening `showDatePicker`/`showTimePicker` (or a slot menu with `timeStep`); same wire formats; validators registered with the form scope; summary through `intl` `DateFormat` (keep React's UTC quirk, documented).
- **Packages:** intl

### Standard: Feedback

#### PulseIndicator

*Standard · Feedback · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/feedback.ts`*

> A small dot that pulses, for example next to the text "Live". Set label when no text next to the dot says what it means.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  | What the dot means, for screen readers. Leave it unset when text next to the dot says the same |
| `pulseColor` | string |  |  |
| `duration` | number | `1500` | Milliseconds. Default 1500 |
| `endScale` | number | `2.4` | Default 2.4 |
| `startOpacity` | number | `0.6` | Default 0.6 |
| `color` | string | `"success"` | Text color token. Default "success" |
| `size` | number | `12` | Pixels. Default 12 |

- **React:** A `size`px dot (12) with a ring scaling 1→`endScale` (2.4) while fading `startOpacity` (.6)→0 over `duration` (1500ms) ease-out, infinite; colour default success; `label` → role img.
- **Flutter:** `AnimatedBuilder` + `Transform.scale`; reduced motion → fade only.
- **Packages:** SDK only

#### FlashcardFlip

*Standard · Feedback · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/feedback.ts`*

> A card that shows the front text. A click or the Enter key flips it to the back text, and again to the front.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `front` | string |  | The text on the front |
| `back` | string |  | The text on the back |
| `hint` | string |  | A small line under the front, for example "Click to flip" |

- **React:** A toggle button (aria-pressed), min-height 140, padding 20, radius 16; front/back text swap (no flip animation); `hint` on the front only; local state.
- **Flutter:** Stateful toggle with `Semantics(toggled:)`.
- **Packages:** SDK only

#### Popover

*Standard · Feedback · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/feedback.ts`*

> A small overlay: exactly two children, one PopoverTrigger then one PopoverContent. A click on the trigger toggles it; Escape or a click outside closes it.

**Children:** `children` (ChildList) · **Writes back:** `open`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `open` | boolean | `false` | Default false |
| `showOnHover` | boolean |  |  |
| `hoverOpenDelay` | number | `0` | Milliseconds before a hover opens it. Default 0 |

- **React:** Relative wrapper; `open` writable (defaults false); closes on outside pointerdown, Escape refocuses the trigger; `showOnHover` (+`hoverOpenDelay`). Content is not portaled (can be clipped).
- **Flutter:** `OverlayPortal` + `TapRegion` for outside taps (portaled in Flutter, so it is never clipped: an intentional improvement, documented).
- **Packages:** SDK only

#### PopoverTrigger

*Standard · Feedback · size S · phase 4 · definition `packages/shared/src/generative-ui/standard/feedback.ts`*

> The trigger of a Popover. Its children are the label of the trigger: a Text or an Icon. Do not put a Button in it, because the trigger is already a button.

**Children:** `children` (ChildList)

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `block` | boolean |  | Full width |

- **React:** Reset button with aria-haspopup/expanded/controls; toggles in the click capture phase (a Button inside still toggles it). Outside a Popover: just its children.
- **Flutter:** `Listener(onPointerUp)` so inner buttons still fire; reads `PopoverScope`.
- **Packages:** SDK only

#### PopoverContent

*Standard · Feedback · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/feedback.ts`*

> The body of a Popover. It shows only when the Popover is open.

**Children:** `children` (ChildList)

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `side` | enum(top \| bottom \| left \| right) | `"bottom"` | Default "bottom" |
| `sideOffset` | number | `6` | Pixels between the trigger and the content. Default 6 |
| `align` | enum(start \| center \| end) | `"center"` | Default "center" |
| `width` | number or string |  | 4px steps when a number |

- **React:** role dialog; `side` bottom/top/left/right with `sideOffset` 6; `align` center/start/end; panel min-width 160, padding 12, radius 12, elevated surface, shadow md; `width` in 4px steps. Outside a Popover: a static panel.
- **Flutter:** Positioned with `CompositedTransformFollower` anchors per side/align.
- **Packages:** SDK only

#### Modal

*Standard · Feedback · size L · phase 4 · definition `packages/shared/src/generative-ui/standard/feedback.ts`*

> A dialog over the page. A click on the trigger (a Button or a Text) opens the content in the dialog. Escape, the close button or a click on the backdrop closes it.

**Children:** `trigger` (ComponentId), `content` (ComponentId) · **Writes back:** `open`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `trigger` | ComponentId |  |  |
| `content` | ComponentId |  |  |
| `title` | string |  | The heading of the dialog |
| `open` | boolean | `false` | Default false. Bind it with { "@path": "/x" } to read it |
| `maxWidth` | number or string | `480` | Default 480 |
| `weight` | number |  | flex-grow in a Row or Column |

- **React:** Slots trigger/content. Trigger wrapper gets role button only when it holds no control (MutationObserver); opens in click capture. `open` writable. Dialog portaled to body inside a themed `.a2ui-surface`; backdrop rgba(0,0,0,.8) closes; box padding 20, radius 16, max-height 90vh, title h2 + 32px ×. Focus trap and restore; Escape via the overlay stack. Pitfall: default `maxWidth` 480 means 480×4px.
- **Flutter:** `showDialog`-free `OverlayPortal` (so the theme scope is inherited) with `FocusScope` trap, `Shortcuts(Escape)`; reproduce the 480-step width quirk or clamp (decide in review; prefer matching React).
- **Packages:** SDK only

### Standard: Data

#### Table

*Standard · Data · size L · phase 6 · definition `packages/shared/src/generative-ui/standard/data.ts`*

> A data table, in a plain Column, not a Card. Give "columns" and "rows", or "children": TableSection or TableRow ids, or a template { "componentId", "path" } repeating a TableRow per item. A component in a cell or header (Badge, Button, Icon, Text): { "componentId": "<id>" }, with the id in "cellComponents".

**Children:** `children` (ChildList), `cellComponents` (ChildList)

| Prop | Type | Default | Notes |
|---|---|---|---|
| `columns` | (string or {label: string, align?: enum(start \| center \| end), width?: number or string, componentId?: string} or {componentId: string} or {id: string})[] | `[]` | Default [] |
| `rows` | any[][] | `[]` | A list of row lists. A cell is a string, a number, or { "componentId": "<id>" } to show a component. Default [] |
| `children` | ChildList |  |  |
| `caption` | string |  | A short name of the table for screen readers. It is not shown |
| `columnSizing` | enum(auto \| equal) | `"auto"` | Default "auto" |
| `dividers` | boolean | `true` | Default true |
| `stickyHeader` | boolean | `false` | Default false |
| `emptyLabel` | string | `"No rows"` | Default "No rows" |
| `cellComponents` | ChildList |  |  |

- **React:** Wrapper with horizontal scroll; `columns` (string, {label, align, width, componentId}, {componentId|id}); `rows` of cells (string/number/JSON or {componentId}/{id} from `cellComponents`). Header th, cells 14px, padding 8 (0 at outer edges), top-aligned; `dividers`; `columnSizing: equal` → fixed layout; `stickyHeader` → max-height 480 + sticky th; empty → `emptyLabel`. Children mode: TableSection/TableRow children.
- **Flutter:** Custom table layout (`Table` widget with `IntrinsicColumnWidth`/`FlexColumnWidth`) inside a horizontal scroller; cell components resolved by id from the `cellComponents` child list; sticky header via a `CustomScrollView` with a pinned header.
- **Packages:** SDK only

#### TableSection

*Standard · Data · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/data.ts`*

> A group of TableRow children in a Table. With header true, it is the header of the table.

**Children:** `children` (ChildList)

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `header` | boolean |  | Renders the rows as the header |
| `rowDivider` | boolean |  |  |

- **React:** `thead` when `header`, else `tbody`; `rowDivider`.
- **Flutter:** Contributes rows to the parent table builder (scope-based).
- **Packages:** SDK only

#### TableRow

*Standard · Data · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/data.ts`*

> A row of a Table. Its children are TableCell ids, or a template. With label, a header cell with that text starts the row.

**Children:** `children` (ChildList)

| Prop | Type | Default | Notes |
|---|---|---|---|
| `children` | ChildList |  |  |
| `label` | string |  | The text of a header cell at the start of the row |
| `header` | boolean |  |  |
| `labelColSpan` | number |  | Columns the label cell spans |

- **React:** A `tr`; `label` adds a leading row header with `labelColSpan`.
- **Flutter:** Row model consumed by the Table builder.
- **Packages:** SDK only

#### TableCell

*Standard · Data · size S · phase 6 · definition `packages/shared/src/generative-ui/standard/data.ts`*

> A cell of a TableRow. It shows "text", or its children. With header true, it is a header cell.

**Children:** `children` (ChildList)

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` | string or number |  |  |
| `children` | ChildList |  |  |
| `header` | boolean |  |  |
| `vAlign` | enum(start \| center \| end) | `"start"` | Default "start" |
| `colSpan` | number |  |  |
| `rowSpan` | number |  |  |
| `align` | enum(start \| center \| end) |  |  |
| `width` | number or string |  |  |
| `padding` | number or string |  |  |

- **React:** `th`/`td`; `text` then `children`; colSpan, rowSpan, align, vAlign, width and padding in 4px steps.
- **Flutter:** Cell model; colSpan supported by a custom table render (Flutter `Table` has no spans: plan a small custom layout).
- **Packages:** SDK only

#### List

*Standard · Data · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/data.ts`*

> A list in a Card or next to another component; a plain list of text is markdown. Give "items": an item with a value and no action is a key-value row (Price: $1,599). Or give "children": ListItem ids or a template. With "action" the user picks an item; the event context gets its index, label and value.

**Children:** `children` (ChildList) · **Events:** `action`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | (string or {label: string, description?: string, icon?: string, value?: string or number})[] |  |  |
| `children` | ChildList |  |  |
| `action` | Action |  | Runs when the user picks an item. The args are the index, label and value of the item. |
| `direction` | enum(vertical \| horizontal) | `"vertical"` | Default "vertical". "horizontal" scrolls sideways |
| `marker` | enum(bullet \| number \| rich \| none) | `"bullet"` | Default "bullet" |
| `connector` | enum(none \| solid) | `"none"` | Default "none" |
| `start` | number |  | The first number of marker "number" |
| `maxMarkerSize` | number |  | The width of the marker column in pixels |
| `align` | enum(start \| center \| end \| stretch) |  |  |
| `weight` | number |  | flex-grow in a Row or Column |
| `gap` | number or string |  |  |

- **React:** `ul`/`ol` (number marker, `start`); markers bullet/number/rich/none; horizontal mode; gap `gap ?? (horizontal ? 12 : 4)`px. `items` mode: icon + label + value (right, tabular) + description; `connector: solid`. With `action`, items are buttons calling `action({index, label, value})`. Otherwise ListItem children.
- **Flutter:** `Column`/`Row` of items with marker painters; numbered markers via `intl`-free counters; `Semantics` list roles.
- **Packages:** SDK only

#### ListItem

*Standard · Data · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/data.ts`*

> An item of a List, with a label, a value on the right, a description, an icon and children. With an "action", the user can pick it.

**Children:** `children` (ChildList) · **Events:** `action`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  |  |
| `value` | string or number |  | Without an action: shown on the right of the label, for a key and value fact |
| `action` | Action |  | Runs when the user picks the item. |
| `children` | ChildList |  |  |
| `description` | string |  |  |
| `icon` | string |  | Lucide icon name |
| `marker` | string |  | Shows this text as the marker |
| `markerSize` | number |  | The width of the marker column in pixels |
| `disabled` | boolean |  | Greys the item out and ignores its action |

- **React:** `li` (or div outside a List); same body + children; text `marker` replaces the bullet; `disabled` (opacity .5); `action({})` makes it a button.
- **Flutter:** Shares the List item widget.
- **Packages:** SDK only

#### Chart

*Standard · Data · size L · phase 2 · definition `packages/shared/src/generative-ui/standard/data.ts`*

> A bar, line, area, scatter, pie or donut chart. "data" is a list of objects. "xKey" is the field of the category. "series" are the value fields.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `data` | object[] |  |  |
| `xKey` | string |  | The field of the category axis |
| `series` | (string or {key: string, label?: string, color?: string})[] |  | Default: every number field except xKey |
| `chartType` | enum(bar \| line \| area \| scatter \| pie \| donut) | `"bar"` | Default "bar" |
| `stacked` | boolean |  |  |
| `layout` | enum(vertical \| horizontal) | `"vertical"` | "horizontal" draws the bars from left to right. Default "vertical" |
| `yAxis` | {label?: string, min?: number, max?: number, width?: number} |  | Example: {label: "Revenue (USD)", min: 0, max: 100}. In a horizontal chart it is the horizontal axis, and width sets the category axis width |
| `showDots` | boolean |  | Point markers on a line or area |
| `barRadius` | number |  | The corner radius of a bar, in pixels |
| `innerRadius` | number or string |  | Pie and donut |
| `outerRadius` | number or string |  | Pie and donut |
| `startAngle` | number | `90` | Pie and donut. Default 90 |
| `endAngle` | number | `-270` | Pie and donut. Default -270 |
| `cornerRadius` | number |  | The corners of a slice |
| `paddingAngle` | number |  | The gap between slices |
| `showLabelLines` | boolean | `true` | Leader lines of the slice labels. Default true |
| `showLegend` | boolean | `true` | Default true |
| `showGrid` | boolean | `true` | Default true |
| `showTooltip` | boolean | `true` | Default true |
| `showValueLabels` | boolean |  |  |
| `format` | enum(number \| currency \| percent) |  | With "percent", data values and axis min/max are fractions: 0.4 shows as 40%; for 0% to 10%, use min: 0 and max: 0.1. |
| `currency` | string | `"USD"` | ISO code. Default "USD" |
| `title` | string |  |  |
| `height` | number | `240` | Pixels. Default 240 |

- **React:** recharts (lazy; data-table fallback if the import fails). figure + optional title + drawing (height 240) + hidden data table. Series = given list or every numeric field except `xKey`; palette `--a2ui-chart-1..6`. Bar radius [4,4,0,0]; line/area monotone width 2; area fill .2; pie/donut (inner 0/55%, outer 80%, 90°→−270°); `stacked`; `layout: horizontal`; legend 8px dots 13px; tooltip radius 10; dashed 3 3 grid; ticks 12px; `format` en-US, **percent values are fractions here** (0.4 = 40%), compact for |v| >= 10,000.
- **Flutter:** `fl_chart` (`BarChart`, `LineChart` with `isCurved` + `preventCurveOverShooting`, `ScatterChart`, `PieChart`); hidden data table via `Semantics`; the foundation's chart formatter. Keep the recharts look, not fl_chart defaults.
- **Packages:** fl_chart, intl

#### Map

*Standard · Data · size L · phase 3 · definition `packages/shared/src/generative-ui/standard/data.ts`*

> A map with markers; with "route" a line connects them in order. Bind "selected" to get the label of the marker the user picks. Without maps it shows a list of the places.

**Writes back:** `selected`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `markers` | {label: string, lat: number, lng: number, category?: string, icon?: string}[] |  |  |
| `selected` | string |  | The label of the selected marker. Bind it with { "@path": "/x" } to read the choice of the user |
| `route` | boolean |  | Draws a line through the markers in order |
| `zoom` | number |  | With two or more markers, only the highest zoom of the fit |
| `center` | {lat: number, lng: number} |  |  |
| `height` | number | `240` | Pixels. Default 240 |

- **React:** maplibre-gl (optional peer; list of places as fallback). Container radius 12, border; places list visually hidden while the map works. Style: theme `mapStyle` or OpenFreeMap positron / dark. Centre = `center` or first marker; zoom `zoom ?? (1 marker ? 10 : 1)`; 2+ markers → fitBounds (padding 48, maxZoom `zoom ?? 14`) until the user moves. Cooperative gestures (ctrl/⌘ + wheel). Default pins with label popups; pin click writes `selected`; `route` draws a #0285ff 3px line.
- **Flutter:** `flutter_map` with a raster tile layer from the theme (default: CARTO light_all / dark_all, the raster twins of Positron/Dark Matter; see open questions); `MarkerLayer` pins, `PolylineLayer` route, `CameraFit.bounds(padding 48)`; places list kept for semantics; scroll-wheel zoom only with ctrl/⌘ on web/desktop.
- **Packages:** flutter_map, latlong2

### Standard: Media

#### Image

*Standard · Media · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/media.ts`*

> An image from a URL. A click opens it full-screen. Set description to say what the image shows, unless it is only decoration.

**Events:** `onOverlayClick` · **Required:** `url`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `url` **(required)** | string |  | Image URL |
| `description` | string |  | What the image shows, for screen readers. Leave it unset only for a decorative image |
| `onOverlayClick` | Action |  | Sent when the user clicks the actionOverlay button and it has no href. |
| `variant` | enum(icon \| avatar \| smallFeature \| mediumFeature \| largeFeature \| header) | `"mediumFeature"` | The size: "icon" 24px, "avatar" 40px round, "smallFeature" 160px wide, "largeFeature" and "header" full width. Default "mediumFeature": the natural size |
| `fit` | enum(cover \| contain \| fill \| none \| scaleDown) | `"cover"` | CSS object-fit. Default "cover" |
| `frame` | boolean |  |  |
| `position` | string |  | CSS object-position, for example "top" or "50% 20%" |
| `hideOnFailure` | boolean | `false` | Default false |
| `fallback` | string |  | Text shown in place of the image when it does not load |
| `hoverZoom` | boolean |  | A slight zoom on hover |
| `lightbox` | boolean | `true` | Default true: a click opens the image full-screen |
| `actionOverlay` | {label: string, icon?: string, href?: string} |  | A button over the bottom-right corner of the image. Without href, it sends onOverlayClick |
| `weight` | number |  | flex-grow in a Row or Column |
| `aspectRatio` | string |  |  |
| `radius` | enum(2xs \| xs \| sm \| md \| lg \| xl \| 2xl \| 3xl \| 4xl \| full) or number or string or {topLeft?: string, topRight?: string, bottomLeft?: string, bottomRight?: string} |  |  |
| `width` | number or string |  |  |
| `height` | number or string |  |  |
| `maxWidth` | number or string |  |  |
| `maxHeight` | number or string |  |  |
| `minWidth` | number or string |  |  |
| `minHeight` | number or string |  |  |
| `background` | string |  |  |

- **React:** Lazy `img`: `fit` (cover; scaleDown), `position`, background, `frame` border, radius; variants icon 24 / avatar 40 round / smallFeature (max 160) / mediumFeature (natural) / largeFeature (100%) / header (100%, 3/1). Sizes in 4px steps. Click → Lightbox (default on). Errors: `hideOnFailure`, `fallback` text box, else broken image. `hoverZoom` 1.03; `actionOverlay` pill button (href → openUrl else `onOverlayClick`).
- **Flutter:** `Image.network` with `errorBuilder`/`frameBuilder`; shared `A2uiLightbox`; `MouseRegion` hover zoom; overlay button.
- **Packages:** url_launcher

#### Icon

*Standard · Media · size M · phase 1 · definition `packages/shared/src/generative-ui/standard/media.ts`*

> A Lucide icon by kebab-case name (for example "arrow-right"), or an A2UI icon name (for example "arrowBack"). Set label when no text next to the icon says what it means.

**Required:** `name`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` **(required)** | string or {svgPath: string} |  | A Lucide icon name in kebab-case ("arrow-right"), an A2UI icon name ("arrowBack"), or { "svgPath" } on a 24px grid |
| `label` | string |  | What the icon means, for screen readers. Leave it unset when text next to the icon says the same |
| `size` | enum(sm \| md \| lg \| xl) or number | `"md"` | Default "md" |
| `color` | string |  |  |
| `inline` | boolean | `false` | Default false |
| `strokeWeight` | enum(normal \| medium \| semibold \| bold) |  | The stroke width |
| `weight` | number |  | flex-grow in a Row or Column |

- **React:** 56 A2UI names mapped to Lucide names (arrowBack → arrow-left, close → x, warning → triangle-alert…), then kebab → PascalCase lookup in lucide's `icons` map; unknown → nothing. Size sm 16 / md 20 / lg 24 / xl 32 or px; `inline` → 1em; `strokeWeight` 2 / 2.25 / 2.5 / 3; `{svgPath}` → filled 24-grid path; `label` → role img.
- **Flutter:** lucide-react 0.525.0's node for the name (`lucideIcon(..., release: LucideRelease.reactCore, a2uiNames: true)`), stroked by `LucideGlyph` with the `strokeWeight`'s width; `svgPath` drawn with `path_parsing` (superseded the flutter_lucide font on 2026-11-21; see port note 7).
- **Packages:** path_parsing

#### Favicon

*Standard · Media · size S · phase 3 · definition `packages/shared/src/generative-ui/standard/media.ts`*

> The favicon of the site at a URL.

**Required:** `url`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `url` **(required)** | string |  |  |
| `alt` | string |  |  |
| `frame` | boolean | `false` | Default false |
| `size` | number | `16` | Pixels. Default 16 |
| `inline` | boolean | `false` | Default false |

- **React:** `https://www.google.com/s2/favicons?domain=<host>&sz=64` (host from `new URL`, https added when missing); size 16; alt = host; radius 4; `frame`.
- **Flutter:** `Image.network` with a configurable favicon URL builder (privacy: the default sends the host to Google, as React does).
- **Packages:** SDK only

#### Svg

*Standard · Media · size M · phase 3 · definition `packages/shared/src/generative-ui/standard/media.ts`*

> A vector drawing from primitive shapes (paths, circles, rects, lines, texts). Colors take text color tokens or CSS colors.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `paths` | {d: string, fill?: string, stroke?: string, strokeWidth?: number}[] |  |  |
| `viewBox` | string |  |  |
| `label` | string |  | What the drawing shows, for screen readers. Leave it unset for a decorative drawing |
| `fill` | string | `"currentColor"` | Default "currentColor" |
| `stroke` | string |  |  |
| `strokeWidth` | number |  |  |
| `strokeLinecap` | enum(butt \| round \| square) |  |  |
| `strokeLinejoin` | enum(miter \| round \| bevel) |  |  |
| `preserveAspectRatio` | string |  |  |
| `circles` | {cx: number, cy: number, r: number, fill?: string, stroke?: string}[] |  |  |
| `rects` | {x: number, y: number, width: number, height: number, rx?: number, fill?: string, stroke?: string}[] |  |  |
| `lines` | {x1: number, y1: number, x2: number, y2: number, stroke?: string}[] |  |  |
| `texts` | {x: number, y: number, text: string, size?: number, fill?: string, anchor?: enum(start \| middle \| end)}[] |  |  |
| `width` | number or string |  |  |
| `height` | number or string |  |  |
| `size` | number or string |  |  |
| `color` | string | `"prose"` | Default "prose" |

- **React:** Primitives only (rects, circles, paths, lines, texts), no raw markup; width `width ?? size ?? 100%`, height `height ?? size`, numbers are px; root fill currentColor; colours via the text-colour resolver.
- **Flutter:** `CustomPaint` drawing the primitives (`path_parsing` for `d`); no flutter_svg needed.
- **Packages:** SDK only

#### Video

*Standard · Media · size L · phase 3 · definition `packages/shared/src/generative-ui/standard/media.ts`*

> A video file URL (optional captions) or a YouTube link, privacy-enhanced: the poster shows until play. Other video sites show as a link. Set title.

**Required:** `url`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `url` **(required)** | string |  | The URL of a video file, or of a YouTube video or short. A page on another video site shows as a link |
| `title` | string |  | Names the video for screen readers |
| `captions` | {url: string, language?: string, label?: string, kind?: enum(subtitles \| captions \| descriptions)}[] |  | Caption tracks of a video file |
| `posterUrl` | string |  | The image shown before the video plays |
| `aspectRatio` | string | `"16 / 9"` | Default "16 / 9" |
| `width` | number or string | `"100%"` | Default "100%" |
| `maxWidth` | number or string | `"100%"` | Default "100%" |
| `weight` | number |  | flex-grow in a Row or Column |

- **React:** URL classified: YouTube (poster button → youtube-nocookie iframe, sandboxed), file (mp4/webm/m3u8…: `<video controls>` + caption tracks; error → link), or page (Vimeo, Loom… → black box with ▶, title, host, link). Aspect 16/9, radius 12.
- **Flutter:** File: `video_player` with a small controls bar (already a dependency of a2ui_flutter). YouTube/page: poster + ▶ that opens the URL externally by default; on web an optional iframe via `HtmlElementView`; an `A2uiEmbedDelegate` hook lets apps plug a player (e.g. `youtube_player_iframe`).
- **Packages:** video_player, url_launcher, web (web only)

#### AudioPlayer

*Standard · Media · size M · phase 3 · definition `packages/shared/src/generative-ui/standard/media.ts`*

> An audio player for an audio file URL, with the description above it.

**Required:** `url`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `url` **(required)** | string |  | The URL of the audio file |
| `description` | string |  | A title or summary of the audio, shown above the player |
| `weight` | number |  | flex-grow in a Row or Column |

- **React:** `figure`: optional description, then `<audio controls preload=metadata>` full width.
- **Flutter:** `video_player` controller (audio only) with play/pause, position slider and times.
- **Packages:** video_player

#### HtmlView

*Standard · Media · size L · phase 3 · definition `packages/shared/src/generative-ui/standard/media.ts`*

> Raw HTML in a fully sandboxed iframe: no scripts, no same-origin access. Set title to name the content.

**Required:** `html`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `html` **(required)** | string |  |  |
| `title` | string |  |  |
| `height` | number or string | `360` | Pixels when a number. Default 360 |
| `width` | number or string | `"100%"` | Default "100%" |

- **React:** An `iframe sandbox=""` (no scripts, forms, popups or same-origin) with `srcDoc=html`; height px (360), width 100%, border, radius 8.
- **Flutter:** Web: `HtmlElementView` iframe with `sandbox=""` and `srcdoc` (exact parity). Android/iOS/desktop: static render with `flutter_widget_from_html_core` (scripts ignored, links through `safeHref`), inline `<svg>` via flutter_svg. The mode is an option, like the lab's `HtmlMode`.
- **Packages:** flutter_widget_from_html_core, flutter_svg, web (web only)

### Standard: Composites

#### LinkCard

*Standard · Composites · size S · phase 5 · definition `packages/shared/src/generative-ui/standard/composites.ts`*

> A preview of a URL: favicon and domain, title, description, thumbnail. A click opens it in a new tab, or sends onClick when bound. For sources, articles and products with a page.

**Events:** `onClick` · **Required:** `href`, `title`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `href` **(required)** | string |  | The URL (http, https) |
| `title` **(required)** | string |  | The page title |
| `onClick` | Action |  | Sent when the user clicks the card, instead of the link. |
| `description` | string |  | One or two lines |
| `image` | string |  | A thumbnail URL |
| `domain` | string |  | Shown next to the favicon. Default: the host of href |
| `favicon` | boolean | `true` | Default true |

- **React:** An `<a target=_blank>` (a button when `onClick` is bound): row, gap 12, padding 12, border, radius 16; favicon + domain, title (2 lines), description (2 lines); 96×96 cover. `safeHref`.
- **Flutter:** Pressable card; favicon builder; `maxLines` + ellipsis.
- **Packages:** url_launcher

#### Citation

*Standard · Composites · size M · phase 4 · definition `packages/shared/src/generative-ui/standard/composites.ts`*

> An inline source marker ([1]) showing title, snippet and link on hover or click. Put it right after the sentence it supports, as a child of a Text or in a Row.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `index` | number | `1` | The marker number. Default 1 |
| `title` | string |  | The source title |
| `url` | string |  | The source URL (http, https) |
| `label` | string |  | Marker text instead of the number, for example a domain |
| `snippet` | string |  | The quoted passage, one or two lines |
| `source` | string |  | The publisher or domain. Default: the host of url |

- **React:** Superscript marker pill; hover opens, click toggles, outside mousedown closes; popup 280 wide (favicon, source, title, snippet, "Open source" link). No Escape/focus handling.
- **Flutter:** `WidgetSpan` marker + `OverlayPortal` popup; tap toggles on touch (no hover-then-click close bug).
- **Packages:** url_launcher

#### FollowUp

*Standard · Composites · size S · phase 4 · definition `packages/shared/src/generative-ui/standard/composites.ts`*

> Suggested next prompts as pills; a click sends the pill's message as the user's next turn, no event needed. At the end of a surface, two to four short items.

**Events:** `onFollowUp`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` | (string or {label: string, message?: string})[] |  |  |
| `onFollowUp` | Action |  | Sent when the user clicks a pill. The args carry the message of the pill. |
| `title` | string |  | A caption above the pills |

- **React:** Optional title + wrapping pills; click → `onFollowUp({message})`; unbound → the engine sends event `follow_up` with userMessage = message (appears as the user's next chat turn).
- **Flutter:** `Wrap` of pills; the unbound default goes through the host's action handler (documented: the Flutter host decides what a `follow_up` event does).
- **Packages:** SDK only

#### EntityCard

*Standard · Composites · size M · phase 5 · definition `packages/shared/src/generative-ui/standard/composites.ts`*

> A card for one product, place, person or listing: image, title, subtitle, description, a price or meta line, badge, rating and up to three buttons. href opens a page; onClick is sent when bound. Use a Grid of them for several things.

**Events:** `onAction`, `onClick` · **Required:** `title`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` **(required)** | string |  | The name |
| `actions` | {label: string, href?: string, variant?: enum(solid \| soft \| outline \| ghost)}[] |  | Up to three buttons. A button without href sends onAction with its label |
| `onAction` | Action |  | Sent when the user clicks a button without href. The args carry the label of the button. |
| `onClick` | Action |  | Sent when the user clicks the card and it has no href. |
| `subtitle` | string |  | A second line, for example the brand or category |
| `description` | string |  | Up to three lines |
| `image` | string |  | An image URL |
| `imageAspectRatio` | string | `"4 / 3"` | Default "4 / 3" |
| `meta` | string |  | A short fact line, for example "$29 / month" or "Open until 22:00" |
| `badge` | {label: string, color?: enum(secondary \| success \| danger \| warning \| info \| discovery)} |  |  |
| `rating` | number |  | 0 to 5, shown as stars |
| `ratingCount` | number |  | The number of ratings |
| `href` | string |  | Opens this URL in a new tab when the user clicks the card |
| `layout` | enum(vertical \| horizontal) | `"vertical"` | Default "vertical". "horizontal" puts the image on the left |
| `width` | number or string |  |  |

- **React:** Column card (row when horizontal), border, radius 16; image 4/3 (120px square when horizontal); subtitle + badge, title, rating stars (#f5a524) with count, description (3 lines), meta, up to 3 action pills (`openUrl(href)` or `onAction({label})`). Clickable with href/onClick.
- **Flutter:** Card widget from foundation pieces; star painter shared with Rating.
- **Packages:** url_launcher

#### ImageGrid

*Standard · Composites · size M · phase 3 · definition `packages/shared/src/generative-ui/standard/composites.ts`*

> A gallery of images in a grid. A click opens the image full-screen, with arrows to the other images. layout "bento" makes the first image twice as large.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `images` | {url: string, description?: string, caption?: string, href?: string}[] |  |  |
| `columns` | number | `3` | Default 3 |
| `layout` | enum(grid \| bento) | `"grid"` | Default "grid". "bento" makes the first image twice as large |
| `aspectRatio` | string | `"1 / 1"` | Default "1 / 1" |
| `gap` | number or string | `2` | Default 2 |

- **React:** Grid `repeat(columns ?? 3, 1fr)`, gap `gap ?? 2` steps; figure with cover image (aspect 1/1) + caption; `layout: bento` (first spans 2×2, dense); click → openUrl or Lightbox.
- **Flutter:** Custom grid layout (bento placement) + shared Lightbox.
- **Packages:** url_launcher

### Playground: Layout

#### Section

*Playground · Layout · size S · phase 1 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/layout.ts`*

> Titled group with eyebrow, title, description, and children.

**Children:** `children` (ChildList) · **Required:** `children`, `title`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `eyebrow` | string |  |  |
| `title` **(required)** | string |  |  |
| `description` | string |  |  |
| `children` **(required)** | ChildList |  |  |

- **React:** Borderless `section`, column gap 12; header row: title 15px semibold then the eyebrow (`.a2-label`) on the same baseline row after it; description 12.5px muted; children column gap 12. Panel-in animation 400ms.
- **Flutter:** `Column` + `Wrap` header; children through the CSS-flex box.
- **Packages:** SDK only

#### Accordion

*Playground · Layout · size S · phase 4 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/layout.ts`*

> Collapsible items (FAQs, details, per-file notes); each has a title and either text or a child id.

**Children:** `items[].child` (ComponentId) · **Required:** `items`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` **(required)** | {title: string, text?: string, child?: ComponentId}[] |  |  |
| `multiple` | boolean |  |  |

- **React:** One card with Radix Accordion items (px-16, line between items); trigger 13px medium, chevron 16px; content 12.5px muted `text` then `item.child`. `multiple` → all closed; single → item 0 open by default, collapsible. ~200ms height animation.
- **Flutter:** Custom expansion items (`AnimatedSize`/`SizeTransition`), not `ExpansionTile` (different chrome).
- **Packages:** SDK only

### Playground: Content

#### Heading

*Playground · Content · size M · phase 1 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/content.ts`*

> Surface title with optional eyebrow and subtitle. Start most surfaces with one.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  |  |
| `eyebrow` | string |  |  |
| `subtitle` | string |  |  |
| `level` | enum(1 \| 2 \| 3) |  |  |

- **React:** Level 1 24px / 2 19px (default) / 3 15.5px, semibold, balanced wrapping; eyebrow inline after the title; subtitle 13px muted. Words stream in (350ms fade + blur, 60ms stagger, only new words animate).
- **Flutter:** `Text` with per-word `FadeTransition` on growth (respecting reduced motion); `Semantics(header: true)`.
- **Packages:** SDK only

#### CodeBlock

*Playground · Content · size M · phase 6 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/content.ts`*

> Syntax-colored code with language label and copy button. Use for any code, config, command or diff snippet.

**Required:** `code`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `code` **(required)** | string |  |  |
| `language` | string |  |  |
| `filename` | string |  |  |

- **React:** Card figure: caption bar (three 8px dots, `filename ?? language ?? "code"`, Copy button → "Copied" for 1200ms); `pre` mono 12.5px/1.65, no wrapping; sugar-high highlighting (one JS-like tokenizer for every language).
- **Flutter:** Port of sugar-high's tokenizer (MIT, small) to `TextSpan`s with the `.a2-code` palette; horizontal scroll; clipboard copy.
- **Packages:** SDK only

#### Quote

*Playground · Content · size S · phase 6 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/content.ts`*

> Pull quote with attribution: testimonial, review, reviewer comment.

**Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `text` **(required)** | string |  |  |
| `author` | string |  |  |
| `role` | string |  |  |

- **React:** Bordered figure with a violet 7% gradient, padding 20×16, faint 32px quote icon top-right; 15px medium quote; caption "**author**, role".
- **Flutter:** `DecoratedBox` with gradient + positioned icon.
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### ImageGallery

*Playground · Content · size S · phase 3 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/content.ts`*

> Grid of images with captions.

**Required:** `images`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `images` **(required)** | {url: string, caption?: string}[] |  |  |
| `columns` | number |  |  |

- **React:** Grid cols = clamp(columns ?? 3, 2, 4), gap 8; square cover tiles, radius 12, hover scale 1.03 (500ms); caption on a black→transparent gradient; hero tile 2×2 when n > 3 and (n+3) % cols == 0. No lightbox.
- **Flutter:** Custom grid (shares ImageGrid's placement code).
- **Packages:** SDK only

#### VideoEmbed

*Playground · Content · size M · phase 3 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/content.ts`*

> Embedded YouTube/Vimeo video by URL.

**Required:** `url`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `url` **(required)** | string |  |  |
| `title` | string |  |  |

- **React:** 16:9 black box, lazy iframe: YouTube regex → youtube-nocookie embed; Vimeo → player.vimeo.com; else "Unsupported video URL". Caption 12px.
- **Flutter:** Same embed path as Video (poster/open externally; iframe on web; delegate hook); identical URL parsing.
- **Packages:** url_launcher, web (web only)

#### Kbd

*Playground · Content · size S · phase 6 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/content.ts`*

> Keyboard shortcut chips, e.g. keys ['Cmd','K'] with a label. Use for shortcuts and how-to steps.

**Required:** `keys`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `keys` **(required)** | string[] |  |  |
| `label` | string |  |  |

- **React:** Inline `<kbd>` chips: min-width 24, rounded, 1px border with 2px bottom, black/6% fill, mono 11px; optional label.
- **Flutter:** `Wrap` of decorated chips.
- **Packages:** SDK only

### Playground: Data display

#### Stat

*Playground · Data display · size M · phase 1 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> One numeric KPI: label, short value (number or <10 chars like '$84k'), optional delta (e.g. '+4.2%'), caption. Not for sentences.

**Required:** `label`, `value`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` **(required)** | string |  |  |
| `value` **(required)** | string or number |  |  |
| `delta` | string |  |  |
| `trend` | enum(up \| down \| flat) |  |  |
| `caption` | string |  |  |
| `tone` | enum(default \| positive \| negative \| warning \| info \| accent) |  |  |
| `icon` | string |  |  |

- **React:** Card + container query: label 12px muted, optional 24px icon tile (tone soft); KpiValue (size clamp(14px, fit cqi, 26px) by text length and card width; per-glyph pop-in 500ms/70ms stagger with overshoot, not for phrases > 14 chars with a space); Delta (trend or sign; ArrowUpRight/DownRight/Minus, positive/negative/muted); caption 11px 2 lines.
- **Flutter:** `LayoutBuilder` for the container-query font size; glyph pop-in with staggered `AnimationController`; `iconFor` lookup.
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### StatGroup

*Playground · Data display · size M · phase 1 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Compact strip of several KPIs in one card.

**Required:** `items`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` **(required)** | ({label: string, value: string or number, delta?: string, trend?: enum(up \| down \| flat)})[] |  |  |

- **React:** Card grid `repeat(auto-fit, minmax(132px, 1fr))` with 1px hairline gaps; cells: label, KpiValue (max 22px), Delta; empty → 80px cell.
- **Flutter:** Grid layout from the foundation + hairline dividers.
- **Packages:** SDK only

#### Avatar

*Playground · Data display · size S · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Person avatar (initials if no image) with name and subtitle: authors, owners, reviewers.

**Required:** `name`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` **(required)** | string |  |  |
| `image` | string |  |  |
| `subtitle` | string |  |  |
| `size` | enum(sm \| md \| lg) |  |  |
| `status` | enum(online \| away \| offline) |  |  |

- **React:** sm 24 / md 32 / lg 44; initials (first+last word) on a hue tint (hue = Σ(h×31 + code) % 360, oklch); image with fallback; status dot (online/away/offline); name + subtitle.
- **Flutter:** `CircleAvatar`-free custom (image + fallback), oklch colour util from foundation.
- **Packages:** SDK only

#### AvatarGroup

*Playground · Data display · size S · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Overlapping avatar stack with +N overflow: attendees, team members, reviewers.

**Required:** `people`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `people` **(required)** | {name: string, image?: string}[] |  |  |
| `max` | number |  |  |
| `label` | string |  |  |

- **React:** First `max` (5) avatars, 32px, 2px ring, −6px overlap; hover lifts −2px; tooltip with name (120ms); "+N" bubble; label.
- **Flutter:** `Stack`/`Row` with negative spacing via `Transform.translate` or `Align`; `Tooltip`.
- **Packages:** SDK only

#### DataTable

*Playground · Data display · size L · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Sortable, filterable table (TanStack Table). columns [{key,label,format?}], rows are objects keyed by column key.

**Required:** `columns`, `rows`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `columns` **(required)** | {key: string, label: string, format?: enum(text \| number \| currency \| percent \| badge \| date), align?: enum(left \| right)}[] |  |  |
| `rows` **(required)** | object[] |  |  |
| `searchable` | boolean |  |  |
| `pageSize` | number |  |  |

- **React:** TanStack Table: sorting (alphanumeric/basic, undefined last), global filter (`includesString` on raw accessor values), pagination (`pageSize` 8). Header: title, "N rows" (total), search ("Search rows"). Sort header buttons with hover icons. Cells 40px, nowrap; formats number/currency/percent (fraction detection: if every |v| <= 1, ×100)/date/badge (`toneFromText`). Empty states; pager "from-to of N".
- **Flutter:** Own table model (sort, filter, paginate) + widgets; reproduce the sort cycle of TanStack v9 (verify), the fraction-percent rule and the raw-value search.
- **Packages:** intl

#### KeyValueList

*Playground · Data display · size M · phase 1 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Label/value rows, e.g. specs or order details.

**Required:** `items`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `items` **(required)** | ({label: string, value: string or number, hint?: string})[] |  |  |
| `columns` | number |  |  |

- **React:** Card + container query: optional title; `columns` 1–3 (2 from 448px, 3 from 672px), column gap 24; rows dashed bottom border; < 256px the label and value stack, else grid `auto 1fr`; label 12.5px muted, value 13px medium right-aligned (numbers via formatNumber), hint 11px.
- **Flutter:** `LayoutBuilder` breakpoints; dashed border painter.
- **Packages:** SDK only

#### Timeline

*Playground · Data display · size S · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Vertical timeline of dated events or steps with status.

**Required:** `items`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `items` **(required)** | {title: string, time?: string, description?: string, status?: enum(done \| current \| upcoming), icon?: string}[] |  |  |

- **React:** Card; 20px rail with connector lines; nodes done (positive check) / current (accent ring + halo) / upcoming (muted dot); icon override; title, time (right), description; 18px between items.
- **Flutter:** `CustomPaint` rail + rows.
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### Progress

*Playground · Data display · size S · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Labelled progress bar, value 0-100: goals, budgets used, completion, coverage.

**Required:** `value`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  |  |
| `value` **(required)** | number |  |  |
| `caption` | string |  |  |
| `tone` | enum(default \| positive \| negative \| warning \| info \| accent) |  |  |

- **React:** Label + `round(v)%`; 6px pill bar, track black/7%, tone colour (default accent), 150ms transition; caption.
- **Flutter:** `AnimatedFractionallySizedBox` bar.
- **Packages:** SDK only

#### RadialProgress

*Playground · Data display · size S · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Ring with centered value, value 0-100: a single score or percent complete.

**Required:** `value`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  |  |
| `value` **(required)** | number |  |  |
| `display` | string |  |  |
| `tone` | enum(default \| positive \| negative \| warning \| info \| accent) |  |  |

- **React:** Card row: 76px SVG ring, stroke 7, tone arc (default accent) from 12 o'clock, 700ms dashoffset animation + glow; centre `display ?? round(v)%` 17px; label + "N of 100".
- **Flutter:** `CustomPaint` arc with `TweenAnimationBuilder`; glow via `MaskFilter.blur`.
- **Packages:** SDK only

#### Rating

*Playground · Data display · size S · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Star rating (0-5) with optional review count: products, places, reviews.

**Required:** `value`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `value` **(required)** | number |  |  |
| `count` | number |  |  |
| `label` | string |  |  |

- **React:** Value clamped 0–5; five 16px stars, fractional fill by clip; value `toFixed(1)` + "N reviews"; optional label.
- **Flutter:** Star painter with `ClipRect` fractional fill.
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### TagList

*Playground · Data display · size S · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Wrapping list of tags/chips.

**Required:** `tags`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `tags` **(required)** | string[] |  |  |
| `tone` | enum(default \| positive \| negative \| warning \| info \| accent) |  |  |

- **React:** Wrapping outline badges (24px, 12px text) in the tone's soft style; truncated.
- **Flutter:** `Wrap` of chips.
- **Packages:** SDK only

#### Agenda

*Playground · Data display · size M · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Calendar agenda: days with timed events (conference, week plan, schedule). Prefer over Timeline for clock times.

**Required:** `days`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `days` **(required)** | {date: string, label?: string, events: {time, title, speaker, location, description, tone}[]}[] |  |  |

- **React:** Card; days separated by dividers; 48px date column (weekday label, day 22px, month); events in wells: 2px tone bar, 64px time ("All day"), title, speaker, description (2 lines), location with MapPin; "Nothing scheduled". YYYY-MM-DD = local midnight.
- **Flutter:** Rows of wells; dates via the foundation's date parser + `intl` en-US formats.
- **Packages:** intl, Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### ComparisonTable

*Playground · Data display · size M · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/data.ts`*

> Feature matrix comparing options side by side. options are the option names as strings; rows [{feature, values}] with one value per option, in the same order, each true/false/text; highlight is the recommended option's index in options (0 is the first).

**Required:** `options`, `rows`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `options` **(required)** | string[] |  |  |
| `rows` **(required)** | ({feature: string, values: (string or number or boolean)[]})[] |  |  |
| `highlight` | number |  |  |

- **React:** Card + table: "Feature" column, option headers centred; `highlight` column tinted accent 7% with "Recommended" badge; cells: true → green check circle, false → X, empty → "-", numbers formatted.
- **Flutter:** Horizontal-scroll `Table` with fixed first column width.
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

### Playground: Charts

#### LineChart

*Playground · Charts · size L · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Trend over ordered x. data [{x,y,series?}]; one line per series.

**Required:** `data`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `data` **(required)** | ({x: string or number, y: number, series?: string})[] |  |  |
| `curve` | boolean |  |  |
| `highlight` | string |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. Linear nice x when every x is numeric, else point scale (padding .25); monotone cubic (Fritsch–Carlson), `curve:false` straight; dots when <= 16 rows; single non-negative series gets a fade area; crosshair, snap-from-anywhere tooltip; height 220; `highlight` greys the other series.
- **Flutter:** `fl_chart` `LineChart` (`isCurved`, `preventCurveOverShooting` ≈ monotone; verify against goldens) with custom touch tooltip and crosshair; shared ChartFrame.
- **Packages:** fl_chart, intl

#### AreaChart

*Playground · Charts · size L · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Filled trend for volumes or cumulative totals (traffic, signups); series stack. data [{x,y,series?}].

**Required:** `data`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `data` **(required)** | ({x: string or number, y: number, series?: string})[] |  |  |
| `stacked` | boolean |  |  |
| `highlight` | string |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. Stacked by default with > 1 series (fill .62, 1px surface stroke between bands, Total row in tooltip); unstacked: fade gradient per series + 1.75 line; height 220.
- **Flutter:** `fl_chart` `LineChart` with `betweenBarsData`/stacked cumulative series and gradients.
- **Packages:** fl_chart, intl

#### BarChart

*Playground · Charts · size L · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Compare categories. data [{x,y,series?}]; series grouped side by side, or stacked:true. horizontal for long labels.

**Required:** `data`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `data` **(required)** | ({x: string or number, y: number, series?: string})[] |  |  |
| `stacked` | boolean |  |  |
| `horizontal` | boolean |  |  |
| `highlight` | string |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. Band scale (padding .24 multi / .32 single); grouped (padding .12) or stacked (outer end rounded 4); vertical max thickness 18/40, labels cut at 12 chars, height 230; `horizontal`: thickness 22, labels 18 chars, height max(160, cats×(40|30)+40).
- **Flutter:** `fl_chart` `BarChart` (`rotationQuarterTurns` for horizontal, `BarChartRodStackItem` for stacks).
- **Packages:** fl_chart, intl

#### PieChart

*Playground · Charts · size M · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Part-to-whole. data [{label,value}]; donut:true for a ring with center total.

**Required:** `data`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `data` **(required)** | {label: string, value: number}[] |  |  |
| `donut` | boolean |  |  |
| `centerLabel` | string |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. Donut by default (inner 64%, corner 4; pie corner 2), gap .025 rad, colour by label; hover dims others to .35; donut centre total + `centerLabel ?? "Total"`; side list with swatch, value and share (1 decimal under 10%).
- **Flutter:** `fl_chart` `PieChart` (sections, `centerSpaceRadius`) + side list widget; centre overlay in a `Stack`.
- **Packages:** fl_chart, intl

#### ScatterChart

*Playground · Charts · size M · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Relationship between two numbers (price vs rating, effort vs impact). data [{x,y,label?,size?,series?}].

**Required:** `data`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `data` **(required)** | {x: number, y: number, label?: string, size?: number, series?: string}[] |  |  |
| `xLabel` | string |  |  |
| `yLabel` | string |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. Both axes linear nice; dot r 5 or 3.5 + sqrt(size/max)×11; fill .55; hover; axis labels; height 260.
- **Flutter:** `fl_chart` `ScatterChart`.
- **Packages:** fl_chart, intl

#### Heatmap

*Playground · Charts · size M · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Matrix of values, e.g. day x hour. data [{x,y,value}] with x,y categories.

**Required:** `data`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `data` **(required)** | {x: string, y: string, value: number}[] |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. Band axes in first-appearance order; cells inset 1.5, radius 4; colour = color-mix(oklch, chart-1 at pct = round(4 + t^0.8 × 96)%, heat-low); values shown when cells <= 48 and x <= 12; height clamp(ys×30+36, 150, 320); min–max gradient legend.
- **Flutter:** `CustomPaint` grid + oklch mixing util (foundation).
- **Packages:** intl

#### Sparkline

*Playground · Charts · size M · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Tiny trend with label and latest value; a compact KPI with history, fits in a Grid instead of Stat. values: numbers.

**Required:** `values`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  |  |
| `values` **(required)** | number[] |  |  |
| `value` | string |  |  |
| `delta` | string |  |  |
| `tone` | enum(positive \| negative \| default) |  |  |

- **React:** Card row: label, value (or compact last), delta pill tinted by tone; tone from prop or first/last; 44px chart, area gradient .3→0, smooth 1.75 line, end dot; < 2 values → shimmer bar.
- **Flutter:** Small `CustomPaint` (monotone path helper shared with the chart kit); no axes.
- **Packages:** SDK only

#### RadarChart

*Playground · Charts · size M · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Multi-axis profile (scores per criterion for 2-3 options or people). data [{axis,value,series?}], values on a shared scale.

**Required:** `data`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `data` **(required)** | {axis: string, value: number, series?: string}[] |  |  |
| `max` | number |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. Radius ratio .78; rings at 25/50/75/100%, spokes; labels offset 12, cut at 16; per series closed polygon fill .2, stroke 1.75, dots r 2.75; empty with < 3 axes; height 280.
- **Flutter:** `fl_chart` `RadarChart` with custom ticks, or a `CustomPaint` if the ring styling cannot match.
- **Packages:** fl_chart

#### CandlestickChart

*Playground · Charts · size M · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> OHLC price candles. data [{date,open,high,low,close}].

**Required:** `data`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `data` **(required)** | {date: string, open: number, high: number, low: number, close: number}[] |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. high/low widened to include open/close; up when close >= open; wick 1.25, body radius 1.5, min height .6% of range; band padding .36, labels 8 chars; header: last close + "±x.xx% over period"; height 240.
- **Flutter:** `fl_chart` `CandlestickChart` or `CustomPaint` (decide by golden fidelity).
- **Packages:** fl_chart, intl

#### Treemap

*Playground · Charts · size L · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Nested part-to-whole as rectangles. data [{name,value,group?}].

**Required:** `data`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `data` **(required)** | {name: string, value: number, group?: string}[] |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. Merge same group+name; path root|g:<group>|name sorted by value; squarified layout, paddingInner 3, outer 1.5, radius 6, opacity .88; colour by group; dark labels 11.5px/600 even in dark mode; tooltip Group/Value/Share.
- **Flutter:** Own squarified treemap layout (port of the d3-hierarchy squarify algorithm; keep its ISC notice if code is ported) + `CustomPaint`.
- **Packages:** intl

#### SankeyChart

*Playground · Charts · size L · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Flows between stages, e.g. budget or funnel paths. links [{source,target,value}].

**Required:** `links`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `subtitle` | string |  |  |
| `height` | number |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |
| `unit` | string |  |  |
| `links` **(required)** | {source: string, target: string, value: number}[] |  |  |

- **React:** TanStack Charts (`@tanstack/charts` 1.1.0) through `chart-kit.tsx`: ChartFrame card (title 13.5px, subtitle 11.5px), palette `--ts-chart-1..6`, dashed 2 4 grid, 5 value ticks, tooltip (radius 10, 11.5px), legend only with > 1 series, SVG wipe-in 700ms, "No data yet" / "Waiting for complete data" states. Cleaning: drop self-links and values <= 0, merge parallel links, drop cycle-closing edges; nodeWidth 10, nodePadding max(10, 5% height); bumpX ribbons in the source colour at .28; labels right of nodes (left for the last layer), name (22 chars) + value; height 280.
- **Flutter:** Own sankey layout (port of TanStack Charts' / d3-sankey's algorithm; keep the source's notice) + `CustomPaint` ribbons.
- **Packages:** intl

#### Gauge

*Playground · Charts · size S · phase 2 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/charts.ts`*

> Half-ring gauge for a single value within min..max (score, utilization).

**Required:** `value`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `value` **(required)** | number |  |  |
| `min` | number |  |  |
| `max` | number |  |  |
| `label` | string |  |  |
| `format` | enum(number \| currency \| percent \| compact) |  |  |

- **React:** Half ring −90°..90°: track ink 7%, value arc chart-1 (negative when t >= .9), inner radius 78%, round ends; 240px chart clipped to 124px; value 26px via fmtValue (no unit); min/max labels.
- **Flutter:** `CustomPaint` arc.
- **Packages:** intl

### Playground: Maps

#### MapView

*Playground · Maps · size L · phase 3 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/maps.ts`*

> Interactive map (MapLibre) with numbered markers; fits all markers. markers [{name,lat,lon,description?}].

**Required:** `markers`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `markers` **(required)** | {id?: string, name: string, lat: number, lon: number, description?: string, category?: string}[] |  |  |
| `height` | number |  |  |
| `zoom` | number |  |  |

- **React:** MapCanvas: react-map-gl/maplibre on maplibre-gl 6.14; CARTO Voyager (light) / Dark Matter (dark) GL styles; no rotate/pitch; zoom buttons; compact attribution; fit bounds (max zoom 15, top padding +30), refit on bounds change (600ms); 26px violet teardrop numbered pins (active scale 1.18 + pulse), no popups; routes as glow + casing + gradient line; shimmer until load. No WebGL fallback. Card header (map tile, title "Map", "N places"); height clamp(height, 160, 640) default 340; chips row below (hover activates, click toggles a pin). Markers are geocoded **on the server**, never in the client.
- **Flutter:** Shared `A2uiMapCanvas` on `flutter_map` (raster CARTO voyager / dark_all by default; configurable), custom pin widgets in `MarkerLayer`, `PolylineLayer` with `gradientColors` for routes, `CameraFit.bounds`, `MapController.fitCamera` animations.
- **Packages:** flutter_map, latlong2

#### RouteMap

*Playground · Maps · size L · phase 3 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/maps.ts`*

> Map with a route line through coordinates [[lon,lat],...] plus start/end pins and distance/duration.

**Required:** `coordinates`, `from`, `to`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `from` **(required)** | string |  |  |
| `to` **(required)** | string |  |  |
| `coordinates` **(required)** | number[][] |  |  |
| `distance` | string |  |  |
| `duration` | string |  |  |
| `height` | number |  |  |

- **React:** MapCanvas: react-map-gl/maplibre on maplibre-gl 6.14; CARTO Voyager (light) / Dark Matter (dark) GL styles; no rotate/pitch; zoom buttons; compact attribution; fit bounds (max zoom 15, top padding +30), refit on bounds change (600ms); 26px violet teardrop numbered pins (active scale 1.18 + pulse), no popups; routes as glow + casing + gradient line; shimmer until load. No WebGL fallback. Header from → to with dashed arrow; needs >= 2 coordinates (skeleton "Plotting route"); distance/duration chips top-left; legend "Start / Destination", "N waypoints". Route coordinates are [lon, lat], points {lat, lon}.
- **Flutter:** Same canvas; three stacked polylines (glow with blur is approximated by a wide translucent line).
- **Packages:** flutter_map, latlong2

#### LocationCard

*Playground · Maps · size M · phase 3 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/maps.ts`*

> Single place (venue, hotel, office): mini map, name, address, category, rating, actions. Use instead of MapView for one place.

**Required:** `lat`, `lon`, `name`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` **(required)** | string |  |  |
| `address` | string |  |  |
| `lat` **(required)** | number |  |  |
| `lon` **(required)** | number |  |  |
| `category` | string |  |  |
| `rating` | number |  |  |
| `hours` | string |  |  |

- **React:** 150px non-interactive map (zoom 14.5, single dot pin, fade at the bottom); name, address, category badge, rating, hours; buttons "Directions" (Google Maps dir URL) and "Open map" (openstreetmap.org).
- **Flutter:** Static `FlutterMap` (`InteractionOptions(flags: none)`), buttons via url_launcher.
- **Packages:** flutter_map, latlong2, url_launcher

#### PlaceList

*Playground · Maps · size L · phase 3 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/maps.ts`*

> Split view: ranked list of places linked to a map; hovering/clicking a row highlights its marker. selected (row index) starts with that row highlighted.

**Required:** `places`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `places` **(required)** | {id?: string, name: string, lat: number, lon: number, description?: string, category?: string, address?: string, distanceKm?: number, rating?: number}[] |  |  |
| `source` | string |  |  |
| `selected` | number |  |  |
| `height` | number |  |  |
| `basemap` | enum(dark \| streets \| liberty) |  |  |

- **React:** Container query: >= 540px two columns (list 1fr, map 1.15fr), else map on top (240px); `--pl-h = height ?? 340` (not clamped); rows with number dot, name, rating, address/description/category, distance ("N m"/"x.x km"); hover eases to the pin (450ms), click flies (900ms) at zoom max(current, 14.5); marker click scrolls the row into view; `basemap` dark/streets/liberty; empty → shimmer rows.
- **Flutter:** `LayoutBuilder` split; list `Scrollable.ensureVisible`; map canvas with animated camera moves.
- **Packages:** flutter_map, latlong2

### Playground: Inputs

#### Combobox

*Playground · Inputs · size M · phase 4 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/inputs.ts`*

> Searchable dropdown for long option lists (countries, cities, timezones).

**Writes back:** `value` · **Required:** `options`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  |  |
| `value` | string |  |  |
| `options` **(required)** | {value: string, label: string}[] |  |  |
| `placeholder` | string |  |  |

- **React:** Outline trigger (`role=combobox`) with the selected label or placeholder ("Search options"); popover (min 208px, trigger width) with a cmdk list, search "Search", empty "No match found"; match on label+value; check on the selected item; writes the value and closes. Option description ignored.
- **Flutter:** `MenuAnchor`/`OverlayPortal` with a filter `TextField` and a list; or `RawAutocomplete`.
- **Packages:** SDK only

#### Switch

*Playground · Inputs · size S · phase 4 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/inputs.ts`*

> On/off toggle with label and description.

**Writes back:** `value` · **Required:** `label`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` **(required)** | string |  |  |
| `value` | boolean |  |  |
| `description` | string |  |  |

- **React:** Well row: label 13px + description 11.5px and a Radix switch (32×18.4, 16px thumb). Writes a bool.
- **Flutter:** Custom-sized `Switch` (Material 3 metrics differ: paint our own track/thumb).
- **Packages:** SDK only

#### DatePicker

*Playground · Inputs · size M · phase 4 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/inputs.ts`*

> Date picker with calendar popover; value ISO date bound to a path.

**Writes back:** `value`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  |  |
| `value` | string |  |  |
| `placeholder` | string |  |  |

- **React:** Outline trigger with CalendarDays and `EEE, MMM d, yyyy`, else `placeholder ?? "Pick a date"`; react-day-picker popover (single, outside days, 28px cells); writes `yyyy-MM-dd` and closes; re-picking the same day only closes.
- **Flutter:** `CalendarDatePicker` in an overlay (or `showDatePicker` on phones); `intl` `DateFormat('EEE, MMM d, yyyy', 'en_US')`.
- **Packages:** intl

#### ButtonGroup

*Playground · Inputs · size S · phase 4 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/inputs.ts`*

> Segmented single-choice control; value bound to a path.

**Writes back:** `value` · **Required:** `options`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  |  |
| `value` | string |  |  |
| `options` **(required)** | {value: string, label: string}[] |  |  |

- **React:** Radix ToggleGroup single as a segmented control (rounded-lg, black/9% border, 2px padding); items 28px, 12.5px; selected white + shadow; clicking the selected does not clear. Writes a string.
- **Flutter:** Custom segmented row.
- **Packages:** SDK only

#### ChipSelect

*Playground · Inputs · size S · phase 4 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/inputs.ts`*

> Multi-select chips bound to a string-list path: extras, interests, dietary needs.

**Writes back:** `value` · **Required:** `options`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string |  |  |
| `value` | string[] |  |  |
| `options` **(required)** | {value: string, label: string}[] |  |  |

- **React:** Radix ToggleGroup multiple, wrapping chips (28px, full radius, 12.5px); on: accent 50% border, 14% fill, check icon; "N selected" in the label row. Writes string[] in click order.
- **Flutter:** `Wrap` of toggle chips; preserve click order.
- **Packages:** SDK only

### Playground: Feedback

#### Alert

*Playground · Feedback · size S · phase 1 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/feedback.ts`*

> Inline alert with icon, title and message.

**Required:** `title`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` **(required)** | string |  |  |
| `message` | string |  |  |
| `tone` | enum(info \| success \| warning \| error) |  |  |

- **React:** Own tones info (default) / success / warning / error → Tailwind sky / emerald / amber / rose (border 20–25%, bg 6–7%, text 800 / dark 100–200, 16px icons Info / CheckCircle2 / AlertTriangle / XCircle); radius 12; title 13px semibold, message 12.5px at 80%; role status.
- **Flutter:** `DecoratedBox` + icon row; the four Tailwind palettes as theme tokens (light and dark).
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### Callout

*Playground · Feedback · size S · phase 1 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/feedback.ts`*

> Highlighted tip or note with optional emoji/icon and a call to action.

**Events:** `onAction` · **Required:** `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `text` **(required)** | string |  |  |
| `icon` | string |  |  |
| `actionLabel` | string |  |  |
| `onAction` | Action |  | Fires when the call-to-action button is clicked. |

- **React:** Violet gradient (10% → 4% → transparent), violet border, radius 14; 32px tile with Lightbulb (the `icon` prop is ignored); title 13px, text 12.5px; secondary sm button `actionLabel` only when `onAction` is bound → `onAction({})`.
- **Flutter:** `DecoratedBox` with gradient; button only when the action is bound.
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### Skeleton

*Playground · Feedback · size S · phase 6 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/feedback.ts`*

> Loading placeholder lines/blocks.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `lines` | number |  |  |
| `variant` | enum(text \| card \| chart) |  |  |

- **React:** text (`lines` bars, 12px, last 60%), card (circle + 3 bars), chart (7 bottom-aligned bars); opacity pulse 1 → .5 → 1 over 1000ms.
- **Flutter:** Shared `A2uiShimmer` pulse.
- **Packages:** SDK only

#### EmptyState

*Playground · Feedback · size S · phase 6 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/feedback.ts`*

> Empty or zero-results state with icon, title, hint and optional action: no matches, nothing scheduled, inbox zero.

**Events:** `onAction` · **Required:** `title`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` **(required)** | string |  |  |
| `description` | string |  |  |
| `icon` | string |  |  |
| `actionLabel` | string |  |  |
| `onAction` | Action |  | Fires when the action button is clicked. |

- **React:** Dashed border (black/12), radius 14, padding 24×32, centred: 40px circle with Inbox (the `icon` prop is ignored), title 14px, description 12.5px (max 384px); primary sm button only with `actionLabel` and a bound `onAction`.
- **Flutter:** Dashed border painter + column.
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

### Playground: Domain

#### WeatherCard

*Playground · Domain · size M · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/domain.ts`*

> Current weather hero with condition icon, temp, high/low, details, an hourly strip and daily forecast. icon: sun\|cloud-sun\|cloud\|fog\|drizzle\|rain\|snow\|storm.

**Required:** `condition`, `location`, `temp`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `location` **(required)** | string |  |  |
| `temp` **(required)** | number |  |  |
| `condition` **(required)** | string |  |  |
| `icon` | string |  |  |
| `high` | number |  |  |
| `low` | number |  |  |
| `feels` | number |  |  |
| `humidity` | number |  |  |
| `wind` | number |  |  |
| `unit` | enum(C \| F) |  |  |
| `hourly` | {label: string, temp: number, icon?: string, precip?: number}[] |  |  |
| `daily` | {label: string, min: number, max: number, icon?: string, precip?: number}[] |  |  |

- **React:** Icon key (sun, cloud-sun, cloud, fog, drizzle, rain, snow, storm) from `icon` or a regex chain over icon+condition; 256px blurred glow per key; temperature `round` 56px + °C/°F; condition, H/L; detail wells (feels like, humidity, wind km/h or mph); hourly strip (precip % hidden when 0); daily rows with a positioned gradient range bar.
- **Flutter:** Composite widget; glow via `ImageFiltered`/`BoxShadow`; oklch colours from the foundation.
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### ProfileCard

*Playground · Domain · size M · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/domain.ts`*

> Person card: avatar, name, role, company, location, bio, contacts, tags, stats. Use for team members, speakers, candidates.

**Required:** `name`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `name` **(required)** | string |  |  |
| `role` | string |  |  |
| `company` | string |  |  |
| `avatar` | string |  |  |
| `location` | string |  |  |
| `bio` | string |  |  |
| `email` | string |  |  |
| `phone` | string |  |  |
| `website` | string |  |  |
| `tags` | string[] |  |  |
| `stats` | {label: string, value: string}[] |  |  |

- **React:** 64px gradient banner (light/dark sets), 64px avatar pulled up 32px with 4px ring; initials of the first two words; location top-right; name, role at company, bio, tags; up to 4 stats with dividers; contacts mailto / tel (digits and + only) / website (scheme hidden, https added).
- **Flutter:** Composite widget; url_launcher for contacts.
- **Packages:** url_launcher, Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### ReceiptCard

*Playground · Domain · size S · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/domain.ts`*

> Order receipt: merchant, order id, date, line items with qty and price, subtotal/tax/total, status.

**Required:** `items`, `merchant`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `merchant` **(required)** | string |  |  |
| `orderId` | string |  |  |
| `date` | string |  |  |
| `status` | string |  |  |
| `items` **(required)** | {name: string, qty?: number, price: number, note?: string}[] |  |  |
| `currency` | string |  |  |
| `tax` | number |  |  |
| `shipping` | number |  |  |
| `discount` | number |  |  |
| `payment` | string |  |  |

- **React:** Totals: subtotal = Σ price×(qty ?? 1), total = subtotal + tax + shipping − |discount|; money via Intl en-US currency (`currency ?? USD`, fallback "CUR 1.23"); status badge by regex (emerald/rose/amber); items with qty chip; dashed rule; Subtotal, Shipping ("Free" when 0), Discount, Tax (when not 0), Total 18px; payment footer.
- **Flutter:** Composite widget; money formatter from foundation.
- **Packages:** intl, Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### EventCard

*Playground · Domain · size M · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/domain.ts`*

> Event: date block, title, time, venue, host, attendees count, tags, RSVP action. Lead an event or conference with it.

**Events:** `onAction` · **Required:** `date`, `title`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` **(required)** | string |  |  |
| `date` **(required)** | string |  |  |
| `time` | string |  |  |
| `venue` | string |  |  |
| `host` | string |  |  |
| `description` | string |  |  |
| `attendees` | number |  |  |
| `image` | string |  |  |
| `tags` | string[] |  |  |
| `actionLabel` | string |  |  |
| `onAction` | Action |  | Fires when the RSVP button is clicked. |

- **React:** Optional 128px image (hidden on error); 56px date block (accent month strip, day 22px, weekday); title, time, venue, host, description, tags; footer with three gradient dots + "N going" and the button `actionLabel ?? "RSVP"` whenever `onAction` is bound.
- **Flutter:** Composite widget.
- **Packages:** intl, Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

#### StockTicker

*Playground · Domain · size M · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/domain.ts`*

> Stock quote header: symbol, name, price, change and % change, sparkline, key stats. sample:true labels illustrative data.

**Required:** `price`, `symbol`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `symbol` **(required)** | string |  |  |
| `name` | string |  |  |
| `price` **(required)** | number |  |  |
| `change` | number |  |  |
| `changePct` | number |  |  |
| `currency` | string |  |  |
| `series` | number[] |  |  |
| `stats` | {label: string, value: string}[] |  |  |
| `sample` | boolean |  |  |

- **React:** Symbol tile (>= 300px), symbol, name, "Sample data" badge; price 30px currency with exactly 2 decimals; change "+1.23 (+0.45%)" coloured; hand-drawn SVG sparkline (viewBox 320×72, straight segments, dashed baseline at the first value, area gradient, non-scaling stroke), no tooltip; stats grid minmax(150px).
- **Flutter:** Composite widget + `CustomPaint` sparkline (straight segments, unlike Sparkline).
- **Packages:** intl

#### RecipeCard

*Playground · Domain · size M · phase 5 · definition `examples/showcases/a2ui-playground/src/a2ui/catalog/definitions/domain.ts`*

> Recipe: title, time/servings/difficulty, ingredient checklist and numbered steps. Use for any recipe or cooking how-to.

**Required:** `ingredients`, `steps`, `title`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` **(required)** | string |  |  |
| `image` | string |  |  |
| `time` | string |  |  |
| `servings` | number |  |  |
| `difficulty` | string |  |  |
| `ingredients` **(required)** | string[] |  |  |
| `steps` **(required)** | string[] |  |  |
| `tags` | string[] |  |  |

- **React:** Optional 160px image; title; meta chips (time, servings, difficulty), tag chips; two columns from 520px; ingredients checklist (Radix checkboxes, local state only) with done/total and a 3px progress bar; numbered steps.
- **Flutter:** Composite widget; checklist state kept locally (as React), keyed by node id so it survives rebuilds.
- **Packages:** Lucide (`lucideImport` with `LucideRelease.playground`; not a dependency)

### Blueprint (internal, not in the catalog)

Blueprint is not in `catalog.json`: the playground's agent emits `{component: "Blueprint", of, h, state, hideName}` while a component's props stream, and for fixed-template slots. It renders a frame (`h`, else the slot of `of`, 72px when `of` is missing or an id, and at least 28px) whose caption is `of` with one leading `#` removed. `hideName` draws the frame with no caption. The replay fixtures contain it.

It ships as an opt-in extra component (`includeBlueprint: true`), outside the exported schema, so the
replays and any playground agent stream render the way the playground does. It is off by default, because a strict
client refuses a name its catalog does not declare. The gallery and the recorded replays pass `includeBlueprint: true`.
