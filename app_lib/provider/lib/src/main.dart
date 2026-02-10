import 'package:app_database/app_database.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepad_bloc/gamepad_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_bloc/theme_bloc.dart';

/// Top-level provider for repositories and ThemeBloc.
/// Used at app startup before localization is available.
class MainProvider extends StatelessWidget {
  const MainProvider({
    super.key,
    required this.child,
    required this.sharedPrefs,
    required this.database,
    required this.vault,
  });

  final Widget child;
  final SharedPreferences sharedPrefs;
  final AppDatabase database;
  final VaultRepository vault;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SharedPreferences>(
          create: (BuildContext context) => sharedPrefs,
        ),
        RepositoryProvider<AppDatabase>(
          create: (BuildContext context) => database,
        ),
        RepositoryProvider<VaultRepository>(
          create: (BuildContext context) => vault,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(
            create: (BuildContext context) =>
                ThemeBloc(context.read<SharedPreferences>()),
          ),
        ],
        child: child,
      ),
    );
  }
}

/// Provider for GamepadBloc.
/// Must be used where navigation context is available.
class AppBlocProvider extends StatefulWidget {
  const AppBlocProvider({
    super.key,
    required this.navigatorKey,
    required this.routeNames,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final List<String> routeNames;
  final Widget child;

  @override
  State<AppBlocProvider> createState() => _AppBlocProviderState();
}

class _AppBlocProviderState extends State<AppBlocProvider> {
  late final GamepadBloc _gamepadBloc;
  late final CaddyBloc _caddyBloc;

  @override
  void initState() {
    super.initState();
    _gamepadBloc = GamepadBloc(
      navigatorKey: widget.navigatorKey,
      routeNames: widget.routeNames,
    );
    _gamepadBloc.add(const GamepadStartListening());
    _caddyBloc = CaddyBloc(CaddyService.instance);
  }

  @override
  void dispose() {
    _gamepadBloc.close();
    _caddyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GamepadBloc>.value(value: _gamepadBloc),
        BlocProvider<CaddyBloc>.value(value: _caddyBloc),
      ],
      child: widget.child,
    );
  }
}
