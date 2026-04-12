import 'package:caddy_app/destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:app_locale/app_locale.dart';

void main() {
  group('Destinations Edge Cases', () {
    testWidgets('changeHandler with negative index does not navigate', (
      tester,
    ) async {
      late BuildContext capturedContext;

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeBloc = DmThemeBloc(prefs: prefs);

      await tester.pumpWidget(
        BlocProvider<DmThemeBloc>(
          create: (_) => themeBloc,
          child: MaterialApp(
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Attempt to navigate with negative index
      Destinations.changeHandler(-1, capturedContext);

      themeBloc.close();
    });

    testWidgets('changeHandler with out-of-bounds index does not navigate', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeBloc = DmThemeBloc(prefs: prefs);

      await tester.pumpWidget(
        BlocProvider<DmThemeBloc>(
          create: (_) => themeBloc,
          child: MaterialApp(
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: Builder(
              builder: (context) {
                // Attempt to navigate with index >= routeNames.length
                Destinations.changeHandler(999, context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      themeBloc.close();
    });

    testWidgets('indexOf with null key returns -1', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeBloc = DmThemeBloc(prefs: prefs);

      late int result;

      await tester.pumpWidget(
        BlocProvider<DmThemeBloc>(
          create: (_) => themeBloc,
          child: MaterialApp(
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: Builder(
              builder: (context) {
                result = Destinations.indexOf(
                  const Key('nonexistent-key'),
                  context,
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, -1);
      themeBloc.close();
    });

    test('routeNames length consistency', () {
      // Verify routeNames has correct number of entries
      expect(Destinations.routeNames.length, equals(3));
      // Verify all names are non-empty strings
      for (final name in Destinations.routeNames) {
        expect(name.isNotEmpty, true);
      }
    });

    testWidgets('navs builds correct number of destinations', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeBloc = DmThemeBloc(prefs: prefs);

      late List<NavigationDestination> destinations;

      await tester.pumpWidget(
        BlocProvider<DmThemeBloc>(
          create: (_) => themeBloc,
          child: MaterialApp(
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: Builder(
              builder: (context) {
                destinations = Destinations.navs(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Verify destinations count matches route names
      expect(destinations.length, Destinations.routeNames.length);
      // Verify all destinations have icons
      for (final dest in destinations) {
        expect(dest.icon, isNotNull);
        expect(dest.selectedIcon, isNotNull);
      }

      themeBloc.close();
    });

    testWidgets('navigationDestinations have unique keys', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeBloc = DmThemeBloc(prefs: prefs);

      late List<NavigationDestination> destinations;

      await tester.pumpWidget(
        BlocProvider<DmThemeBloc>(
          create: (_) => themeBloc,
          child: MaterialApp(
            localizationsDelegates: AppLocale.localizationsDelegates,
            supportedLocales: AppLocale.supportedLocales,
            home: Builder(
              builder: (context) {
                destinations = Destinations.navs(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final keys = destinations.map((d) => d.key).toList();
      // All keys should be unique
      expect(keys.length, keys.toSet().length);

      themeBloc.close();
    });
  });
}
