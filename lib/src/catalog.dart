import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/catalog_options.dart';
import 'package:a2ui_kit/src/components/node_guard.dart';
import 'package:a2ui_kit/src/components/playground/blueprint.dart';
import 'package:a2ui_kit/src/components/registry.dart';
import 'package:a2ui_kit/src/document/catalog_document.g.dart';
import 'package:a2ui_kit/src/document/inference_document.g.dart';
import 'package:a2ui_kit/src/foundation/scope.dart';
import 'package:a2ui_kit/src/functions/functions.dart';

/// The id of CopilotKit's A2UI Playground catalog, which every playground
/// surface names in `createSurface`.
const String kA2uiPlaygroundCatalogId =
    'https://copilotkit.ai/a2ui/catalogs/playground/v1';

/// The id of CopilotKit's standard catalog (`standardUI`): the 69 standard
/// components alone.
const String kA2uiStandardCatalogId = 'copilotkit/standard@1';

/// CopilotKit's exported catalog document (`catalog.json`): the render
/// contract of the playground catalog, 121 components and 16 functions.
///
/// Put it in a client's inline catalogs, or hand it to an agent. It is
/// read-only.
final Map<String, Object?> a2uiKitCatalogDocument =
    _frozen(jsonDecode(catalogDocumentJson))! as Map<String, Object?>;

/// CopilotKit's model-facing catalog document (`inference-catalog.json`):
/// the 121 components with their styling props cut and their descriptions
/// shortened, plus the three macros the server expands (FlightCard,
/// ProductCard, WeatherReport). It is read-only.
final Map<String, Object?> a2uiKitInferenceCatalogDocument =
    _frozen(jsonDecode(inferenceDocumentJson))! as Map<String, Object?>;

Object? _frozen(Object? value) => switch (value) {
  final Map<String, Object?> map => Map<String, Object?>.unmodifiable({
    for (final entry in map.entries) entry.key: _frozen(entry.value),
  }),
  final List<Object?> list => List<Object?>.unmodifiable(list.map(_frozen)),
  _ => value,
};

final CatalogApi _playgroundApi = Catalog.fromJson(a2uiKitCatalogDocument);

/// The playground catalog's definitions, without builders: what the schemas
/// say (child references, validation), for the package's own tools.
CatalogApi get playgroundCatalogApi => _playgroundApi;

/// The playground catalog: all 121 components and 16 functions under
/// [kA2uiPlaygroundCatalogId], with the title, description and design
/// instructions of CopilotKit's export.
///
/// Every component and function keeps the exported JSON Schema, so payloads
/// validate exactly as CopilotKit declares them.
///
/// ```dart
/// final processor = MessageProcessor<ComponentImplementation>(
///   catalogs: [a2uiKitCatalog()],
/// );
/// ```
///
/// In this version the 65 components of [a2uiKitPortedComponents] render;
/// the others validate and draw nothing until they are ported. All 16
/// functions run.
///
/// CopilotKit's agents may use component ids that `a2ui_core` rejects
/// (`spacer-l`): pass their messages through an `A2uiIdNormalizer`.
CatalogImplementation a2uiKitCatalog({
  A2uiKitOptions options = const A2uiKitOptions(),
}) {
  final api = _playgroundApi;
  final catalog = CatalogImplementation(
    id: api.id,
    schemaId: api.schemaId,
    title: api.title,
    description: api.description,
    protocolVersion: api.protocolVersion,
    instructions: api.instructions,
    definitions: api.definitions,
    components: [
      for (final component in api.components.values)
        _implement(component, options),
    ],
    functions: kitFunctions(api, options),
  );
  if (!options.includeBlueprint) return catalog;
  return catalog.copyWith(
    components: [
      ...catalog.components.values,
      _implement(
        ComponentApi(name: 'Blueprint', schema: blueprintSchema),
        options,
      ),
    ],
  );
}

/// The standard catalog: the 69 standard components and the 16 functions,
/// with the same schemas, under [kA2uiStandardCatalogId], without the
/// playground's title and instructions (CopilotKit's `standardUI` has
/// none).
CatalogImplementation a2uiKitStandardCatalog({
  A2uiKitOptions options = const A2uiKitOptions(),
}) {
  final api = _playgroundApi;
  return CatalogImplementation(
    id: kA2uiStandardCatalogId,
    protocolVersion: api.protocolVersion,
    definitions: api.definitions,
    components: [
      for (final name in standardComponentNames)
        _implement(api.components[name]!, options),
    ],
    functions: kitFunctions(api, options),
  );
}

