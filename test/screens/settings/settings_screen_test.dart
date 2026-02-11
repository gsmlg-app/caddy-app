import 'package:flutter/material.dart';
import 'package:caddy_app/screens/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:theme_bloc/theme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_locale/app_locale.dart';

Widget _buildTestWidget({
  required ThemeBloc themeBloc,
  required SharedPreferences sharedPreferences,
}) {
  return RepositoryProvider<SharedPreferences>(
    create: (context) => sharedPreferences,
    child: BlocProvider<ThemeBloc>(
      create: (_) => themeBloc,
      child: MaterialApp(
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: const SettingsScreen(),
      ),
    ),
  );
}

void main() {
  group('SettingsScreen', () {
    late ThemeBloc themeBloc;
    late SharedPreferences sharedPreferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      themeBloc = ThemeBloc(sharedPreferences);
    });

    tearDown(() {
      themeBloc.close();
      sharedPreferences.clear();
    });

    testWidgets('renders correctly with basic components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('displays settings sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      expect(find.text('App Setting'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows appearance option', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      expect(find.byIcon(Icons.brightness_medium), findsOneWidget);
    });

    testWidgets('shows accent color option', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      expect(find.byIcon(Icons.palette), findsOneWidget);
    });

    testWidgets('app settings tile has correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      expect(find.byIcon(Icons.api), findsOneWidget);
    });

    testWidgets('has correct static name and path', (tester) async {
      expect(SettingsScreen.name, 'Settings');
      expect(SettingsScreen.path, '/settings');
    });

    testWidgets('displays theme section', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('shows current theme name in accent color tile', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      final currentThemeName = themeBloc.state.theme.name;
      expect(find.text(currentThemeName), findsOneWidget);
    });

    testWidgets('shows theme mode icon in appearance tile', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      // Default is system mode -> brightness_auto icon
      expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
    });

    testWidgets('ChangeThemeMode event updates bloc state', (tester) async {
      themeBloc.add(const ChangeThemeMode(ThemeMode.dark));
      await tester.pump();

      expect(themeBloc.state.themeMode, ThemeMode.dark);
    });
  });
}
