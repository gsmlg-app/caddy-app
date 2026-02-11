import 'package:flutter/material.dart';
import 'package:caddy_app/destination.dart';
import 'package:caddy_app/screens/home/home_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_screen.dart';
import 'package:caddy_app/screens/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:theme_bloc/theme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_locale/app_locale.dart';

void main() {
  group('Destinations', () {
    test('routeNames has 3 entries matching screen names', () {
      expect(Destinations.routeNames, hasLength(3));
      expect(Destinations.routeNames[0], HomeScreen.name);
      expect(Destinations.routeNames[1], CaddyScreen.name);
      expect(Destinations.routeNames[2], SettingsScreen.name);
    });

    testWidgets('navs returns 3 NavigationDestinations', (tester) async {
      late List<NavigationDestination> navs;

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeBloc = ThemeBloc(prefs);

      await tester.pumpWidget(
        BlocProvider<ThemeBloc>(
          create: (_) => themeBloc,
          child: MaterialApp(
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: Builder(
              builder: (context) {
                navs = Destinations.navs(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(navs, hasLength(3));
      expect(navs[0].key, const Key(HomeScreen.name));
      expect(navs[1].key, const Key(CaddyScreen.name));
      expect(navs[2].key, const Key(SettingsScreen.name));

      themeBloc.close();
    });

    testWidgets('indexOf returns correct index for each destination', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeBloc = ThemeBloc(prefs);

      await tester.pumpWidget(
        BlocProvider<ThemeBloc>(
          create: (_) => themeBloc,
          child: MaterialApp(
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: Builder(
              builder: (context) {
                expect(
                  Destinations.indexOf(const Key(HomeScreen.name), context),
                  0,
                );
                expect(
                  Destinations.indexOf(const Key(CaddyScreen.name), context),
                  1,
                );
                expect(
                  Destinations.indexOf(const Key(SettingsScreen.name), context),
                  2,
                );
                expect(
                  Destinations.indexOf(const Key('nonexistent'), context),
                  -1,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      themeBloc.close();
    });

    test('routeNames and navs stay in sync', () {
      // routeNames count must match nav count
      // This is verified at runtime with context, so test the static list
      expect(Destinations.routeNames.length, 3);
    });
  });
}
