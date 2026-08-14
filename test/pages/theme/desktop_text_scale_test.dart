import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/pages/theme/font.dart';

void main() {
  test('desktop text scaler clamps above the max factor', () {
    final clamped = DesktopTextScale.clampScaler(TextScaler.linear(2));

    expect(clamped.scale(10), closeTo(11, 0.001));
  });

  test('desktop text scaler clamps below the min factor', () {
    final clamped = DesktopTextScale.clampScaler(TextScaler.linear(0.5));

    expect(clamped.scale(10), closeTo(9, 0.001));
  });

  testWidgets('wrap leaves mobile scale unchanged and clamps desktop', (
    tester,
  ) async {
    late TextScaler applied;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Builder(
          builder: (context) {
            return DesktopTextScale.wrap(
              context,
              Builder(
                builder: (context) {
                  applied = MediaQuery.textScalerOf(context);
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );

    if (AppPlatform.isDesktop) {
      expect(applied.scale(10), closeTo(11, 0.001));
    } else {
      expect(applied.scale(10), closeTo(20, 0.001));
    }
  });

  test('Windows fallback family stays Microsoft YaHei UI then YaHei', () {
    expect(AppFontFamily.windowsSansFallback, const <String>[
      'Microsoft YaHei UI',
      'Microsoft YaHei',
    ]);
    if (AppPlatform.isWindows) {
      expect(AppFontFamily.sansFallback, AppFontFamily.windowsSansFallback);
      expect(
        AppTypography.rowTitle.fontFamilyFallback,
        AppFontFamily.sansFallback,
      );
      expect(AppTypography.rowTitle.height, 1.25);
    }
  });
}
