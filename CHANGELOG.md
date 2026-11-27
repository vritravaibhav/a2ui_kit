## Unreleased

- Agenda, Timeline, ComparisonTable, Progress, Rating, EntityCard and
  FollowUp draw. 60 of the catalog's 121 components render; the other 61
  validate and draw nothing yet.
- Blueprint, the playground agent's stand-in while a component's props are
  still streaming, draws when `A2uiKitOptions.includeBlueprint` is set. It
  stays out of the exported catalog.

## 0.1.0

The first release: 53 of the catalog's 121 components draw, and the other 68
validate and draw nothing yet.

- The playground catalog (`a2uiKitCatalog`) and the standard catalog
  (`a2uiKitStandardCatalog`): all 121 components and 16 functions with
  CopilotKit's exported JSON Schemas, generated from `catalog.json`. Typed
  props views and enums for every component.
- The catalog documents for agents (`a2uiKitCatalogDocument`,
  `a2uiKitInferenceCatalogDocument`) and `a2uiKitCatalogPrompt`.
- Layout: Box, Column, Row, Grid, GridItem, Card, Flow, FlowItem, Section,
  Spacer and Divider, on a CSS flexbox and a CSS grid layout, so containers
  shrink, wrap, gap and stretch as they do in the browser.
- Text: Title, Heading, Text, Caption, Label, Bold, Italic, Underline,
  Strikethrough, Badge, Blockquote, Code, Markdown, Math (TeX typeset as
  KaTeX typesets it, inline and as display blocks, with environments,
  equation tags and KaTeX's error display) and Link. A Text's inline
  children continue its line.
- Data: Table, TableSection, TableRow and TableCell, laid out as Chromium
  lays out an HTML table (column sizing, spans, fixed layout, collapsed
  dividers, a sticky header) and read by screen readers as a table; List,
  ListItem, KeyValueList, Stat and StatGroup.
- Charts: the playground's LineChart, AreaChart, BarChart, PieChart,
  ScatterChart and Sparkline, and CopilotKit's standard Chart (bar, line,
  area, scatter, pie, donut), with tooltips and crosshairs for the pointer,
  a tap and the arrow keys, and a table of the data for screen readers.
- Forms: Form, TextField, Select, CheckBox, RadioGroup and Button, with
  write-back of input values, `checks`, Form validation and submission, and
  event arguments (`writableProps`, `eventArguments`).
- Media and notices: Image, Icon (Lucide, drawn from lucide-react's own icon
  nodes), Svg (paths, circles, rects, lines and text with a viewBox), Alert
  and Callout.
- All 16 functions, `calc` and `series` included; the formatters,
  `pluralize`, `and`, `or`, `not` and `formatString` are ports of
  CopilotKit's, with its test vectors.
- `A2uiOperationValidator` (operations CopilotKit refuses),
  `A2uiIdNormalizer` (component ids that are not identifiers) and
  `A2uiUserOwnedData` (what the user typed stays when the agent writes the
  same data again).
- The "Couldn’t display this part" fallback for invalid props, a component
  that throws, a cyclic reference and an unknown type.
- `A2uiKitTheme`: the playground's look and CopilotKit's library look, light
  and dark, with colour, radius, shadow and type tokens, and
  `A2uiKitTheme.fromColorScheme` for Material apps.
- `tool/check_upstream.dart` reports drift from the live playground catalog.
