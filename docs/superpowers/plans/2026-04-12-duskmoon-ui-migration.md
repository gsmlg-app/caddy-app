# DuskMoon UI Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all custom theme, widget, feedback, settings, scaffold, and chart packages with DuskMoon UI equivalents.

**Architecture:** The migration replaces internal implementations of 6 workspace packages while keeping their barrel export files as re-export shims to DuskMoon. The root app wiring changes from custom `ThemeBloc`/`AppTheme` to `DmThemeBloc`/`DmThemeEntry`. Third-party packages `settings_ui` and `flutter_adaptive_scaffold` are deleted since DuskMoon provides replacements.

**Tech Stack:** Flutter 3.8+, duskmoon_ui ^1.4.0, BLoC 9.x, GoRouter, SharedPreferences

---

## File Structure

### Files to Create
- None (all changes are modifications to existing files or deletions)

### Files to Modify
- `pubspec.yaml` (root) — add duskmoon_ui, remove google_fonts, remove workspace entries for deleted packages
- `app_lib/theme/pubspec.yaml` — replace deps with duskmoon_theme
- `app_lib/theme/lib/app_theme.dart` — re-export DuskMoon theme types
- `app_bloc/theme/pubspec.yaml` — replace deps with duskmoon_theme_bloc
- `app_bloc/theme/lib/theme_bloc.dart` — re-export DmThemeBloc
- `app_widget/adaptive/pubspec.yaml` — replace deps with duskmoon_adaptive_scaffold
- `app_widget/adaptive/lib/app_adaptive_widgets.dart` — re-export DuskMoon scaffold
- `app_widget/adaptive/lib/src/scaffold.dart` — rewrite to wrap DmAdaptiveScaffold
- `app_widget/adaptive/lib/src/action.dart` — rewrite to wrap DmActionList
- `app_widget/feedback/pubspec.yaml` — replace deps with duskmoon_feedback
- `app_widget/feedback/lib/app_feedback.dart` — re-export DuskMoon feedback
- `app_widget/chart/pubspec.yaml` — replace deps with duskmoon_visualization
- `app_widget/chart/lib/app_chart.dart` — re-export DuskMoon visualization
- `app_lib/provider/pubspec.yaml` — depend on duskmoon_theme_bloc instead of theme_bloc
- `app_lib/provider/lib/src/main.dart` — use DmThemeBloc
- `lib/app.dart` — use DmThemeBloc, DmThemeState, DuskmoonApp wrapper
- `lib/screens/home/home_screen.dart` — DmAdaptiveScaffold, DmCard
- `lib/screens/caddy/caddy_screen.dart` — DmAdaptiveScaffold, showDmDialog
- `lib/screens/settings/settings_screen.dart` — DmThemeBloc, duskmoon_settings
- `lib/screens/settings/appearance_settings_screen.dart` — DmThemeBloc, duskmoon_settings
- `lib/screens/settings/accent_color_settings_screen.dart` — DmThemeBloc, DmThemeData.themes
- `lib/screens/settings/app_settings_screen.dart` — DmThemeBloc, showDmDialog
- `test/app_test.dart` — use DmThemeBloc/DmThemeState

### Files to Delete
- `app_lib/theme/lib/src/themes.dart`
- `app_lib/theme/lib/src/extension.dart`
- `app_lib/theme/lib/src/typography.dart` (if exists)
- `app_lib/theme/lib/src/color_schemes/fire.dart`
- `app_lib/theme/lib/src/color_schemes/green.dart`
- `app_lib/theme/lib/src/color_schemes/violet.dart`
- `app_lib/theme/lib/src/color_schemes/wheat.dart`
- `app_bloc/theme/lib/src/bloc.dart`
- `app_bloc/theme/lib/src/event.dart`
- `app_bloc/theme/lib/src/state.dart`
- `app_widget/feedback/lib/src/bottom_sheet_action.dart`
- `app_widget/feedback/lib/src/dialog.dart`
- `app_widget/feedback/lib/src/fullscreen_dialog.dart`
- `app_widget/feedback/lib/src/helper.dart`
- `app_widget/feedback/lib/src/snackbar.dart`
- `app_widget/feedback/lib/src/toast.dart`
- `app_widget/chart/lib/src/bar_chart.dart`
- `app_widget/chart/lib/src/chart_data.dart`
- `app_widget/chart/lib/src/line_chart.dart`
- `app_widget/chart/lib/src/pie_chart.dart`
- `third_party/settings_ui/` (entire directory)
- `third_party/flutter_adaptive_scaffold/` (entire directory)

