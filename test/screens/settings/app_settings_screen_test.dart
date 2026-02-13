import 'package:flutter/material.dart';
import 'package:caddy_app/screens/settings/app_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:theme_bloc/theme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_locale/app_locale.dart';

Widget _buildTestWidget({
  required SharedPreferences prefs,
  required ThemeBloc themeBloc,
}) {
  return RepositoryProvider<SharedPreferences>(
    create: (context) => prefs,
    child: BlocProvider<ThemeBloc>(
      create: (context) => themeBloc,
      child: MaterialApp(
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
        home: const AppSettingsScreen(),
      ),
    ),
  );
}

void main() {
  group('AppSettingsScreen', () {
    late SharedPreferences sharedPreferences;
    late ThemeBloc themeBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      themeBloc = ThemeBloc(sharedPreferences);
    });

    tearDown(() {
      themeBloc.close();
      sharedPreferences.clear();
    });

    testWidgets('renders correctly with basic components', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(prefs: sharedPreferences, themeBloc: themeBloc),
      );

      expect(find.byType(AppSettingsScreen), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('displays APP_NAME section', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(prefs: sharedPreferences, themeBloc: themeBloc),
      );

      expect(find.text('APP_NAME'), findsWidgets);
    });

    testWidgets('displays N/A when APP_NAME is not set', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(prefs: sharedPreferences, themeBloc: themeBloc),
      );

      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('displays APP_NAME value when set', (tester) async {
      await sharedPreferences.setString('APP_NAME', 'Test App Name');

      await tester.pumpWidget(
        _buildTestWidget(prefs: sharedPreferences, themeBloc: themeBloc),
      );

      expect(find.text('Test App Name'), findsOneWidget);
      expect(find.text('N/A'), findsNothing);
    });

    testWidgets('opens dialog when APP_NAME tile is tapped', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(prefs: sharedPreferences, themeBloc: themeBloc),
      );

      // Dialog content should not exist before tap
      expect(find.text('Welcome to Caddy App'), findsNothing);

      await tester.tap(find.text('APP_NAME').last);
      await tester.pumpAndSettle();

      // Dialog content should appear after tap
      expect(find.text('Welcome to Caddy App'), findsOneWidget);
    });

    testWidgets('dialog has OK and Cancel buttons', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(prefs: sharedPreferences, themeBloc: themeBloc),
      );

      await tester.tap(find.text('APP_NAME').last);
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('dialog closes when OK is tapped', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(prefs: sharedPreferences, themeBloc: themeBloc),
      );

      await tester.tap(find.text('APP_NAME').last);
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Caddy App'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Caddy App'), findsNothing);
    });

    testWidgets('dialog closes when Cancel is tapped', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(prefs: sharedPreferences, themeBloc: themeBloc),
      );

      await tester.tap(find.text('APP_NAME').last);
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Caddy App'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Caddy App'), findsNothing);
    });

    testWidgets('APP_NAME tile has correct icon', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(prefs: sharedPreferences, themeBloc: themeBloc),
      );

      expect(find.byIcon(Icons.api), findsOneWidget);
    });

    testWidgets('has correct static name and path', (tester) async {
      expect(AppSettingsScreen.name, 'App Settings');
      expect(AppSettingsScreen.path, 'app');
    });

    testWidgets('handles empty SharedPreferences correctly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final emptyPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _buildTestWidget(prefs: emptyPrefs, themeBloc: themeBloc),
      );

      expect(find.text('N/A'), findsOneWidget);
    });
  });
}
