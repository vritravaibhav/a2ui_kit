/// Renders CopilotKit's A2UI Playground catalog (121 components, A2UI 1.0)
/// as Flutter widgets on `a2ui_flutter`.
///
/// Register `a2uiKitCatalog()` with an `a2ui_core` `MessageProcessor` and
/// render its surfaces with `A2uiSurface`:
///
/// ```dart
/// final processor = MessageProcessor<ComponentImplementation>(
///   catalogs: [a2uiKitCatalog()],
/// );
/// ```
///
/// Surfaces take the hosted playground's look; `A2uiKitTheme` restyles
/// them, and `A2uiKitOptions.overrides` replaces any component's builder.
/// A CopilotKit agent's messages go through an `A2uiIdNormalizer` first,
/// since its component ids may not be identifiers (`spacer-l`).
library;

export 'package:a2ui_flutter/a2ui_flutter.dart'
    show
        CatalogImplementation,
        ChildWidgetBuilder,
        ComponentImplementation,
        ComponentProps,
        ComponentWidgetBuilder;

export 'src/catalog.dart'
    show
        a2uiKitCatalog,
        a2uiKitCatalogDocument,
        a2uiKitCatalogPrompt,
        a2uiKitInferenceCatalogDocument,
        a2uiKitPortedComponents,
        a2uiKitStandardCatalog,
        kA2uiPlaygroundCatalogId,
        kA2uiStandardCatalogId;
export 'src/catalog_options.dart';
export 'src/data/owned_data.dart' show A2uiUserOwnedData;
export 'src/document/behaviour.g.dart';
export 'src/document/props.g.dart' hide propEnumValues;
export 'src/foundation/css/css_color.dart' show oklch, parseCssColor;
export 'src/foundation/css/css_length.dart'
    show A2uiEm, A2uiLength, A2uiPercent, A2uiPx;
export 'src/foundation/icons/lucide.dart'
    show
        LucideCircle,
        LucideElement,
        LucideEllipse,
        LucideGlyph,
        LucideIconNode,
        LucideLine,
        LucidePath,
        LucidePolygon,
        LucidePolyline,
        LucideRect,
        LucideRelease,
        a2uiIconNames,
        lucideIcon,
        lucideImport;
export 'src/foundation/interaction/checks.dart'
    show CheckMessage, FailedCheck, firstFailedCheck;
export 'src/foundation/interaction/form_scope.dart'
    show
        A2uiFormController,
        A2uiFormScope,
        FormFieldValidity,
        FormSubmitButton,
        FormValidationMessages;
export 'src/ids/id_normalizer.dart';
export 'src/macros/macro.dart'
    show
        ExpandedMacros,
        MacroDefinition,
        MacroExpander,
        MacroExpansion,
        MacroNode,
        derive,
        flatten,
        given,
        h,
        isDynamic,
        join;
export 'src/macros/macros.dart'
    show
        a2uiKitMacros,
        expandFlightCard,
        expandMacroSample,
        expandWeatherReport,
        flightCardMacro,
        flightCardSampleCall,
        weatherReportMacro,
        weatherReportSampleCall;
export 'src/macros/weather.dart'
    show
        Weather,
        WeatherCurrent,
        WeatherDay,
        WeatherHour,
        WeatherPlace,
        sampleLisbonWeather;
export 'src/macros/weather_fetch.dart'
    show A2uiJsonGet, describeWmo, fetchWeather;
export 'src/theme/a2ui_kit_theme.dart';
export 'src/theme/chart_colors.dart';
export 'src/theme/playground_tokens.dart';
export 'src/theme/tokens.dart' show A2uiColorToken, A2uiShadowToken;
export 'src/theme/tone_colors.dart' show A2uiToneColors;
export 'src/theme/typography.dart';
export 'src/validation/operation_validator.dart' show A2uiOperationValidator;

// PORT STATUS: confidence=high todos=0 upstream=none
