import 'package:flutter/material.dart';
import 'package:caddy_app/screens/app/error_screen.dart';
import 'package:caddy_app/screens/app/splash_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_config_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_log_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_secrets_screen.dart';
import 'package:caddy_app/screens/home/home_screen.dart';
import 'package:caddy_app/screens/settings/accent_color_settings_screen.dart';
import 'package:caddy_app/screens/settings/app_settings_screen.dart';
import 'package:caddy_app/screens/settings/appearance_settings_screen.dart';
import 'package:caddy_app/screens/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>(
    debugLabel: 'routerKey',
  );

  static GoRouter router = GoRouter(
    navigatorKey: key,
    debugLogDiagnostics: true,
    initialLocation: SplashScreen.path,
    routes: routes,
    errorBuilder: (context, state) {
      return ErrorScreen(routerState: state);
    },
  );

  static List<GoRoute> routes = [
    GoRoute(
      name: SplashScreen.name,
      path: SplashScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SplashScreen(),
        );
      },
    ),
    GoRoute(
      name: HomeScreen.name,
      path: HomeScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const HomeScreen(),
        );
      },
    ),
    GoRoute(
      name: CaddyScreen.name,
      path: CaddyScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const CaddyScreen(),
        );
      },
      routes: [
        GoRoute(
          name: CaddyConfigScreen.name,
          path: CaddyConfigScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const CaddyConfigScreen(),
            );
          },
        ),
        GoRoute(
          name: CaddyLogScreen.name,
          path: CaddyLogScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const CaddyLogScreen(),
            );
          },
        ),
        GoRoute(
          name: CaddySecretsScreen.name,
          path: CaddySecretsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const CaddySecretsScreen(),
            );
          },
        ),
      ],
    ),
    GoRoute(
      name: SettingsScreen.name,
      path: SettingsScreen.path,
      pageBuilder: (context, state) {
        return NoTransitionPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: const SettingsScreen(),
        );
      },
      routes: [
        GoRoute(
          name: AppSettingsScreen.name,
          path: AppSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AppSettingsScreen(),
            );
          },
        ),
        GoRoute(
          name: AppearanceSettingsScreen.name,
          path: AppearanceSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AppearanceSettingsScreen(),
            );
          },
        ),
        GoRoute(
          name: AccentColorSettingsScreen.name,
          path: AccentColorSettingsScreen.path,
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: const AccentColorSettingsScreen(),
            );
          },
        ),
      ],
    ),
  ];
}
