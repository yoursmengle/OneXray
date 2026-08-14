import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/theme/font.dart';
import 'package:onexray/pages/theme/theme.dart';

void main() {
  group('AppTheme', () {
    test('light Material and Shad themes share the prototype palette', () {
      const tokens = AppColorTokens.light;
      final palette = tokens.palette;
      final material = AppTheme.light;
      final shad = AppTheme.shadColorScheme(Brightness.light);

      expect(material.scaffoldBackgroundColor, palette.background);
      expect(material.colorScheme.primary, palette.primary);
      expect(material.colorScheme.onPrimary, palette.primaryForeground);
      expect(material.colorScheme.surface, palette.card);
      expect(material.colorScheme.onSurface, palette.foreground);
      expect(material.colorScheme.error, palette.destructive);
      expect(material.colorScheme.outline, palette.border);
      expect(material.appBarTheme.backgroundColor, palette.header);
      expect(material.appBarTheme.foregroundColor, palette.foreground);
      expect(material.appBarTheme.toolbarHeight, isNull);
      expect(material.appBarTheme.titleSpacing, 20);
      expect(
        material.appBarTheme.actionsPadding,
        const EdgeInsetsDirectional.only(end: 12),
      );
      expect(material.appBarTheme.iconTheme, isNull);
      expect(material.appBarTheme.actionsIconTheme, isNull);
      expect(
        material.appBarTheme.systemOverlayStyle?.statusBarColor,
        palette.header,
      );
      expect(
        material.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.dark,
      );
      expect(material.navigationRailTheme.backgroundColor, palette.sidebar);
      expect(material.navigationBarTheme.height, isNull);

      expect(shad.background, palette.background);
      expect(shad.foreground, palette.foreground);
      expect(shad.card, palette.card);
      expect(shad.primary, palette.primary);
      expect(shad.secondary, palette.secondary);
      expect(shad.muted, palette.muted);
      expect(shad.accent, palette.accent);
      expect(shad.destructive, palette.destructive);
      expect(shad.border, palette.border);
      expect(shad.input, palette.input);
      expect(shad.ring, palette.ring);
      expect(shad.custom['running'], palette.running);
      expect(shad.custom['runningText'], palette.runningText);
    });

    test('dark Material and Shad themes share translucent borders', () {
      const tokens = AppColorTokens.dark;
      final palette = tokens.palette;
      final material = AppTheme.dark;
      final shad = AppTheme.shadColorScheme(Brightness.dark);

      expect(material.brightness, Brightness.dark);
      expect(material.colorScheme.primary, palette.primary);
      expect(material.colorScheme.surface, palette.card);
      expect(material.dividerTheme.color, palette.border);
      expect(material.navigationBarTheme.backgroundColor, palette.sidebar);
      expect(
        material.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.light,
      );

      expect(shad.background, palette.background);
      expect(shad.card, palette.card);
      expect(shad.popover, palette.popover);
      expect(shad.border, const Color(0x1CFFFFFF));
      expect(shad.input, const Color(0x26FFFFFF));
    });

    test('Material and Shad themes share the Geist typography system', () {
      final material = AppTheme.light;
      final shad = AppTheme.shad(Brightness.light);
      final desktop = AppPlatform.isDesktop;
      final mutedSize = desktop ? 12.0 : 14.0;
      final mutedHeight = desktop ? 1.25 : 20 / 14;
      final bodySize = desktop ? 13.0 : 16.0;
      final bodyHeight = desktop ? 1.3 : 28 / 16;

      expect(material.textTheme.bodyMedium?.fontFamily, AppFontFamily.sans);
      expect(
        material.textTheme.bodyMedium?.fontFamilyFallback,
        AppFontFamily.sansFallback,
      );
      expect(material.textTheme.bodyMedium?.fontSize, mutedSize);
      expect(material.textTheme.bodyMedium?.height, mutedHeight);
      expect(material.textTheme.bodySmall?.fontSize, mutedSize);
      expect(material.textTheme.labelSmall?.fontSize, mutedSize);
      expect(shad.textTheme.family, AppFontFamily.sans);
      expect(
        shad.textTheme.muted.fontFamilyFallback,
        AppFontFamily.sansFallback,
      );
      expect(shad.textTheme.p.fontSize, bodySize);
      expect(shad.textTheme.p.height, bodyHeight);
      expect(shad.textTheme.small.fontSize, mutedSize);
      expect(shad.textTheme.muted.fontSize, mutedSize);
      expect(shad.textTheme.muted.height, mutedHeight);
      expect(shad.textTheme.h1.letterSpacing, 0);
      expect(shad.textTheme.h4.letterSpacing, 0);
      expect(AppTypography.supporting.fontSize, mutedSize);
      expect(AppTypography.navigationLabel.fontSize, mutedSize);
      expect(AppTypography.badge.fontSize, mutedSize);
      expect(AppTypography.code.fontFamily, AppFontFamily.mono);
      expect(AppTypography.code.fontSize, mutedSize);
      expect(AppTypography.code.height, mutedHeight);
      expect(AppFontFamily.windowsSansFallback, const <String>[
        "Microsoft YaHei UI",
        "Microsoft YaHei",
      ]);
    });

    test('legacy color accessors map to semantic prototype tokens', () {
      const tokens = AppColorTokens.light;
      final palette = tokens.palette;

      expect(tokens.pageBackground, palette.background);
      expect(tokens.surface, palette.card);
      expect(tokens.surfaceBorder, palette.border);
      expect(tokens.primaryText, palette.foreground);
      expect(tokens.secondaryText, palette.mutedForeground);
      expect(tokens.tagBackground, palette.muted);
      expect(tokens.sectionTitle, palette.mutedForeground);
      expect(tokens.interactiveText, palette.primary);
      expect(tokens.secondaryButtonBackground, palette.secondary);
      expect(tokens.secondaryButtonForeground, palette.secondaryForeground);
    });
  });
}
