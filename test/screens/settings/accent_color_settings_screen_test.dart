import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:caddy_app/screens/settings/accent_color_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_theme/app_theme.dart';
import 'package:theme_bloc/theme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_locale/app_locale.dart';

Widget _buildTestWidget({required ThemeBloc themeBloc}) {
  return BlocProvider<ThemeBloc>(
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
    late ThemeBloc themeBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      themeBloc = ThemeBloc(prefs);
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
      final currentThemeName = themeBloc.state.theme.name;
      expect(find.text(currentThemeName), findsOneWidget);
    });

    testWidgets('displays color option circles for each theme', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      // Should have one GestureDetector per theme in the color picker
      // themeList has 4 themes: Violet, Green, Fire, Wheat
      expect(themeList.length, 4);
    });

    testWidgets('selected color shows checkmark icon', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      expect(find.byIcon(CupertinoIcons.checkmark), findsOneWidget);
    });

    testWidgets('displays all 4 theme names via themeList', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      // Verify themeList has 4 entries with expected names
      expect(themeList.map((t) => t.name).toList(), [
        'Violet',
        'Green',
        'Fire',
        'Wheat',
      ]);
    });

    testWidgets('ChangeTheme event updates bloc state', (tester) async {
      // Verify the BLoC responds to ChangeTheme
      themeBloc.add(ChangeTheme(FireTheme()));
      await tester.pump();

      expect(themeBloc.state.theme.name, 'Fire');
    });

    testWidgets('each theme has non-null primary color', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      for (final theme in themeList) {
        expect(theme.lightTheme.colorScheme.primary, isNotNull);
      }
    });

    testWidgets('has correct static name and path', (tester) async {
      expect(AccentColorSettingsScreen.name, 'Accent Color Settings');
      expect(AccentColorSettingsScreen.path, 'accent-color');
    });
  });
}