ComponentImplementation _implement(ComponentApi api, A2uiKitOptions options) {
  final builder =
      options.overrides[api.name] ??
      kitBuilders[api.name] ??
      (api.name == 'Blueprint' ? buildBlueprint : buildNotYetPorted);
  return ComponentImplementation(
    name: api.name,
    schema: api.schema,
    allowedParents: api.allowedParents,
    allowedChildren: api.allowedChildren,
    builder: (context, node, props, buildChild) {
      // CopilotKit's render check, boundary and fallbacks round every node
      // (node_guard.dart), overrides included.
      final guarded = NodeGuard(
        node: node,
        props: props,
        buildChild: buildChild,
        builder: builder,
      );
      if (context.getInheritedWidgetOfExactType<A2uiKitScope>() != null) {
        return guarded;
      }
      return wrapKitRoot(
        context,
        options,
        guarded,
        block: _blockContainers.contains(api.name),
      );
    },
  );
}

/// The components that hold blocks of an answer, whose pieces a screen
/// reader reads one by one, in order ([wrapKitRoot]).
const Set<String> _blockContainers = {
  'Column',
  'Row',
  'Box',
  'Card',
  'Grid',
  'GridItem',
  'Flow',
  'FlowItem',
  'List',
  'Section',
  'Form',
  'Markdown',
};

/// The names of the components this version renders.
Set<String> get a2uiKitPortedComponents => kitBuilders.keys.toSet();

/// A prompt for a model that writes A2UI for this catalog: CopilotKit's
/// design instructions, then one line per component and function, from the
/// model-facing document.
///
/// With [macros] false, the three macros (which only a server that expands
/// them can accept) are left out.
String a2uiKitCatalogPrompt({bool macros = true}) {
  final document = a2uiKitInferenceCatalogDocument;
  final components = document['components']! as Map<String, Object?>;
  final functions = document['functions']! as Map<String, Object?>;
  final rendered = (a2uiKitCatalogDocument['components']! as Map).keys.toSet();
  final out = StringBuffer();
  final instructions = document['instructions'];
  if (instructions is String && instructions.isNotEmpty) {
    out
      ..writeln(instructions.trim())
      ..writeln();
  }
  out
    ..writeln('## Components')
    ..writeln();
  for (final entry in components.entries) {
    if (!macros && !rendered.contains(entry.key)) continue;
    final schema = entry.value! as Map<String, Object?>;
    final required = (schema['required'] as List? ?? const []).toSet();
    final props = (schema['properties'] as Map? ?? const {})
        .cast<String, Object?>();
    String describe(MapEntry<String, Object?> prop) {
      final optional = required.contains(prop.key) ? '' : '?';
      return '${prop.key}$optional: ${_typeOf(prop.value)}';
    }

    final parts = [
      for (final prop in props.entries)
        if (prop.key != 'component') describe(prop),
    ];
    final description = schema['description'];
    out.writeln(
      '- ${entry.key}'
      '${description is String ? ': $description' : ''}'
      '${parts.isEmpty ? '' : ' Props: ${parts.join(', ')}.'}',
    );
  }
  out
    ..writeln()
    ..writeln('## Functions')
    ..writeln();
  for (final entry in functions.entries) {
    final schema = entry.value! as Map<String, Object?>;
    final description = schema['description'];
    out.writeln(
      '- ${entry.key}${description is String ? ': $description' : ''}',
    );
  }
  return out.toString().trimRight();
}

/// A short type of a prop schema for the prompt.
String _typeOf(Object? schema) {
  if (schema is! Map) return 'any';
  final ref = schema[r'$ref'];
  if (ref is String) {
    final name = ref.split('/').last;
    return switch (name) {
      'ChildList' => 'child ids',
      'ComponentId' => 'child id',
      'Action' => 'action',
      'DataBinding' || 'FunctionCall' => '',
      _ => name,
    };
  }
  final anyOf = schema['anyOf'];
  if (anyOf is List) {
    final types = [
      for (final alternative in anyOf)
        if (_typeOf(alternative) case final type when type.isNotEmpty) type,
    ];
    return types.isEmpty ? 'any' : types.toSet().join(' or ');
  }
  final values = schema['enum'];
  if (values is List) return values.map((v) => '"$v"').join('|');
  final type = schema['type'];
  if (type is List) return type.join(' or ');
  if (type == 'array') return '${_typeOf(schema['items'])}[]';
  return type is String ? type : 'any';
}

// PORT STATUS: confidence=medium todos=0 upstream=packages/shared/src/generative-ui/catalog/catalog-export.ts, examples/showcases/a2ui-playground/src/a2ui/catalog
