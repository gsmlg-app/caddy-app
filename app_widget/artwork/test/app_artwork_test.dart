import 'dart:io' show Platform;

import 'package:app_artwork/app_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogoGSMLGDEV', () {
    testWidgets('renders CustomPaint', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LogoGSMLGDEV()));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with AspectRatio', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LogoGSMLGDEV()));
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('has 10:2 aspect ratio', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LogoGSMLGDEV()));
      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, 10 / 2);
    });

    testWidgets('accepts optional child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LogoGSMLGDEV(child: Text('Overlay'))),
      );
      expect(find.text('Overlay'), findsOneWidget);
    });

    testWidgets('golden test', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LogoGSMLGDEV()));

      await expectLater(
        find.byType(LogoGSMLGDEV),
        matchesGoldenFile('goldens/gsmlg_dev.png'),
        skip: !Platform.isWindows,
      );
    });
  });

  group('LaddingPageLottie', () {
    testWidgets('renders widget', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LaddingPageLottie()));
      expect(find.byType(LaddingPageLottie), findsOneWidget);
    });

    testWidgets('accepts width and height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LaddingPageLottie(width: 200, height: 200)),
      );
      expect(find.byType(LaddingPageLottie), findsOneWidget);
    });

    testWidgets('accepts fit parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LaddingPageLottie(fit: BoxFit.contain)),
      );
      expect(find.byType(LaddingPageLottie), findsOneWidget);
    });

    testWidgets('accepts repeat false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LaddingPageLottie(repeat: false)),
      );
      expect(find.byType(LaddingPageLottie), findsOneWidget);
    });

    testWidgets('golden test', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LaddingPageLottie()));

      await expectLater(
        find.byType(LaddingPageLottie),
        matchesGoldenFile('goldens/landing_page.png'),
        skip: !Platform.isWindows,
      );
    });
  });
}
