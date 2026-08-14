import 'package:flutter/material.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

abstract final class AppFontFamily {
  static const sans = "packages/shadcn_ui/Geist";
  static const mono = "packages/shadcn_ui/GeistMono";
  static const windowsSansFallback = <String>[
    "Microsoft YaHei UI",
    "Microsoft YaHei",
  ];

  static List<String>? get sansFallback =>
      AppPlatform.isWindows ? windowsSansFallback : null;
}

abstract final class DesktopTextScale {
  static const min = 0.9;
  static const max = 1.1;

  static TextScaler clampScaler(TextScaler scaler) {
    return scaler.clamp(minScaleFactor: min, maxScaleFactor: max);
  }

  static Widget wrap(BuildContext context, Widget child) {
    if (!AppPlatform.isDesktop) {
      return child;
    }
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: clampScaler(MediaQuery.textScalerOf(context))),
      child: child,
    );
  }
}

abstract final class AppTypography {
  static final _shadDefaults = ShadTextTheme(family: AppFontFamily.sans);

  static TextStyle _normalize(
    TextStyle style, {
    double? desktopFontSize,
    double? desktopHeight,
  }) {
    var next = style.copyWith(
      letterSpacing: 0,
      fontFamilyFallback: AppFontFamily.sansFallback,
    );
    if (AppPlatform.isDesktop) {
      next = next.copyWith(
        fontSize: desktopFontSize ?? next.fontSize,
        height: desktopHeight ?? 1.25,
      );
    }
    return next;
  }

  static final shad = ShadTextTheme.custom(
    h1Large: _normalize(
      _shadDefaults.h1Large,
      desktopFontSize: 36,
      desktopHeight: 1.15,
    ),
    h1: _normalize(_shadDefaults.h1, desktopFontSize: 28, desktopHeight: 1.2),
    h2: _normalize(_shadDefaults.h2, desktopFontSize: 22, desktopHeight: 1.25),
    h3: _normalize(_shadDefaults.h3, desktopFontSize: 18, desktopHeight: 1.25),
    h4: _normalize(_shadDefaults.h4, desktopFontSize: 16, desktopHeight: 1.25),
    p: _normalize(_shadDefaults.p, desktopFontSize: 13, desktopHeight: 1.3),
    blockquote: _normalize(
      _shadDefaults.blockquote,
      desktopFontSize: 13,
      desktopHeight: 1.3,
    ),
    table: _normalize(
      _shadDefaults.table,
      desktopFontSize: 13,
      desktopHeight: 1.3,
    ),
    list: _normalize(
      _shadDefaults.list,
      desktopFontSize: 13,
      desktopHeight: 1.3,
    ),
    lead: _normalize(
      _shadDefaults.lead,
      desktopFontSize: 15,
      desktopHeight: 1.3,
    ),
    large: _normalize(
      _shadDefaults.large,
      desktopFontSize: 14,
      desktopHeight: 1.25,
    ),
    small: _normalize(
      _shadDefaults.small,
      desktopFontSize: 12,
      desktopHeight: 1.25,
    ),
    muted: _normalize(
      _shadDefaults.muted,
      desktopFontSize: 12,
      desktopHeight: 1.25,
    ),
    family: AppFontFamily.sans,
  );

  static final material = TextTheme(
    displayLarge: shad.h1Large,
    displayMedium: shad.h1,
    displaySmall: shad.h2,
    headlineLarge: shad.h3,
    headlineMedium: shad.h4,
    headlineSmall: shad.h4,
    titleLarge: shad.large,
    titleMedium: shad.p.copyWith(fontWeight: FontWeight.w600),
    titleSmall: shad.small.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: shad.p,
    bodyMedium: shad.muted,
    bodySmall: shad.muted,
    labelLarge: shad.small.copyWith(fontWeight: FontWeight.w600),
    labelMedium: shad.small.copyWith(fontWeight: FontWeight.w600),
    labelSmall: shad.small.copyWith(fontWeight: FontWeight.w600),
  );

  static final pageTitle = shad.h4;
  static final panelTitle = shad.large;
  static final sectionTitle = shad.small.copyWith(fontWeight: FontWeight.w600);
  static final listSectionTitle = shad.p.copyWith(fontWeight: FontWeight.w600);
  static final rowTitle = shad.muted.copyWith(fontWeight: FontWeight.w500);
  static final rowValue = shad.muted;
  static final supporting = shad.muted;
  static final control = shad.small.copyWith(fontWeight: FontWeight.w600);
  static final navigationLabel = shad.small.copyWith(
    fontWeight: FontWeight.w600,
  );
  static final badge = shad.small.copyWith(fontWeight: FontWeight.w600);
  static final code = shad.muted.copyWith(fontFamily: AppFontFamily.mono);
  static final metric = shad.large.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static final numeric = shad.muted.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
