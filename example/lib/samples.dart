// The playground's component previews (a2ui.open.bot and samples/*.ts),
// for the components this version draws. A part that only renders inside
// its parent (GridItem, TableRow, ListItem) uses the preview its page shows.
// The menu lists them by name.

import 'dart:collection';

import 'package:a2ui_kit/a2ui_kit.dart';

/// One gallery entry: the surface and, when props bind into it, the data.
class GallerySample {
  /// A surface of [components], optionally seeded with [data].
  GallerySample(this.components, {this.data});

  /// The component messages, root id `root`.
  final List<Map<String, Object?>> components;

  /// The data model, for `{"@path": "/..."}` props.
  final Map<String, Object?>? data;
}

/// The incidents table shared by TableSection, TableRow and TableCell.
final List<Map<String, Object?>> _incidents = [
  {
    'id': 'root',
    'component': 'Table',
    'caption': 'Open incidents',
    'children': ['head', 'body'],
  },
  {
    'id': 'head',
    'component': 'TableSection',
    'header': true,
    'children': ['head_row'],
  },
  {
    'id': 'head_row',
    'component': 'TableRow',
    'children': ['h1', 'h2'],
  },
  {'id': 'h1', 'component': 'TableCell', 'header': true, 'text': 'Service'},
  {'id': 'h2', 'component': 'TableCell', 'header': true, 'text': 'Status'},
  {
    'id': 'body',
    'component': 'TableSection',
    'children': ['r1', 'r2'],
  },
  {
    'id': 'r1',
    'component': 'TableRow',
    'children': ['r1a', 'r1b'],
  },
  {'id': 'r1a', 'component': 'TableCell', 'text': 'Search'},
  {
    'id': 'r1b',
    'component': 'TableCell',
    'children': ['r1b_badge'],
  },
  {
    'id': 'r1b_badge',
    'component': 'Badge',
    'label': 'Degraded',
    'color': 'warning',
  },
  {
    'id': 'r2',
    'component': 'TableRow',
    'children': ['r2a', 'r2b'],
  },
  {'id': 'r2a', 'component': 'TableCell', 'text': 'Billing'},
  {
    'id': 'r2b',
    'component': 'TableCell',
    'children': ['r2b_badge'],
  },
  {
    'id': 'r2b_badge',
    'component': 'Badge',
    'label': 'Resolved',
    'color': 'success',
  },
];

/// The release-highlights carousel shared by Carousel and CarouselItem.
final List<Map<String, Object?>> _carousel = [
  {
    'id': 'root',
    'component': 'Carousel',
    'label': 'Release highlights',
    'visibleItems': 2,
    'children': ['s1', 's2', 's3'],
  },
  {
    'id': 's1',
    'component': 'CarouselItem',
    'children': ['s1_t', 's1_c'],
  },
  {'id': 's1_t', 'component': 'Title', 'text': 'Faster deploys'},
  {
    'id': 's1_c',
    'component': 'Caption',
    'text': 'Builds start in under ten seconds.',
  },
  {
    'id': 's2',
    'component': 'CarouselItem',
    'children': ['s2_t', 's2_c'],
  },
  {'id': 's2_t', 'component': 'Title', 'text': 'Audit log'},
  {
    'id': 's2_c',
    'component': 'Caption',
    'text': 'Every change, who made it and when.',
  },
  {
    'id': 's3',
    'component': 'CarouselItem',
    'children': ['s3_t', 's3_c'],
  },
  {'id': 's3_t', 'component': 'Title', 'text': 'Usage alerts'},
  {
    'id': 's3_c',
    'component': 'Caption',
    'text': 'A heads-up before you reach a limit.',
  },
];

