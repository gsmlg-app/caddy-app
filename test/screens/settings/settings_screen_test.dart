import 'package:flutter/material.dart';
import 'package:caddy_app/screens/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';
import 'package:theme_bloc/theme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_locale/app_locale.dart';

Widget _buildTestWidget({
  required ThemeBloc themeBloc,
  required GamepadBloc gamepadBloc,
  required SharedPreferences sharedPreferences,
}) {
  return RepositoryProvider<SharedPreferences>(
    create: (context) => sharedPreferences,
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (_) => themeBloc),
        BlocProvider<GamepadBloc>(create: (_) => gamepadBloc),
      ],
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
    late GamepadBloc gamepadBloc;
    late SharedPreferences sharedPreferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      themeBloc = ThemeBloc(sharedPreferences);
      gamepadBloc = GamepadBloc(
        navigatorKey: GlobalKey<NavigatorState>(),
        routeNames: ['home', 'caddy', 'showcase', 'Settings'],
      );
    });

    tearDown(() {
      themeBloc.close();
      gamepadBloc.close();
      sharedPreferences.clear();
    });

    testWidgets('renders correctly with basic components', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          gamepadBloc: gamepadBloc,
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
          gamepadBloc: gamepadBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      expect(find.text('App Setting'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows appearance option', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          gamepadBloc: gamepadBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      expect(find.byIcon(Icons.brightness_medium), findsOneWidget);
    });

    testWidgets('shows accent color option', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          themeBloc: themeBloc,
          gamepadBloc: gamepadBloc,
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
          gamepadBloc: gamepadBloc,
          sharedPreferences: sharedPreferences,
        ),
      );

      expect(find.byIcon(Icons.api), findsOneWidget);
    });
  });
}
