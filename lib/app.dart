import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_provider/app_provider.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';

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
    } catch (e) {
      AppLogger().d('CaddyBloc not available during lifecycle event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DmThemeBloc, DmThemeState>(
      builder: (context, state) {
        return _AppContent(themeState: state);
      },
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent({required this.themeState});

  final DmThemeState themeState;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    return AppBlocProvider(
      child: DuskmoonApp(
        child: MaterialApp.router(
          key: const Key('app'),
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          onGenerateTitle: (context) => context.l10n.appName,
          theme: themeState.entry.light,
          darkTheme: themeState.entry.dark,
          themeMode: themeState.themeMode,
          scaffoldMessengerKey: dmScaffoldMessengerKey,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
        ),
      ),
    );
  }
}