/// One plan card for [_carouselCards]: a fixed-width Card with icon, badge,
/// copy and a CTA.
List<Map<String, Object?>> _carouselCard({
  required String id,
  required String icon,
  required String badge,
  required String badgeColor,
  required String title,
  required String caption,
  required String price,
  required String cta,
}) => [
  {
    'id': id,
    'component': 'CarouselItem',
    'width': 56,
    'children': ['${id}_card'],
  },
  {
    'id': '${id}_card',
    'component': 'Card',
    'variant': 'outline',
    'padding': 4,
    'gap': 3,
    'children': [
      '${id}_head',
      '${id}_title',
      '${id}_caption',
      '${id}_price',
      '${id}_cta',
    ],
  },
  {
    'id': '${id}_head',
    'component': 'Row',
    'align': 'center',
    'justify': 'spaceBetween',
    'children': ['${id}_icon', '${id}_badge'],
  },
  {
    'id': '${id}_icon',
    'component': 'Icon',
    'name': icon,
    'size': 'lg',
    'label': title,
  },
  {
    'id': '${id}_badge',
    'component': 'Badge',
    'label': badge,
    'color': badgeColor,
  },
  {'id': '${id}_title', 'component': 'Title', 'text': title},
  {'id': '${id}_caption', 'component': 'Caption', 'text': caption},
  {
    'id': '${id}_price',
    'component': 'Text',
    'text': price,
    'fontWeight': 'semibold',
  },
  {
    'id': '${id}_cta',
    'component': 'Button',
    'label': cta,
    'variant': 'primary',
    'block': true,
  },
];

/// A denser carousel of plan cards, for the gallery's second Carousel entry.
final List<Map<String, Object?>> _carouselCards = [
  {
    'id': 'root',
    'component': 'Carousel',
    'label': 'Plans',
    'children': ['starter', 'pro', 'team', 'enterprise'],
  },
  ..._carouselCard(
    id: 'starter',
    icon: 'zap',
    badge: 'Free',
    badgeColor: 'secondary',
    title: 'Starter',
    caption: 'One project, community support, and the shared runner pool.',
    price: r'$0 / mo',
    cta: 'Start free',
  ),
  ..._carouselCard(
    id: 'pro',
    icon: 'rocket',
    badge: 'Popular',
    badgeColor: 'info',
    title: 'Pro',
    caption: 'Unlimited projects, audit log, and usage alerts before a limit.',
    price: r'$24 / seat',
    cta: 'Upgrade',
  ),
  ..._carouselCard(
    id: 'team',
    icon: 'users',
    badge: 'Teams',
    badgeColor: 'success',
    title: 'Team',
    caption: 'SSO, shared drafts, and a dedicated success manager.',
    price: r'$48 / seat',
    cta: 'Talk to sales',
  ),
  ..._carouselCard(
    id: 'enterprise',
    icon: 'building-2',
    badge: 'Custom',
    badgeColor: 'warning',
    title: 'Enterprise',
    caption: 'VPC deploy, custom SLAs, and a named solutions architect.',
    price: 'Contact us',
    cta: 'Book a call',
  ),
];

