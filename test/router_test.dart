import 'package:flutter/material.dart';
import 'package:caddy_app/router.dart';
import 'package:caddy_app/screens/app/splash_screen.dart';
import 'package:caddy_app/screens/home/home_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_config_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_log_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_secrets_screen.dart';
import 'package:caddy_app/screens/settings/settings_screen.dart';
import 'package:caddy_app/screens/settings/app_settings_screen.dart';
import 'package:caddy_app/screens/settings/appearance_settings_screen.dart';
import 'package:caddy_app/screens/settings/accent_color_settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AppRouter', () {
    test('has navigator key', () {
      expect(AppRouter.key, isNotNull);
      expect(AppRouter.key, isA<GlobalKey<NavigatorState>>());
    });

    test('router is configured', () {
      expect(AppRouter.router, isNotNull);
      expect(AppRouter.router, isA<GoRouter>());
    });

    test('routes list contains all expected top-level routes', () {
      final routePaths = AppRouter.routes.map((r) => r.path).toList();
      expect(routePaths, contains(SplashScreen.path));
      expect(routePaths, contains(HomeScreen.path));
      expect(routePaths, contains(CaddyScreen.path));
      expect(routePaths, contains(SettingsScreen.path));
    });

    test('caddy route has config, log, and secrets sub-routes', () {
      final caddyRoute = AppRouter.routes.firstWhere(
        (r) => r.path == CaddyScreen.path,
      );
      final subPaths = caddyRoute.routes
          .map((r) => (r as GoRoute).path)
          .toList();
      expect(subPaths, contains(CaddyConfigScreen.path));
      expect(subPaths, contains(CaddyLogScreen.path));
      expect(subPaths, contains(CaddySecretsScreen.path));
    });

    test('settings route has app, appearance, and accent-color sub-routes', () {
      final settingsRoute = AppRouter.routes.firstWhere(
        (r) => r.path == SettingsScreen.path,
      );
      final subPaths = settingsRoute.routes
          .map((r) => (r as GoRoute).path)
          .toList();
      expect(subPaths, contains(AppSettingsScreen.path));
      expect(subPaths, contains(AppearanceSettingsScreen.path));
      expect(subPaths, contains(AccentColorSettingsScreen.path));
    });

    test('total route count is correct', () {
      // 4 top-level + 3 caddy sub + 3 settings sub = 10 total
      int countRoutes(List routes) {
        int count = routes.length;
        for (final route in routes) {
          if (route.routes.isNotEmpty) {
            count += countRoutes(route.routes);
          }
        }
        return count;
      }

      expect(countRoutes(AppRouter.routes), 10);
    });
  });
}