---

### Task 1: Add duskmoon_ui dependency and update root pubspec.yaml

**Files:**
- Modify: `pubspec.yaml` (root)

- [ ] **Step 1: Add duskmoon_ui and remove google_fonts from dependencies**

In root `pubspec.yaml`, add `duskmoon_ui: ^1.4.0` to dependencies and remove `google_fonts: ^6.2.1`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  logging: ^1.3.0

  go_router: ^17.0.1

  bloc: ^9.0.0
  flutter_bloc: ^9.0.0
  provider: ^6.1.5
  equatable: ^2.0.7

  shared_preferences: ^2.3.5
  path_provider: ^2.1.5
  path: any

  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.16
  lottie: ^3.3.1
  duskmoon_ui: ^1.4.0

  # workspace packages
  app_database: any
  app_theme: any
  app_locale: any
  app_provider: any
  nav_bloc: any
  theme_bloc: any
  app_artwork: any
  app_chart: any
  app_client_info: any
  app_feedback: any
  app_adaptive_widgets: any
  app_logging: any
  app_secure_storage: any
  app_web_view: any
  demo_form: any
  flutter_form_bloc: any
  caddy_service: any
  caddy_bloc: any
  error_handler_bloc: any
```

Note: `settings_ui: any` is removed from workspace dependencies.

- [ ] **Step 2: Remove deleted packages from workspace list**

In root `pubspec.yaml`, remove these from the `workspace:` list:

```yaml
  # Remove these lines:
  # - third_party/flutter_adaptive_scaffold
  # - third_party/settings_ui
```

- [ ] **Step 3: Run dart pub get to verify resolution**

Run: `dart pub get`
Expected: Successful resolution. duskmoon_ui and its transitive deps resolve.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add duskmoon_ui dependency, remove google_fonts and deleted workspace entries"
```

---

### Task 2: Migrate app_lib/theme to DuskMoon theme

**Files:**
- Modify: `app_lib/theme/pubspec.yaml`
- Modify: `app_lib/theme/lib/app_theme.dart`
- Delete: `app_lib/theme/lib/src/themes.dart`
- Delete: `app_lib/theme/lib/src/extension.dart`
- Delete: `app_lib/theme/lib/src/color_schemes/fire.dart`
- Delete: `app_lib/theme/lib/src/color_schemes/green.dart`
- Delete: `app_lib/theme/lib/src/color_schemes/violet.dart`
- Delete: `app_lib/theme/lib/src/color_schemes/wheat.dart`
- Delete: `app_lib/theme/lib/src/typography.dart` (if exists)

- [ ] **Step 1: Update app_lib/theme/pubspec.yaml**

Replace the dependencies to use duskmoon_theme instead of google_fonts:

```yaml
name: app_theme
version: 1.0.0
publish_to: "none"

environment:
  sdk: ">=3.8.0 <4.0.0"
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  duskmoon_ui: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 2: Delete old theme source files**

Delete these files:
- `app_lib/theme/lib/src/themes.dart`
- `app_lib/theme/lib/src/extension.dart`
- `app_lib/theme/lib/src/color_schemes/fire.dart`
- `app_lib/theme/lib/src/color_schemes/green.dart`
- `app_lib/theme/lib/src/color_schemes/violet.dart`
- `app_lib/theme/lib/src/color_schemes/wheat.dart`

Also check if `app_lib/theme/lib/src/typography.dart` exists and delete it.

- [ ] **Step 3: Rewrite app_lib/theme/lib/app_theme.dart as DuskMoon re-export**

```dart
library;

export 'package:duskmoon_ui/duskmoon_ui.dart'
    show
        DmThemeData,
        DmThemeEntry,
        DmTheme,
        DmColors,
        DmColorScheme,
        DmColorExtension,
        DmTextTheme,
        ThemeModeExtension;
