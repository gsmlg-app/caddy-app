import 'package:app_locale/app_locale.dart';
import 'package:app_provider/app_provider.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:theme_bloc/theme_bloc.dart';

import 'destination.dart';
import 'router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      final caddyBloc = context.read<CaddyBloc>();
      if (state == AppLifecycleState.paused) {
        caddyBloc.add(const CaddyLifecyclePause());
      } else if (state == AppLifecycleState.resumed) {
        caddyBloc.add(const CaddyLifecycleResume());
      }
    } catch (_) {
      // CaddyBloc may not be available yet during early lifecycle
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();

    return BlocBuilder<ThemeBloc, ThemeState>(
      bloc: themeBloc,
      builder: (context, state) {
        return _AppContent(themeState: state);
      },
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent({required this.themeState});

  final ThemeState themeState;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    return AppBlocProvider(
      navigatorKey: AppRouter.key,
      routeNames: Destinations.routeNames,
      child: MaterialApp.router(
        key: const Key('app'),
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        onGenerateTitle: (context) => context.l10n.appName,
        theme: themeState.theme.lightTheme,
        darkTheme: themeState.theme.darkTheme,
        themeMode: themeState.themeMode,
        localizationsDelegates: AppLocale.localizationsDelegates,
        supportedLocales: AppLocale.supportedLocales,
      ),
    );
  }
}
