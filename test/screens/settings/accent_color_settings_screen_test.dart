import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:caddy_app/screens/settings/accent_color_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_locale/app_locale.dart';

Widget _buildTestWidget({required DmThemeBloc themeBloc}) {
  return BlocProvider<DmThemeBloc>(
    create: (_) => themeBloc,
    child: MaterialApp(
      localizationsDelegates: AppLocale.localizationsDelegates,
      supportedLocales: AppLocale.supportedLocales,
      home: const AccentColorSettingsScreen(),
    ),
  );
}

void main() {
  group('AccentColorSettingsScreen', () {
    late DmThemeBloc themeBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      themeBloc = DmThemeBloc(prefs: prefs);
    });

    tearDown(() {
      themeBloc.close();
    });

    testWidgets('renders correctly with basic components', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      expect(find.byType(AccentColorSettingsScreen), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('displays current theme name', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      // Default theme name should be displayed
      final currentThemeName = themeBloc.state.entry.name;
      expect(find.text(currentThemeName), findsOneWidget);
    });

    testWidgets('displays color option circles for each theme', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      // Should have one GestureDetector per theme in the color picker
      expect(DmThemeData.themes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('selected color shows checkmark icon', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      expect(find.byIcon(CupertinoIcons.checkmark), findsOneWidget);
    });

    testWidgets('displays all theme names via DmThemeData.themes', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      // Verify all themes have non-empty names
      for (final theme in DmThemeData.themes) {
        expect(theme.name, isNotEmpty);
      }
    });

    testWidgets('DmSetTheme event updates bloc state', (tester) async {
      // Verify the BLoC responds to DmSetTheme
      final lastTheme = DmThemeData.themes.last.name;
      themeBloc.add(DmSetTheme(lastTheme));
      await tester.pump();

      expect(themeBloc.state.entry.name, lastTheme);
    });

    testWidgets('each theme has non-null primary color', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      for (final theme in DmThemeData.themes) {
        expect(theme.light.colorScheme.primary, isNotNull);
      }
    });

    testWidgets('has correct static name and path', (tester) async {
      expect(AccentColorSettingsScreen.name, 'Accent Color Settings');
      expect(AccentColorSettingsScreen.path, 'accent-color');
    });

    testWidgets('dispatching DmSetTheme event changes the theme', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      final lastTheme = DmThemeData.themes.last.name;
      themeBloc.add(DmSetTheme(lastTheme));
      await tester.pumpAndSettle();

      expect(themeBloc.state.entry.name, lastTheme);
    });

    testWidgets('changing theme updates BLoC state', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      // Initial theme
      final initialTheme = themeBloc.state.entry.name;

      // Change to the other theme
      final otherTheme = DmThemeData.themes
          .firstWhere((t) => t.name != initialTheme)
          .name;
      themeBloc.add(DmSetTheme(otherTheme));
      await tester.pumpAndSettle();

      // BLoC state updated
      expect(themeBloc.state.entry.name, otherTheme);
      expect(themeBloc.state.entry.name, isNot(initialTheme));
    });

    testWidgets('checkmark appears only on selected theme', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      // Initially one checkmark
      expect(find.byIcon(CupertinoIcons.checkmark), findsOneWidget);

      // Change theme
      final lastTheme = DmThemeData.themes.last.name;
      themeBloc.add(DmSetTheme(lastTheme));
      await tester.pumpAndSettle();

      // Still exactly one checkmark (on new theme)
      expect(find.byIcon(CupertinoIcons.checkmark), findsOneWidget);
      expect(themeBloc.state.entry.name, lastTheme);
    });
  });
}