```

- [ ] **Step 4: Verify the package compiles**

Run: `cd app_lib/theme && dart pub get && cd ../..`
Expected: Successful resolution.

- [ ] **Step 5: Commit**

```bash
git add app_lib/theme/
git commit -m "refactor(theme): replace custom AppTheme with DuskMoon theme re-exports"
```

---

### Task 3: Migrate app_bloc/theme to DmThemeBloc

**Files:**
- Modify: `app_bloc/theme/pubspec.yaml`
- Modify: `app_bloc/theme/lib/theme_bloc.dart`
- Delete: `app_bloc/theme/lib/src/bloc.dart`
- Delete: `app_bloc/theme/lib/src/event.dart`
- Delete: `app_bloc/theme/lib/src/state.dart`

- [ ] **Step 1: Update app_bloc/theme/pubspec.yaml**

```yaml
name: theme_bloc
description: App theme bloc
version: 1.0.0

environment:
  sdk: ">=3.8.0 <4.0.0"
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  duskmoon_ui: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  bloc_test: ^10.0.0
```

- [ ] **Step 2: Delete old BLoC source files**

Delete:
- `app_bloc/theme/lib/src/bloc.dart`
- `app_bloc/theme/lib/src/event.dart`
- `app_bloc/theme/lib/src/state.dart`

- [ ] **Step 3: Rewrite app_bloc/theme/lib/theme_bloc.dart as DmThemeBloc re-export**

```dart
library;

export 'package:duskmoon_ui/duskmoon_ui.dart'
    show DmThemeBloc, DmThemeState, DmSetTheme, DmSetThemeMode, DmThemeEntry;
```

- [ ] **Step 4: Commit**

```bash
git add app_bloc/theme/
git commit -m "refactor(theme-bloc): replace custom ThemeBloc with DmThemeBloc re-export"
```

---

### Task 4: Migrate app_widget/adaptive to DuskMoon scaffold

**Files:**
- Modify: `app_widget/adaptive/pubspec.yaml`
- Modify: `app_widget/adaptive/lib/app_adaptive_widgets.dart`
- Modify: `app_widget/adaptive/lib/src/scaffold.dart`
- Modify: `app_widget/adaptive/lib/src/action.dart`

- [ ] **Step 1: Update app_widget/adaptive/pubspec.yaml**

```yaml
name: app_adaptive_widgets
description: Flutter adaptive widgets for my apps.
version: 1.0.0
homepage: none
publish: none

environment:
  sdk: ">=3.8.0 <4.0.0"
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  duskmoon_ui: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 2: Rewrite app_adaptive_widgets.dart barrel export**

```dart
library;

export 'package:duskmoon_ui/duskmoon_ui.dart'
    show
        DmAdaptiveScaffold,
        DmActionList,
        DmAction,
        DmActionSize,
        Breakpoint,
        Breakpoints,
        SlotLayout,
        SlotLayoutConfig,
        AdaptiveLayout,
        NavigationRailDestinationBuilder;
```

- [ ] **Step 3: Replace app_widget/adaptive/lib/src/scaffold.dart**

Replace the entire file with a typedef alias for backward compatibility during migration:

```dart
// This file is kept for backward compatibility.
// Import DmAdaptiveScaffold from app_adaptive_widgets.dart instead.
export 'package:duskmoon_ui/duskmoon_ui.dart' show DmAdaptiveScaffold;

/// Backward-compat alias — use DmAdaptiveScaffold directly.
typedef AppAdaptiveScaffold = DmAdaptiveScaffold;
```

- [ ] **Step 4: Replace app_widget/adaptive/lib/src/action.dart**

```dart
// This file is kept for backward compatibility.
// Import DmActionList from app_adaptive_widgets.dart instead.
export 'package:duskmoon_ui/duskmoon_ui.dart'
    show DmActionList, DmAction, DmActionSize;
```

- [ ] **Step 5: Commit**

```bash
git add app_widget/adaptive/
git commit -m "refactor(adaptive): replace AppAdaptiveScaffold with DmAdaptiveScaffold"
```

---

### Task 5: Migrate app_widget/feedback to DuskMoon feedback

**Files:**
- Modify: `app_widget/feedback/pubspec.yaml`
- Modify: `app_widget/feedback/lib/app_feedback.dart`
- Delete: `app_widget/feedback/lib/src/bottom_sheet_action.dart`
- Delete: `app_widget/feedback/lib/src/dialog.dart`
- Delete: `app_widget/feedback/lib/src/fullscreen_dialog.dart`
- Delete: `app_widget/feedback/lib/src/helper.dart`
- Delete: `app_widget/feedback/lib/src/snackbar.dart`
- Delete: `app_widget/feedback/lib/src/toast.dart`