/// The sample surfaces of the gallery, listed by name.
final Map<String, GallerySample> gallerySamples = SplayTreeMap.of({
  // Layout.
  'Section': GallerySample([
    {
      'id': 'root',
      'component': 'Section',
      'eyebrow': 'Overview',
      'title': 'This week',
      'description': 'Activity across your workspace.',
      'children': ['g'],
    },
    {
      'id': 'g',
      'component': 'Row',
      'wrap': 'wrap',
      'children': ['a', 'b'],
    },
    {'id': 'a', 'component': 'Stat', 'label': 'Commits', 'value': '342'},
    {'id': 'b', 'component': 'Stat', 'label': 'PRs merged', 'value': '57'},
  ]),
  // Content.
  'Heading': GallerySample([
    {
      'id': 'root',
      'component': 'Heading',
      'eyebrow': 'Trip plan',
      'text': 'Three days in Tokyo',
      'subtitle':
          'Food markets, quiet temples and one very late night in Shinjuku.',
    },
  ]),
  'Quote': GallerySample([
    {
      'id': 'root',
      'component': 'Quote',
      'text': 'The best interface is the one that shows up already filled in.',
      'author': 'Maya Chen',
      'role': 'Head of Design, Lattice',
    },
  ]),
  // Data display.
  'Agenda': GallerySample([
    {
      'id': 'root',
      'component': 'Agenda',
      'title': 'This week',
      'days': [
        {
          'date': '2026-10-15',
          'label': 'Today',
          'events': [
            {
              'time': '9:30 AM',
              'title': 'Design review: billing page',
              'location': 'Room 4B',
              'tone': 'accent',
            },
            {
              'time': '1:00 PM',
              'title': 'Lunch with Priya',
              'location': 'Tartine, Mission St',
              'tone': 'positive',
            },
            {
              'time': '4:30 PM',
              'title': 'Incident retro',
              'location': 'Zoom',
              'tone': 'warning',
            },
          ],
        },
        {
          'date': '2026-10-16',
          'events': [
            {
              'time': '10:00 AM',
              'title': 'Q4 planning',
              'location': 'Main conference room',
              'tone': 'info',
            },
            {'time': '3:00 PM', 'title': '1:1 with Leo', 'tone': 'accent'},
          ],
        },
        {'date': '2026-10-17', 'events': <Object?>[]},
      ],
    },
  ]),
  'Timeline': GallerySample([
    {
      'id': 'root',
      'component': 'Timeline',
      'items': [
        {
          'title': 'Order confirmed',
          'time': 'Oct 14, 9:42 AM',
          'status': 'done',
        },
        {
          'title': 'Packed at Reno warehouse',
          'time': 'Oct 14, 4:10 PM',
          'description': '3 items in one box, 2.4 kg.',
          'status': 'done',
        },
        {
          'title': 'In transit',
          'time': 'Oct 15, 7:05 AM',
          'description': 'Left the Sacramento hub, next stop Oakland.',
          'status': 'current',
          'icon': 'truck',
        },
        {
          'title': 'Out for delivery',
          'time': 'Est. Oct 16',
          'status': 'upcoming',
        },
        {'title': 'Delivered', 'status': 'upcoming'},
      ],
    },
  ]),
  'ComparisonTable': GallerySample([
    {
      'id': 'root',
      'component': 'ComparisonTable',
      'title': 'Pick a plan',
      'options': ['Starter', 'Pro', 'Enterprise'],
      'highlight': 1,
      'rows': [
        {
          'feature': 'Price per seat',
          'values': <Object?>[r'$0', r'$24/mo', 'Custom'],
        },
        {
          'feature': 'Projects',
          'values': <Object?>[3, 'Unlimited', 'Unlimited'],
        },
        {
          'feature': 'SSO and SAML',
          'values': <Object?>[false, true, true],
        },
        {
          'feature': 'Audit log',
          'values': <Object?>[false, true, true],
        },
        {
          'feature': 'Dedicated support',
          'values': <Object?>[false, false, true],
        },
        {
          'feature': 'Uptime SLA',
          'values': <Object?>['', '99.9%', '99.99%'],
        },
      ],
    },
  ]),
  'Progress': GallerySample([
    {
      'id': 'root',
      'component': 'Progress',
      'label': 'Storage used',
      'value': 72,
      'caption': '72 GB of 100 GB, resets Nov 1',
      'tone': 'accent',
    },
  ]),
  'Rating': GallerySample([
    {
      'id': 'root',
      'component': 'Rating',
      'value': 4.6,
      'count': 1284,
      'label': 'Customer rating',
    },
  ]),
  // Official docs sample (a2ui-playground …/components/TagList).
  'TagList': GallerySample([
    {
      'id': 'root',
      'component': 'TagList',
      'tags': [
        'TypeScript',
        'React 19',
        'Edge runtime',
        'Postgres',
        'OpenTelemetry',
        'Tailwind',
        'pnpm',
      ],
    },
  ]),
  'StatGroup': GallerySample([
    {
      'id': 'root',
      'component': 'StatGroup',
      'items': [
        {'label': 'Visitors', 'value': '84,210', 'delta': '+8.1%'},
        {'label': 'Signups', 'value': 2318, 'delta': '+14.6%'},
        {
          'label': 'Conversion',
          'value': '2.75%',
          'delta': '-0.3%',
          'trend': 'down',
        },
        {
          'label': 'Avg. session',
          'value': '4m 12s',
          'delta': '0.0%',
          'trend': 'flat',
        },
      ],
    },
  ]),
  'KeyValueList': GallerySample([
    {
      'id': 'root',
      'component': 'KeyValueList',
      'title': 'Order #A-20481',
      'items': [
        {'label': 'Placed', 'value': 'Oct 14, 2026', 'hint': '9:42 AM PT'},
        {'label': 'Items', 'value': 3},
        {'label': 'Shipping', 'value': 'Express, 2 days'},
        {'label': 'Subtotal', 'value': r'$218.00'},
        {'label': 'Total', 'value': r'$236.40', 'hint': r'Incl. $18.40 tax'},
      ],
    },
  ]),
  'Stat': GallerySample([
    {
      'id': 'root',
      'component': 'Stat',
      'label': 'Monthly recurring revenue',
      'value': r'$48.2k',
      'delta': '+12.4%',
      'caption': 'vs. September, 1,284 active accounts',
      'icon': 'trending-up',
      'tone': 'default',
    },
  ]),
  // Charts.
  'LineChart': GallerySample([
    {
      'id': 'root',
      'component': 'LineChart',
      'title': 'Weekly active users',
      'subtitle': 'Web vs mobile, last 12 months',
      'format': 'compact',
      'data': [
        ..._series('Web', [
          18200, 19400, 21100, 20800, 23900, 26400, //
          25800, 28900, 31200, 33800, 35100, 38400,
        ]),
        ..._series('Mobile', [
          9800, 10900, 12600, 14100, 15900, 17200, //
          19800, 21400, 24100, 26900, 29300, 32600,
        ]),
      ],
    },
  ]),
  'AreaChart': GallerySample([
    {
      'id': 'root',
      'component': 'AreaChart',
      'title': 'Inference spend by workload',
      'subtitle': 'Stacked monthly cost, USD',
      'format': 'currency',
      'stacked': true,
      'data': [
        ..._series('Chat', [
          4200, 4800, 5600, 6100, 7300, 8100, //
          8900, 9400, 10800, 11600, 12900, 14100,
        ]),
        ..._series('Agents', [
          2100, 2600, 3300, 3900, 4400, 5200, //
          6100, 6900, 7400, 8300, 9100, 9800,
        ]),
        ..._series('Embeddings', [
          900, 950, 1100, 1180, 1260, 1400, //
          1520, 1610, 1700, 1820, 1950, 2080,
        ]),
      ],
    },
  ]),
  'BarChart': GallerySample([
    {
      'id': 'root',
      'component': 'BarChart',
      'title': 'Revenue by region',
      'subtitle': 'Quarterly, USD',
      'format': 'currency',
      'data': [
        ..._series(
          '2025',
          [412000, 298000, 186000, 94000],
          ['NA', 'EMEA', 'APAC', 'LATAM'],
        ),
        ..._series(
          '2026',
          [538000, 371000, 262000, 131000],
          ['NA', 'EMEA', 'APAC', 'LATAM'],
        ),
      ],
    },
  ]),
  'PieChart': GallerySample([
    {
      'id': 'root',
      'component': 'PieChart',
      'title': 'Traffic sources',
      'subtitle': 'Sessions, last 30 days',
      'donut': true,
      'centerLabel': 'sessions',
      'format': 'compact',
      'data': [
        {'label': 'Organic search', 'value': 48200},
        {'label': 'Direct', 'value': 27100},
        {'label': 'Referral', 'value': 14600},
        {'label': 'Social', 'value': 9800},
        {'label': 'Email', 'value': 5300},
      ],
    },
  ]),
  'ScatterChart': GallerySample([
    {
      'id': 'root',
      'component': 'ScatterChart',
      'title': 'Latency vs throughput',
      'subtitle': 'Per deployment, bubble size is replica count',
      'xLabel': 'Requests / s',
      'yLabel': 'p95 latency',
      'unit': 'ms',
      'data': [
        for (final (x, y, size, series, label) in const [
          (120, 84, 2, 'us-east', 'api-gateway'),
          (340, 112, 4, 'us-east', 'search'),
          (610, 168, 8, 'us-east', 'checkout'),
          (880, 241, 12, 'us-east', 'catalog'),
          (210, 64, 3, 'eu-west', 'auth'),
          (450, 98, 5, 'eu-west', 'search'),
          (720, 132, 9, 'eu-west', 'checkout'),
          (960, 188, 14, 'eu-west', 'catalog'),
          (300, 142, 2, 'ap-south', 'search'),
          (520, 205, 6, 'ap-south', 'checkout'),
          (690, 262, 7, 'ap-south', 'catalog'),
        ])
          {'x': x, 'y': y, 'size': size, 'series': series, 'label': label},
      ],
    },
  ]),
  'Sparkline': GallerySample([
    {
      'id': 'root',
      'component': 'Sparkline',
      'label': 'Monthly recurring revenue',
      'value': r'$184.2K',
      'delta': '+12.4%',
      'tone': 'positive',
      'values': [
        128, 131, 129, 138, 142, 140, 149, 155, 153, 162, 171, 168, 176, 184, //
      ],
    },
  ]),
  // Feedback.
  'Alert': GallerySample([
    {
      'id': 'root',
      'component': 'Alert',
      'tone': 'warning',
      'title': 'Usage at 92% of plan',
      'message':
          'You will hit the request limit in about 3 days at the current rate.',
    },
  ]),
  'Callout': GallerySample([
    {
      'id': 'root',
      'component': 'Callout',
      'title': 'Tip',
      'text':
          'Fixed-schema surfaces paint as soon as the data lands. '
          'Use them for the requests you see every day.',
      'actionLabel': 'Learn more',
      'onAction': {
        'event': {'name': 'learn_more'},
      },
    },
  ]),
  'PulseIndicator': GallerySample([
    {
      'id': 'root',
      'component': 'Row',
      'gap': 2,
      'align': 'center',
      'children': ['dot', 't'],
    },
    {'id': 'dot', 'component': 'PulseIndicator'},
    {'id': 't', 'component': 'Text', 'text': 'Live: 1,204 visitors now'},
  ]),
  // Standard layout.
  'Box': GallerySample([
    {
      'id': 'root',
      'component': 'Box',
      'gap': 1,
      'children': ['t', 'c'],
    },
    {'id': 't', 'component': 'Title', 'text': 'Box'},
    {
      'id': 'c',
      'component': 'Caption',
      'text': 'A flex column by default. Set direction to "row" for a row.',
    },
  ]),
  'Column': GallerySample([
    {
      'id': 'root',
      'component': 'Column',
      'children': ['t', 'b', 'c'],
    },
    {'id': 't', 'component': 'Title', 'text': 'Weekly summary'},
    {
      'id': 'b',
      'component': 'Text',
      'text': 'Deploys finished **12% faster** than last week.',
    },
    {'id': 'c', 'component': 'Caption', 'text': 'Updated 5 minutes ago'},
  ]),
  'Row': GallerySample([
    {
      'id': 'root',
      'component': 'Row',
      'justify': 'spaceBetween',
      'align': 'center',
      'children': ['k', 'v'],
    },
    {'id': 'k', 'component': 'Caption', 'text': 'Plan'},
    {
      'id': 'v',
      'component': 'Text',
      'text': 'Team, billed yearly',
      'fontWeight': 'semibold',
    },
  ]),
  'Grid': GallerySample([
    {
      'id': 'root',
      'component': 'Grid',
      'columns': 2,
      'gap': 4,
      'children': ['a', 'b', 'c', 'd'],
    },
    ..._stat('a', 'Visitors', '48.2K'),
    ..._stat('b', 'Signups', '1,284'),
    ..._stat('c', 'Trials', '312'),
    ..._stat('d', 'Paid', '96'),
  ]),
  'GridItem': GallerySample([
    {
      'id': 'root',
      'component': 'Grid',
      'columns': 3,
      'gap': 3,
      'children': ['wide', 'narrow'],
    },
    {
      'id': 'wide',
      'component': 'GridItem',
      'span': 2,
      'children': ['wide_t', 'wide_c'],
    },
    {'id': 'wide_t', 'component': 'Title', 'text': 'Pipeline'},
    {
      'id': 'wide_c',
      'component': 'Caption',
      'text': 'Spans two of three columns.',
    },
    {
      'id': 'narrow',
      'component': 'GridItem',
      'children': ['narrow_t', 'narrow_c'],
    },
    {'id': 'narrow_t', 'component': 'Title', 'text': 'Owner'},
    {'id': 'narrow_c', 'component': 'Caption', 'text': 'One column.'},
  ]),
  'Carousel': GallerySample(_carousel),
  'Carousel cards': GallerySample(_carouselCards),
  'CarouselItem': GallerySample(_carousel),
  'Card': GallerySample(
    [
      {
        'id': 'root',
        'component': 'Card',
        'children': ['t', 'c', 'email', 'send'],
      },
      {'id': 't', 'component': 'Title', 'text': 'Invite a teammate'},
      {
        'id': 'c',
        'component': 'Caption',
        'text': 'They get an email with a sign-in link.',
      },
      {
        'id': 'email',
        'component': 'TextField',
        'label': 'Email',
        'variant': 'email',
        'placeholder': 'name@company.com',
        'value': {'@path': '/invite/email'},
      },
      {
        'id': 'send',
        'component': 'Button',
        'label': 'Send invite',
        'variant': 'primary',
      },
    ],
    data: {
      'invite': {'email': ''},
    },
  ),
  'Divider': GallerySample([
    {
      'id': 'root',
      'component': 'Column',
      'children': ['a', 'line', 'b'],
    },
    {'id': 'a', 'component': 'Text', 'text': 'Order #4821 shipped on Monday.'},
    {'id': 'line', 'component': 'Divider'},
    {'id': 'b', 'component': 'Text', 'text': 'Expected delivery: Thursday.'},
  ]),
  // Standard text.
  'Title': GallerySample([
    {
      'id': 'root',
      'component': 'Title',
      'text': 'Quarterly review',
      'size': 'xl',
    },
  ]),
  'Text': GallerySample([
    {
      'id': 'root',
      'component': 'Text',
      'text':
          'Deploys finished **12% faster** this week, '
          'and no release was rolled back.',
    },
  ]),
  'Caption': GallerySample([
    {'id': 'root', 'component': 'Caption', 'text': 'Updated 5 minutes ago'},
  ]),
  'Label': GallerySample([
    {'id': 'root', 'component': 'Label', 'text': 'Email address'},
  ]),
  'Bold': GallerySample([
    {'id': 'root', 'component': 'Bold', 'text': 'Ships on Friday'},
  ]),
  'Italic': GallerySample([
    {'id': 'root', 'component': 'Italic', 'text': 'Draft, not reviewed yet'},
  ]),
  'Underline': GallerySample([
    {'id': 'root', 'component': 'Underline', 'text': 'Read before you sign'},
  ]),
  'Strikethrough': GallerySample([
    {'id': 'root', 'component': 'Strikethrough', 'text': r'$49 per month'},
  ]),
  'Badge': GallerySample([
    {
      'id': 'root',
      'component': 'Row',
      'gap': 2,
      'children': ['a', 'b', 'c'],
    },
    {'id': 'a', 'component': 'Badge', 'label': 'Active', 'color': 'success'},
    {'id': 'b', 'component': 'Badge', 'label': 'Pending', 'color': 'warning'},
    {'id': 'c', 'component': 'Badge', 'label': 'Failed', 'color': 'danger'},
  ]),
  'Blockquote': GallerySample([
    {
      'id': 'root',
      'component': 'Blockquote',
      'text': 'Ship small changes often, and **measure** each one.',
    },
  ]),
  'Code': GallerySample([
    {
      'id': 'root',
      'component': 'Code',
      'language': 'ts',
      'text':
          'const total = items.reduce((sum, item) => sum + item.price, 0);\n'
          r'console.log(`Total: ${total}`);',
    },
  ]),
  'Markdown': GallerySample([
    {
      'id': 'root',
      'component': 'Markdown',
      'text':
          '**Next steps**\n\n'
          '1. Confirm the venue\n'
          '2. Send the invites\n'
          '3. Book travel by *Friday*',
    },
  ]),
  'Math': GallerySample([
    {
      'id': 'root',
      'component': 'Math',
      'value': r'\bar{x} = \frac{1}{n} \sum_{i=1}^{n} x_i',
      'block': true,
    },
  ]),
  'Link': GallerySample([
    {
      'id': 'root',
      'component': 'Link',
      'text': 'Read the standard catalog docs',
      'href':
          'https://docs.copilotkit.ai/generative-ui/components/standard-catalog',
    },
  ]),
  // Standard inputs.
  'Button': GallerySample([
    {
      'id': 'root',
      'component': 'Row',
      'gap': 2,
      'children': ['cancel', 'save'],
    },
    {'id': 'cancel', 'component': 'Button', 'label': 'Cancel'},
    {
      'id': 'save',
      'component': 'Button',
      'label': 'Save changes',
      'variant': 'primary',
    },
  ]),
  'Form': GallerySample(
    [
      {
        'id': 'root',
        'component': 'Form',
        'label': 'Newsletter',
        'children': ['email', 'submit'],
      },
      {
        'id': 'email',
        'component': 'TextField',
        'label': 'Email',
        'variant': 'email',
        'placeholder': 'name@company.com',
        'value': {'@path': '/form/email'},
      },
      {
        'id': 'submit',
        'component': 'Button',
        'label': 'Subscribe',
        'variant': 'primary',
        'submit': true,
      },
    ],
    data: {
      'form': {'email': ''},
    },
  ),
  'TextField': GallerySample(
    [
      {
        'id': 'root',
        'component': 'TextField',
        'label': 'Work email',
        'variant': 'email',
        'placeholder': 'name@company.com',
        'value': {'@path': '/form/email'},
      },
    ],
    data: {
      'form': {'email': ''},
    },
  ),
  'Select': GallerySample(
    [
      {
        'id': 'root',
        'component': 'Select',
        'label': 'Region',
        'value': {'@path': '/form/region'},
        'options': [
          {'value': 'us', 'label': 'United States'},
          {'value': 'eu', 'label': 'Europe'},
          {'value': 'apac', 'label': 'Asia Pacific'},
        ],
      },
    ],
    data: {
      'form': {'region': 'eu'},
    },
  ),
  'CheckBox': GallerySample(
    [
      {
        'id': 'root',
        'component': 'CheckBox',
        'label': 'Email me a weekly summary',
        'value': {'@path': '/form/digest'},
      },
    ],
    data: {
      'form': {'digest': true},
    },
  ),
  'RadioGroup': GallerySample(
    [
      {
        'id': 'root',
        'component': 'RadioGroup',
        'label': 'Plan',
        'direction': 'col',
        'value': {'@path': '/form/plan'},
        'options': [
          {'value': 'free', 'label': 'Free'},
          {'value': 'team', 'label': 'Team', 'description': 'Up to 30 seats'},
          {'value': 'enterprise', 'label': 'Enterprise'},
        ],
      },
    ],
    data: {
      'form': {'plan': 'team'},
    },
  ),
  // Standard data and media.
  'Table': GallerySample([
    {
      'id': 'root',
      'component': 'Table',
      'caption': 'Top pages',
      'columns': [
        'Page',
        {'label': 'Views', 'align': 'end'},
        {'label': 'Bounce', 'align': 'end'},
      ],
      'rows': [
        <Object?>['/pricing', 18420, '31%'],
        <Object?>['/docs/quickstart', 12950, '24%'],
        <Object?>['/blog/launch', 9310, '47%'],
      ],
    },
  ]),
  'TableSection': GallerySample(_incidents),
  'TableRow': GallerySample(_incidents),
  'TableCell': GallerySample(_incidents),
  'List': GallerySample([
    {
      'id': 'root',
      'component': 'List',
      'marker': 'number',
      'items': [
        'Connect your repository',
        'Pick a framework preset',
        'Deploy the main branch',
      ],
    },
  ]),
  'ListItem': GallerySample([
    {
      'id': 'root',
      'component': 'List',
      'marker': 'none',
      'children': ['i1', 'i2', 'i3'],
    },
    {
      'id': 'i1',
      'component': 'ListItem',
      'icon': 'users',
      'label': 'Seats',
      'value': '24 of 30',
    },
    {
      'id': 'i2',
      'component': 'ListItem',
      'icon': 'hard-drive',
      'label': 'Storage',
      'value': '61 GB',
    },
    {
      'id': 'i3',
      'component': 'ListItem',
      'icon': 'calendar',
      'label': 'Renews',
      'value': 'Dec 1',
    },
  ]),
  'Chart': GallerySample([
    {
      'id': 'root',
      'component': 'Chart',
      'chartType': 'bar',
      'title': 'Signups by week',
      'xKey': 'week',
      'series': [
        {'key': 'signups', 'label': 'Signups'},
      ],
      'data': [
        {'week': 'W1', 'signups': 120},
        {'week': 'W2', 'signups': 164},
        {'week': 'W3', 'signups': 151},
        {'week': 'W4', 'signups': 208},
      ],
    },
  ]),
  'Icon': GallerySample([
    {
      'id': 'root',
      'component': 'Row',
      'gap': 4,
      'align': 'center',
      'children': ['a', 'b', 'c', 'd'],
    },
    {
      'id': 'a',
      'component': 'Icon',
      'name': 'rocket',
      'size': 'lg',
      'label': 'Launch',
    },
    {
      'id': 'b',
      'component': 'Icon',
      'name': 'calendar',
      'size': 'lg',
      'label': 'Calendar',
    },
    {
      'id': 'c',
      'component': 'Icon',
      'name': 'map-pin',
      'size': 'lg',
      'label': 'Location',
    },
    {
      'id': 'd',
      'component': 'Icon',
      'name': 'bell',
      'size': 'lg',
      'label': 'Alerts',
    },
  ]),
  'Svg': GallerySample([
    {
      'id': 'root',
      'component': 'Svg',
      'label': 'A sun over two hills',
      'viewBox': '0 0 120 60',
      'size': 180,
      'circles': [
        {'cx': 88, 'cy': 20, 'r': 10, 'fill': 'warning'},
      ],
      'paths': [
        {'d': 'M0 60 Q30 20 60 60 Z', 'fill': 'success'},
        {'d': 'M40 60 Q75 28 120 60 Z', 'fill': 'info'},
      ],
    },
  ]),
  'FollowUp': GallerySample([
    {
      'id': 'root',
      'component': 'FollowUp',
      'title': 'Try next',
      'items': [
        'Compare with last quarter',
        'Break down by region',
        'Export as CSV',
      ],
    },
  ]),
  // Official macro samples, already expanded into standard components.
  'FlightCard': GallerySample(expandMacroSample('FlightCard')),
  'WeatherReport': GallerySample(expandMacroSample('WeatherReport')),
  'EntityCard': GallerySample([
    {
      'id': 'root',
      'component': 'EntityCard',
      'title': 'Trailhead Daypack 22L',
      'subtitle': 'Backpacks',
      'description':
          'A light pack with a padded laptop sleeve and a rain cover.',
      'meta': r'$89',
      'badge': {'label': 'In stock', 'color': 'success'},
      'rating': 4.6,
      'ratingCount': 312,
    },
  ]),
  // The playground agent's stand-in: a frame sized for the component
  // whose props are still streaming, captioned with the name already
  // written. `#stops` is an id whose type has not arrived.
  'Blueprint': GallerySample([
    {
      'id': 'root',
      'component': 'Column',
      'gap': 3,
      'children': ['title', 'stat', 'chart', 'table', 'pending', 'quiet'],
    },
    {
      'id': 'title',
      'component': 'Blueprint',
      'of': 'Heading',
      'state': 'streaming',
    },
    {
      'id': 'stat',
      'component': 'Blueprint',
      'of': 'Stat',
      'state': 'streaming',
    },
    {
      'id': 'chart',
      'component': 'Blueprint',
      'of': 'BarChart',
      'state': 'streaming',
    },
    {
      'id': 'table',
      'component': 'Blueprint',
      'of': 'DataTable',
      'state': 'streaming',
    },
    {
      'id': 'pending',
      'component': 'Blueprint',
      'of': '#stops',
      'state': 'pending',
    },
    {
      'id': 'quiet',
      'component': 'Blueprint',
      'of': 'WeatherCard',
      'hideName': true,
      'state': 'streaming',
    },
  ]),
});

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// One row per value of the series [name], x from [xs] (the months).
List<Map<String, Object?>> _series(
  String name,
  List<num> values, [
  List<Object> xs = _months,
]) => [
  for (var i = 0; i < values.length; i++)
    {'x': xs[i], 'y': values[i], 'series': name},
];

/// A caption over an xl title, the Grid preview's cells.
List<Map<String, Object?>> _stat(String id, String label, String value) => [
  {
    'id': id,
    'component': 'Column',
    'gap': 1,
    'children': ['${id}_k', '${id}_v'],
  },
  {'id': '${id}_k', 'component': 'Caption', 'text': label},
  {'id': '${id}_v', 'component': 'Title', 'text': value, 'size': 'xl'},
];
