import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/components/playground/charts/area_chart.dart';
import 'package:a2ui_kit/src/components/playground/charts/bar_chart.dart';
import 'package:a2ui_kit/src/components/playground/charts/line_chart.dart';
import 'package:a2ui_kit/src/components/playground/charts/pie_chart.dart';
import 'package:a2ui_kit/src/components/playground/charts/scatter_chart.dart';
import 'package:a2ui_kit/src/components/playground/charts/sparkline.dart';
import 'package:a2ui_kit/src/components/playground/content/heading.dart';
import 'package:a2ui_kit/src/components/playground/content/quote.dart';
import 'package:a2ui_kit/src/components/playground/data_display/agenda.dart';
import 'package:a2ui_kit/src/components/playground/data_display/comparison_table.dart';
import 'package:a2ui_kit/src/components/playground/data_display/key_value_list.dart';
import 'package:a2ui_kit/src/components/playground/data_display/progress.dart';
import 'package:a2ui_kit/src/components/playground/data_display/rating.dart';
import 'package:a2ui_kit/src/components/playground/data_display/stat.dart';
import 'package:a2ui_kit/src/components/playground/data_display/tag_list.dart';
import 'package:a2ui_kit/src/components/playground/data_display/timeline.dart';
import 'package:a2ui_kit/src/components/playground/feedback/alert_callout.dart';
import 'package:a2ui_kit/src/components/playground/layout/section.dart';
import 'package:a2ui_kit/src/components/standard/composites/entity_card.dart';
import 'package:a2ui_kit/src/components/standard/composites/follow_up.dart';
import 'package:a2ui_kit/src/components/standard/data/chart.dart';
import 'package:a2ui_kit/src/components/standard/data/list.dart';
import 'package:a2ui_kit/src/components/standard/data/table.dart';
import 'package:a2ui_kit/src/components/standard/feedback/pulse_indicator.dart';
import 'package:a2ui_kit/src/components/standard/inputs/button.dart';
import 'package:a2ui_kit/src/components/standard/inputs/choices.dart';
import 'package:a2ui_kit/src/components/standard/inputs/form.dart';
import 'package:a2ui_kit/src/components/standard/inputs/select.dart';
import 'package:a2ui_kit/src/components/standard/inputs/text_field.dart';
import 'package:a2ui_kit/src/components/standard/layout/carousel.dart';
import 'package:a2ui_kit/src/components/standard/layout/containers.dart';
import 'package:a2ui_kit/src/components/standard/layout/flow.dart';
import 'package:a2ui_kit/src/components/standard/layout/grid.dart';
import 'package:a2ui_kit/src/components/standard/layout/spacer_divider.dart';
import 'package:a2ui_kit/src/components/standard/media/icon.dart';
import 'package:a2ui_kit/src/components/standard/media/image.dart';
import 'package:a2ui_kit/src/components/standard/media/svg.dart';
import 'package:a2ui_kit/src/components/standard/text/blockquote.dart';
import 'package:a2ui_kit/src/components/standard/text/bold.dart';
import 'package:a2ui_kit/src/components/standard/text/code.dart';
import 'package:a2ui_kit/src/components/standard/text/italic.dart';
import 'package:a2ui_kit/src/components/standard/text/link.dart';
import 'package:a2ui_kit/src/components/standard/text/markdown.dart';
import 'package:a2ui_kit/src/components/standard/text/math.dart';
import 'package:a2ui_kit/src/components/standard/text/strikethrough.dart';
import 'package:a2ui_kit/src/components/standard/text/text_components.dart';
import 'package:a2ui_kit/src/components/standard/text/underline.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:flutter/widgets.dart';

/// The builders a2ui_kit has, by component name.
const Map<String, ComponentWidgetBuilder> kitBuilders = {
  // Standard: layout.
  'Box': buildBox,
  'Column': buildColumn,
  'Row': buildRow,
  'Grid': buildGrid,
  'GridItem': buildGridItem,
  'Card': buildCard,
  'Flow': buildFlow,
  'FlowItem': buildFlowItem,
  'Spacer': buildSpacer,
  'Divider': buildDivider,
  'Carousel': buildCarousel,
  'CarouselItem': buildCarouselItem,
  // Standard: text.
  'Title': buildTitle,
  'Text': buildText,
  'Caption': buildCaption,
  'Label': buildLabel,
  'Bold': buildBold,
  'Italic': buildItalic,
  'Underline': buildUnderline,
  'Strikethrough': buildStrikethrough,
  'Badge': buildBadge,
  'Blockquote': buildBlockquote,
  'Code': buildCode,
  'Markdown': buildMarkdown,
  'Math': buildMath,
  'Link': buildLink,
  // Standard: inputs.
  'Button': buildButton,
  'Form': buildForm,
  'TextField': buildTextField,
  'Select': buildSelect,
  'CheckBox': buildCheckBox,
  'RadioGroup': buildRadioGroup,
  // Standard: data and media.
  'Table': buildTable,
  'TableSection': buildTableSection,
  'TableRow': buildTableRow,
  'TableCell': buildTableCell,
  'List': buildList,
  'ListItem': buildListItem,
  'Chart': buildChart,
  'Image': buildImage,
  'Icon': buildIcon,
  'Svg': buildSvg,
  // Standard: composites and feedback.
  'FollowUp': buildFollowUp,
  'EntityCard': buildEntityCard,
  'PulseIndicator': buildPulseIndicator,
  // Playground.
  'Section': buildSection,
  'Heading': buildHeading,
  'Quote': buildQuote,
  'Stat': buildStat,
  'StatGroup': buildStatGroup,
  'KeyValueList': buildKeyValueList,
  'Agenda': buildAgenda,
  'Timeline': buildTimeline,
  'ComparisonTable': buildComparisonTable,
  'Progress': buildProgress,
  'Rating': buildRating,
  'TagList': buildTagList,
  'Alert': buildAlert,
  'Callout': buildCallout,
  // Playground: charts.
  'LineChart': buildLineChart,
  'AreaChart': buildAreaChart,
  'BarChart': buildBarChart,
  'PieChart': buildPieChart,
  'ScatterChart': buildScatterChart,
  'Sparkline': buildSparkline,
};

/// The builder of a component this version does not render yet: it draws
/// nothing, like a pending node, so the rest of the surface still lays
/// out.
Widget buildNotYetPorted(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) => const SizedBox.shrink();

// PORT STATUS: confidence=high todos=0 upstream=none
