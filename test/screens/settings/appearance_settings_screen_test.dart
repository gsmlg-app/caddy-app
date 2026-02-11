import 'package:flutter/material.dart';
import 'package:caddy_app/screens/settings/appearance_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:theme_bloc/theme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_locale/app_locale.dart';

Widget _buildTestWidget({required ThemeBloc themeBloc}) {
  return BlocProvider<ThemeBloc>(
    create: (_) => themeBloc,
    child: MaterialApp(
      localizationsDelegates: AppLocale.localizationsDelegates,
      supportedLocales: AppLocale.supportedLocales,
      home: const AppearanceSettingsScreen(),
    ),
  );
}

void main() {
  group('AppearanceSettingsScreen', () {
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

      expect(find.byType(AppearanceSettingsScreen), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('displays three appearance mode options', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      // Light, Dark, System options
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('tapping light mode dispatches ChangeThemeMode', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      await tester.tap(find.text('Light'));
      await tester.pump();

      expect(themeBloc.state.themeMode, ThemeMode.light);
    });

    testWidgets('tapping dark mode dispatches ChangeThemeMode', (tester) async {
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));

      await tester.tap(find.text('Dark'));
      await tester.pump();

      expect(themeBloc.state.themeMode, ThemeMode.dark);
    });

    testWidgets('tapping system mode dispatches ChangeThemeMode', (
      tester,
    ) async {
      // First switch to dark, then back to system
      themeBloc.add(const ChangeThemeMode(ThemeMode.dark));
      await tester.pumpWidget(_buildTestWidget(themeBloc: themeBloc));
      await tester.pump();

      await tester.tap(find.text('System'));
      await tester.pump();

      expect(themeBloc.state.themeMode, ThemeMode.system);
    });

    testWidgets('has correct static name and path', (tester) async {
      expect(AppearanceSettingsScreen.name, 'Appearance Settings');
      expect(AppearanceSettingsScreen.path, 'appearance');
    });
  });
}
