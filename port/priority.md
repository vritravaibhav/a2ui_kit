# Port order by priority

The user's order (2026-11-19, go-ahead 2026-11-21): the remaining components are ported tier by tier, ranked by what
the Abhyas AI tutor needs on a student's board (JEE, NEET, UPSC, SSC). After each tier the work stops and the user
looks at the components before the next tier starts (`port/RULEBOOK.md` section 7, "Order and stopping rule").

| Tier | Components | Why |
|---|---|---|
| 1. Explaining a doubt (14) | Math, Bold, Italic, Underline, Strikethrough, Code, Table, TableSection, TableRow, TableCell, Svg, Flow, FlowItem, Blockquote | formulas, styled text, comparison tables, diagrams, step-by-step derivations, quoted definitions |
| 2. Practice and checking (11) | ChoicePicker, Radio, TextArea, FlashcardFlip, Accordion, Tabs, Tooltip, Popover, PopoverTrigger, PopoverContent, Slider | multiple-choice questions, written answers, flashcards, hints and answers, methods side by side, definitions on tap, trying values in a formula |
| 3. Subject content (14) | Citation, Gauge, Heatmap, RadarChart, Treemap, SankeyChart, Map, MapView, LocationCard, PlaceList, RouteMap, VideoEmbed, ImageGallery, ImageGrid | sources, more charts on the chart foundation, maps (wait on the user's tile source), lesson video |
| 4. General interface (24) | CodeBlock, Kbd, ShimmerText, Skeleton, EmptyState, CarouselMediaItem, SegmentedControl, ButtonGroup, ChipSelect, Switch, Pressable, Combobox, Modal, DatePicker, DateTimeInput, Avatar, AvatarGroup, RadialProgress, LinkCard, Favicon, AudioPlayer, Video, HtmlView, DataTable | loading states, menus, pickers, cards |
| 5. Last (7) | EventCard, ProfileCard, ReceiptCard, RecipeCard, StockTicker, WeatherCard, CandlestickChart | business demo cards |

Already built (39), not yet signed off: phase 1's 32 (their fix round and reviews still to come) and the 7 charts
(four fix rounds; the last, e987134c, verified; no further review round unless the user asks). Agenda, Timeline,
ComparisonTable, Progress, Rating, FollowUp, EntityCard, TagList, Quote,
PulseIndicator, Carousel and CarouselItem are built too. Blueprint is built and stays opt-in
(`includeBlueprint`); it is not one of the 121.