- [ ] **Step 1: Update app_widget/feedback/pubspec.yaml**

```yaml
name: app_feedback
description: Feedback widgets
version: 1.0.0
publish_to: "none"

environment:
  sdk: ">=3.8.0 <4.0.0"
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  duskmoon_ui: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 2: Delete old feedback source files**

Delete all files in `app_widget/feedback/lib/src/`.

- [ ] **Step 3: Rewrite app_widget/feedback/lib/app_feedback.dart**

```dart
library;

export 'package:duskmoon_ui/duskmoon_ui.dart'
    show
        showDmDialog,
        DmDialogAction,
        showDmFullscreenDialog,
        showDmSnackbar,
        showDmUndoSnackbar,
        showDmSuccessToast,
        showDmErrorToast,
        showDmBottomSheetActionList,
        DmBottomSheetAction,
        dmScaffoldMessengerKey,
        getDmWidgetSize;
```

- [ ] **Step 4: Delete old feedback tests**

Delete all files in `app_widget/feedback/test/src/` — they test the old implementations.

- [ ] **Step 5: Commit**

```bash
git add app_widget/feedback/
git commit -m "refactor(feedback): replace custom feedback helpers with DuskMoon feedback re-exports"
```

---

### Task 6: Migrate app_widget/chart to DuskMoon visualization

**Files:**
- Modify: `app_widget/chart/pubspec.yaml`
- Modify: `app_widget/chart/lib/app_chart.dart`
- Delete: `app_widget/chart/lib/src/bar_chart.dart`
- Delete: `app_widget/chart/lib/src/chart_data.dart`
- Delete: `app_widget/chart/lib/src/line_chart.dart`
- Delete: `app_widget/chart/lib/src/pie_chart.dart`

- [ ] **Step 1: Update app_widget/chart/pubspec.yaml**

```yaml
name: app_chart
description: Chart widgets using DuskMoon visualization for Flutter apps.
version: 1.0.0

environment:
  sdk: ">=3.8.0 <4.0.0"
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  duskmoon_ui: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 2: Delete old chart source files**

Delete all files in `app_widget/chart/lib/src/`.

- [ ] **Step 3: Rewrite app_widget/chart/lib/app_chart.dart**

```dart
library;

export 'package:duskmoon_ui/duskmoon_ui.dart'
    show
        DmLineChart,
        DmBarChart,
        DmScatterChart,
        DmHeatmapChart,
        DmNetworkGraph,
        DmMapChart;
```

- [ ] **Step 4: Delete old chart tests if they exist**

Check `app_widget/chart/test/` and delete tests that reference the old chart classes.

- [ ] **Step 5: Commit**

```bash
git add app_widget/chart/
git commit -m "refactor(chart): replace custom charts with DuskMoon visualization re-exports"
```

---

### Task 7: Update app_lib/provider to use DmThemeBloc

**Files:**
- Modify: `app_lib/provider/pubspec.yaml`
- Modify: `app_lib/provider/lib/src/main.dart`

- [ ] **Step 1: Update app_lib/provider/pubspec.yaml**

Replace `theme_bloc: any` with `duskmoon_ui: any` (keep all other deps):

```yaml
name: app_provider
version: 1.0.0
publish_to: "none"

environment:
  sdk: ">=3.8.0 <4.0.0"
resolution: workspace

dependencies:
  bloc: ^9.0.0
  flutter_bloc: ^9.0.0
  equatable: ^2.0.5
  flutter:
    sdk: flutter
  shared_preferences: ^2.0.17
  duskmoon_ui: any

  app_database: any
  app_secure_storage: any
  caddy_bloc: any
  caddy_service: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 2: Update app_lib/provider/lib/src/main.dart**

Replace `ThemeBloc` with `DmThemeBloc`:

```dart
import 'package:app_database/app_database.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level provider for repositories and DmThemeBloc.
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
          BlocProvider<DmThemeBloc>(
            create: (BuildContext context) =>
                DmThemeBloc(prefs: context.read<SharedPreferences>()),
          ),
        ],
        child: child,
      ),
    );
  }
}

/// Provider for app-level BLoCs.
/// Must be used where navigation context is available.
class AppBlocProvider extends StatefulWidget {
  const AppBlocProvider({super.key, required this.child});

  final Widget child;

  @override
  State<AppBlocProvider> createState() => _AppBlocProviderState();
}

class _AppBlocProviderState extends State<AppBlocProvider> {
  late final CaddyBloc _caddyBloc;

  @override
  void initState() {
    super.initState();
    _caddyBloc = CaddyBloc(
      CaddyService.instance,
      database: context.read<AppDatabase>(),
      vault: context.read<VaultRepository>(),
    );
    _caddyBloc.add(const CaddyInitialize());
  }

  @override
  void dispose() {
    _caddyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CaddyBloc>.value(
      value: _caddyBloc,
      child: widget.child,
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add app_lib/provider/
git commit -m "refactor(provider): use DmThemeBloc instead of custom ThemeBloc"
```

---

### Task 8: Update lib/app.dart to use DmThemeBloc and DuskmoonApp

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Rewrite lib/app.dart**

```dart
import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_provider/app_provider.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
```

- [ ] **Step 2: Commit**

```bash
git add lib/app.dart
git commit -m "refactor(app): use DmThemeBloc, DmThemeState, and DuskmoonApp wrapper"
```

---

### Task 9: Update HomeScreen to use DmAdaptiveScaffold

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

- [ ] **Step 1: Update imports and scaffold usage**

Replace `import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';` with `import 'package:duskmoon_ui/duskmoon_ui.dart';`.

Replace `AppAdaptiveScaffold` with `DmAdaptiveScaffold` in the build method.

Replace `Card(` with `DmCard(` for the status card and quick action cards.

Replace `Card(child: Padding(` pattern with `DmCard(padding: ..., child:` where applicable.

Keep all BLoC and business logic unchanged.

The `_ServerStatusCard` uses `Card(child: Padding(...))` — change to `DmCard(padding: const EdgeInsets.all(16), child: Column(...))`.

The `_QuickActionCard` uses `Card(child: InkWell(...))` — change to `DmCard(child: InkWell(...))`.

- [ ] **Step 2: Verify it compiles**

Run: `dart analyze lib/screens/home/home_screen.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/home_screen.dart
git commit -m "refactor(home): use DmAdaptiveScaffold and DmCard"
```

---

### Task 10: Update CaddyScreen to use DmAdaptiveScaffold and DmDialog

**Files:**
- Modify: `lib/screens/caddy/caddy_screen.dart`

- [ ] **Step 1: Update imports**

Replace:
```dart
import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
```
With:
```dart
import 'package:duskmoon_ui/duskmoon_ui.dart';
```

- [ ] **Step 2: Replace AppAdaptiveScaffold with DmAdaptiveScaffold**

In `CaddyScreen.build()`, change `AppAdaptiveScaffold(` to `DmAdaptiveScaffold(`.

- [ ] **Step 3: Replace _showErrorRecoveryDialog with showDmDialog**

Replace the `_showErrorRecoveryDialog` function:

```dart
void _showErrorRecoveryDialog(
  BuildContext context,
  String errorMessage,
  CaddyState state,
) {
  final isPortInUse =
      errorMessage.contains('already in use') || errorMessage.contains('bind:');

  showDmDialog(
    context: context,
    title: context.l10n.caddyErrorRecoveryTitle,
    content: Text(
      isPortInUse
          ? context.l10n.caddyErrorPortInUse
          : context.l10n.caddyErrorGeneric,
    ),
    actions: [
      DmDialogAction(
        onPressed: (ctx) => Navigator.of(ctx).pop(),
        child: Text(context.l10n.caddyErrorDismiss),
      ),
      if (isPortInUse)
        DmDialogAction(
          onPressed: (ctx) {
            Navigator.of(ctx).pop();
            context.goNamed(CaddyConfigScreen.name);
          },
          child: Text(context.l10n.caddyErrorChangePort),
        ),
      if (!isPortInUse)
        DmDialogAction(
          onPressed: (ctx) {
            Navigator.of(ctx).pop();
            context.goNamed(CaddyLogScreen.name);
          },
          child: Text(context.l10n.caddyErrorViewLogs),
        ),
      DmDialogAction(
        onPressed: (ctx) {
          Navigator.of(ctx).pop();
          context.read<CaddyBloc>().add(CaddyStart(state.config));
        },
        child: Text(context.l10n.caddyErrorRetry),
      ),
    ],
  );
}
```

- [ ] **Step 4: Replace Card with DmCard in status/metrics/config cards**

In `_StatusCard`, `_MetricsCard`, `_ConfigSummary`, `_AdminApiCard`, `_AutoRestartCard`, `_KeyboardShortcutsHint`:
Change `Card(` to `DmCard(` where used.

Note: `SwitchListTile` in `_AdminApiCard` and `_AutoRestartCard` uses `Card(child: SwitchListTile(...))`. Change `Card(` to `DmCard(` — `DmCard` wraps Material Card so `SwitchListTile` still works as a child.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/caddy/caddy_screen.dart
git commit -m "refactor(caddy): use DmAdaptiveScaffold, showDmDialog, and DmCard"
```

---

### Task 11: Update Settings screens

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`
- Modify: `lib/screens/settings/appearance_settings_screen.dart`
- Modify: `lib/screens/settings/accent_color_settings_screen.dart`
- Modify: `lib/screens/settings/app_settings_screen.dart`

- [ ] **Step 1: Update settings_screen.dart**

Replace imports:
```dart
import 'package:duskmoon_ui/duskmoon_ui.dart';
```
Remove:
```dart
import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_theme/app_theme.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';
```

Replace `AppAdaptiveScaffold` → `DmAdaptiveScaffold`.
Replace `context.read<ThemeBloc>()` → `context.read<DmThemeBloc>()`.
Replace `BlocBuilder<ThemeBloc, ThemeState>` → `BlocBuilder<DmThemeBloc, DmThemeState>`.
Replace `themeState.themeMode.icon` → `themeState.themeMode.icon` (DuskMoon provides `ThemeModeExtension` with the same API).
Replace `themeState.theme.name` → `themeState.themeName`.
Remove `smallSecondaryBody: AdaptiveScaffold.emptyBuilder` (DmAdaptiveScaffold handles this by default with null).

The `SettingsList`, `SettingsSection`, `SettingsTile` classes now come from `duskmoon_ui` (which re-exports `duskmoon_settings`).

- [ ] **Step 2: Update appearance_settings_screen.dart**

Replace imports:
```dart
import 'package:duskmoon_ui/duskmoon_ui.dart';
```
Remove:
```dart
import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';
```

Replace `AppAdaptiveScaffold` → `DmAdaptiveScaffold`.
Replace `context.read<ThemeBloc>()` → `context.read<DmThemeBloc>()`.
Replace `BlocBuilder<ThemeBloc, ThemeState>` → `BlocBuilder<DmThemeBloc, DmThemeState>`.
Replace `themeBloc.add(ChangeThemeMode(mode))` → `themeBloc.add(DmSetThemeMode(mode))`.
Remove `smallSecondaryBody: AdaptiveScaffold.emptyBuilder`.

The `_AppearancePicker` and `_AppearanceOption` widgets stay as-is — they're custom UI not tied to settings_ui.

- [ ] **Step 3: Update accent_color_settings_screen.dart**

Replace imports:
```dart
import 'package:duskmoon_ui/duskmoon_ui.dart';
```
Remove:
```dart
import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_theme/app_theme.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';
```

Replace `AppAdaptiveScaffold` → `DmAdaptiveScaffold`.
Replace `context.read<ThemeBloc>()` → `context.read<DmThemeBloc>()`.
Replace `BlocBuilder<ThemeBloc, ThemeState>` → `BlocBuilder<DmThemeBloc, DmThemeState>`.

Replace the `_AccentColorPicker` to use `DmThemeData.themes` instead of `themeList`:

```dart
class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker({
    required this.themes,
    required this.currentThemeName,
    required this.isLight,
    required this.onThemeChanged,
  });

  final List<DmThemeEntry> themes;
  final String currentThemeName;
  final bool isLight;
  final ValueChanged<DmThemeEntry> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? CupertinoColors.white : CupertinoColors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: themes.map((theme) {
              final colorScheme = isLight
                  ? theme.light.colorScheme
                  : theme.dark.colorScheme;
              final isSelected = currentThemeName == theme.name;

              return _ColorOption(
                color: colorScheme.primary,
                isSelected: isSelected,
                onTap: () => onThemeChanged(theme),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            currentThemeName,
            style: TextStyle(
              fontSize: 13,
              color: labelColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
```

Update the call site in `AccentColorSettingsScreen.build()`:

```dart
_AccentColorPicker(
  themes: DmThemeData.themes,
  currentThemeName: state.themeName,
  isLight: isLight,
  onThemeChanged: (theme) {
    themeBloc.add(DmSetTheme(theme.name));
  },
),
```

Remove `smallSecondaryBody: AdaptiveScaffold.emptyBuilder`.

- [ ] **Step 4: Update app_settings_screen.dart**

Replace imports:
```dart
import 'package:duskmoon_ui/duskmoon_ui.dart';
```
Remove:
```dart
import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_feedback/app_feedback.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:theme_bloc/theme_bloc.dart';
```

Replace `AppAdaptiveScaffold` → `DmAdaptiveScaffold`.
Replace `BlocBuilder<ThemeBloc, ThemeState>` → `BlocBuilder<DmThemeBloc, DmThemeState>`.
Replace `showAppDialog(` → `showDmDialog(`.
Replace `AppDialogAction(` → `DmDialogAction(`.
Remove `smallSecondaryBody: AdaptiveScaffold.emptyBuilder`.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/settings/
git commit -m "refactor(settings): use DmThemeBloc, DmAdaptiveScaffold, and duskmoon_settings"
```

---

### Task 12: Update caddy sub-screens (config, log, secrets)

**Files:**
- Modify: `lib/screens/caddy/caddy_config_screen.dart`
- Modify: `lib/screens/caddy/caddy_log_screen.dart`
- Modify: `lib/screens/caddy/caddy_secrets_screen.dart`

- [ ] **Step 1: Check each file for imports of old packages**

In each file, replace:
- `import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';` → `import 'package:duskmoon_ui/duskmoon_ui.dart';`
- `import 'package:app_feedback/app_feedback.dart';` → (already in duskmoon_ui)
- `import 'package:settings_ui/settings_ui.dart';` → (already in duskmoon_ui)
- `import 'package:theme_bloc/theme_bloc.dart';` → (already in duskmoon_ui)

Replace `AppAdaptiveScaffold` → `DmAdaptiveScaffold` in each file.
Replace `AdaptiveScaffold.emptyBuilder` → remove or use null.
Replace any `showAppDialog` → `showDmDialog`, `AppDialogAction` → `DmDialogAction`.
Replace any `Card(` → `DmCard(` where applicable.

- [ ] **Step 2: Commit**

```bash
git add lib/screens/caddy/
git commit -m "refactor(caddy-screens): use DmAdaptiveScaffold and DuskMoon components"
```

---

### Task 13: Update splash_screen and error_screen

**Files:**
- Modify: `lib/screens/app/splash_screen.dart` (if uses old imports)
- Modify: `lib/screens/app/error_screen.dart` (if uses old imports)

- [ ] **Step 1: Check and update imports**

Read each file. If they import `app_adaptive_widgets`, `app_feedback`, `settings_ui`, or `theme_bloc`, replace with `duskmoon_ui`. If they don't use any of these, no changes needed.

- [ ] **Step 2: Commit (if changes were made)**

```bash
git add lib/screens/app/
git commit -m "refactor(app-screens): update to DuskMoon imports"
```

---

### Task 14: Delete third_party/settings_ui and third_party/flutter_adaptive_scaffold

**Files:**
- Delete: `third_party/settings_ui/` (entire directory)
- Delete: `third_party/flutter_adaptive_scaffold/` (entire directory)

- [ ] **Step 1: Delete the directories**

```bash
rm -rf third_party/settings_ui
rm -rf third_party/flutter_adaptive_scaffold
```

- [ ] **Step 2: Verify dart pub get still resolves**

Run: `dart pub get`
Expected: Successful. No workspace packages reference these deleted packages.

- [ ] **Step 3: Commit**

```bash
git add third_party/settings_ui/ third_party/flutter_adaptive_scaffold/
git commit -m "chore: remove third_party/settings_ui and flutter_adaptive_scaffold (replaced by DuskMoon)"
```

---

### Task 15: Update tests

**Files:**
- Modify: `test/app_test.dart`
- Modify: `test/screens/settings/settings_screen_test.dart`
- Modify: `test/screens/settings/appearance_settings_screen_test.dart`
- Modify: `test/screens/settings/accent_color_settings_screen_test.dart`
- Modify: `test/screens/settings/app_settings_screen_test.dart`
- Modify: `test/screens/home/home_screen_test.dart`
- Modify: `test/screens/caddy/caddy_screen_test.dart`
- Modify: other test files as needed

- [ ] **Step 1: Update test/app_test.dart**

Replace:
```dart
import 'package:theme_bloc/theme_bloc.dart';
```
With:
```dart
import 'package:duskmoon_ui/duskmoon_ui.dart';
```

Replace all occurrences of:
- `ThemeBloc(prefs)` → `DmThemeBloc(prefs: prefs)`
- `BlocProvider<ThemeBloc>` → `BlocProvider<DmThemeBloc>`
- `BlocBuilder<ThemeBloc, ThemeState>` → `BlocBuilder<DmThemeBloc, DmThemeState>`
- `state.theme.lightTheme` → `state.entry.light`
- `state.theme.darkTheme` → `state.entry.dark`
- `themeBloc.add(const ChangeThemeMode(ThemeMode.dark))` → `themeBloc.add(const DmSetThemeMode(ThemeMode.dark))`
- `themeBloc.add(const ChangeThemeMode(ThemeMode.light))` → `themeBloc.add(const DmSetThemeMode(ThemeMode.light))`

- [ ] **Step 2: Update all other screen tests**

For each test file in `test/screens/`, replace:
- `import 'package:theme_bloc/theme_bloc.dart';` → `import 'package:duskmoon_ui/duskmoon_ui.dart';`
- `import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';` → `import 'package:duskmoon_ui/duskmoon_ui.dart';`
- `import 'package:app_feedback/app_feedback.dart';` → `import 'package:duskmoon_ui/duskmoon_ui.dart';`
- `import 'package:settings_ui/settings_ui.dart';` → `import 'package:duskmoon_ui/duskmoon_ui.dart';`
- `import 'package:app_theme/app_theme.dart';` → `import 'package:duskmoon_ui/duskmoon_ui.dart';`
- `ThemeBloc(prefs)` → `DmThemeBloc(prefs: prefs)`
- `BlocProvider<ThemeBloc>` → `BlocProvider<DmThemeBloc>`
- `ChangeThemeMode(...)` → `DmSetThemeMode(...)`
- `ChangeTheme(...)` → `DmSetTheme(...)` (pass theme name string instead of AppTheme object)

- [ ] **Step 3: Run all tests**

Run: `flutter test`
Expected: All tests pass. Fix any remaining compile errors.

- [ ] **Step 4: Commit**

```bash
git add test/
git commit -m "test: update all tests to use DmThemeBloc and DuskMoon components"
```

---

### Task 16: Run analysis and format

**Files:** All modified files

- [ ] **Step 1: Run dart pub get at root**

Run: `dart pub get`
Expected: Clean resolution.

- [ ] **Step 2: Run format**

Run: `dart format .`
Expected: All files formatted.

- [ ] **Step 3: Run analyze**

Run: `dart analyze --fatal-warnings`
Expected: No errors or warnings.

- [ ] **Step 4: Run all tests**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 5: Commit any formatting fixes**

```bash
git add -A
git commit -m "chore: format and fix analysis warnings after DuskMoon migration"
```

---

### Task 17: Final cleanup and verification

- [ ] **Step 1: Verify no remaining references to old types**

Run these greps and confirm zero results:
```bash
# Should return no results in lib/ or test/ (docs are ok):
grep -r "AppTheme\|ThemeBloc\|ThemeState\|ChangeTheme\|ChangeThemeMode" lib/ test/ --include="*.dart"
grep -r "AppAdaptiveScaffold" lib/ test/ --include="*.dart"
grep -r "showAppDialog\|AppDialogAction\|scaffoldMessengerKey\b" lib/ test/ --include="*.dart"
grep -r "import.*settings_ui" lib/ test/ --include="*.dart"
grep -r "import.*flutter_adaptive_scaffold" lib/ test/ --include="*.dart"
grep -r "import.*google_fonts" lib/ test/ --include="*.dart"
```

Expected: No matches in `lib/` or `test/` (some may appear in `app_widget/adaptive/lib/src/scaffold.dart` typedef — that's fine).

- [ ] **Step 2: Verify deleted packages are gone**

```bash
test ! -d third_party/settings_ui && echo "OK" || echo "FAIL"
test ! -d third_party/flutter_adaptive_scaffold && echo "OK" || echo "FAIL"
```

Expected: Both print "OK".

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "refactor: complete DuskMoon UI migration — replace custom theme, scaffold, feedback, settings, and chart packages"
```
