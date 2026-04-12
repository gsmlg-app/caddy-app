# DuskMoon UI Migration Design

## Summary

Full migration of the Caddy App from custom Material 3 theming, third-party settings_ui, custom feedback helpers, and a forked adaptive scaffold to the DuskMoon UI design system (`duskmoon_ui ^1.4.0`).

## Goals

- Replace all custom theme, widget, feedback, settings, scaffold, and chart packages with DuskMoon equivalents
- Use DuskMoon's built-in theme schemes (sunshine, moonlight, forest, ocean) instead of custom fire/green/violet/wheat
- Remove `third_party/settings_ui` and `third_party/flutter_adaptive_scaffold`
- Maintain existing BLoC architecture and GoRouter navigation

## Non-Goals

- Changing app features or adding new screens
- Migrating form_bloc / flutter_form_bloc (duskmoon_form wraps them, but app_form/demo stays on current form_bloc for now)
- Changing the monorepo/workspace structure

---

## 1. Dependencies

### Add to root `pubspec.yaml`

```yaml
dependencies:
  duskmoon_ui: ^1.4.0
```

This umbrella package brings in: `duskmoon_theme`, `duskmoon_widgets`, `duskmoon_settings`, `duskmoon_feedback`, `duskmoon_form`, `duskmoon_visualization`, `duskmoon_theme_bloc`, `duskmoon_adaptive_scaffold`, `duskmoon_code_engine`.

### Remove

- `google_fonts` — DuskMoon provides its own typography via `DmTextTheme`

### Remove from workspace

- `third_party/settings_ui` — replaced by `duskmoon_settings`
- `third_party/flutter_adaptive_scaffold` — replaced by `duskmoon_adaptive_scaffold`

---

## 2. Theme System

### Current

- `app_lib/theme`: Abstract `AppTheme` with 5 implementations (Violet, Green, Fire, Wheat, Dynamic)
- `app_bloc/theme`: Custom `ThemeBloc` with `ChangeTheme`/`ChangeThemeMode` events, SharedPreferences persistence
- Color schemes in `app_lib/theme/lib/src/color_schemes/` (4 files)
- Typography via Google Fonts (Inter)

### New

- `app_lib/theme`: Becomes a thin barrel export of `duskmoon_theme`. Exports `DmThemeData`, `DmThemeEntry`, `DmColorExtension`, `ThemeModeExtension`. Remove `AppTheme`, color scheme files, and typography files.
- `app_bloc/theme`: Remove custom `ThemeBloc`. Re-export `DmThemeBloc` from `duskmoon_theme_bloc`.
- Available themes: All entries from `DmThemeData.themes` (sunshine, moonlight, forest, ocean, etc.)
- `DmThemeBloc(prefs: sharedPrefs)` handles persistence automatically (keys: `dm_theme_name`, `dm_theme_mode`)

### App Integration (lib/app.dart)

```dart
BlocBuilder<DmThemeBloc, DmThemeState>(
  builder: (context, state) => DuskmoonApp(
    child: MaterialApp.router(
      theme: state.entry.light,
      darkTheme: state.entry.dark,
      themeMode: state.themeMode,
      scaffoldMessengerKey: dmScaffoldMessengerKey,
      routerConfig: AppRouter.router,
    ),
  ),
)
```

### Semantic Colors

Screens needing custom semantic colors (status indicators, accent surfaces) use:
```dart
final dmColors = Theme.of(context).extension<DmColorExtension>();
// dmColors.success, dmColors.warning, dmColors.info, dmColors.accent, etc.
```

---

## 3. Adaptive Scaffold

### Current

- `app_widget/adaptive`: `AppAdaptiveScaffold` wrapping `flutter_adaptive_scaffold.AdaptiveScaffold`
- `AppAdaptiveAction` / `AppAdaptiveActionList` for responsive action buttons

### New

- `AppAdaptiveScaffold` → `DmAdaptiveScaffold` (near drop-in replacement)
- `AppAdaptiveAction` / `AppAdaptiveActionList` → `DmAction` / `DmActionList`
- Same breakpoint system (Material 3: small, medium, mediumLarge, large, extraLarge)
- Same rail collapse/expand toggle via `showCollapseToggle`, `isExtendedOverride`, `onExtendedChange`
- `app_widget/adaptive` package internals rewritten to re-export DuskMoon scaffold

### Key Mapping

| Current | DuskMoon |
|---------|----------|
| `AppAdaptiveScaffold(destinations:, selectedIndex:, body:, ...)` | `DmAdaptiveScaffold(destinations:, selectedIndex:, body:, ...)` |
| `AppAdaptiveAction(title:, icon:, onPressed:)` | `DmAction(title:, icon:, onPressed:)` |
| `AppAdaptiveActionList(size:, actions:)` | `DmActionList(size:, actions:)` |
| `AppAdaptiveActionSize.small` | `DmActionSize.small` |

---

## 4. Feedback Components

### Current

- `app_widget/feedback`: `showAppDialog`, `showSuccessToast`, `showErrorToast`, `showSnackbar`, `showUndoSnackbar`, `showFullScreenDialog`, `showBottomSheetActionList`, `scaffoldMessengerKey`

### New

Rewrite `app_widget/feedback` to re-export DuskMoon feedback functions:

| Current | DuskMoon |
|---------|----------|
| `showAppDialog<T>()` | `showDmDialog<T>()` |
| `AppDialogAction` | `DmDialogAction` |
| `showSuccessToast()` | `showDmSuccessToast()` |
| `showErrorToast()` | `showDmErrorToast()` |
| `showSnackbar()` | `showDmSnackbar()` |
| `showUndoSnackbar()` | `showDmUndoSnackbar()` |
| `showFullScreenDialog()` | `showDmFullscreenDialog()` |
| `showBottomSheetActionList()` | `showDmBottomSheetActionList()` |
| `BottomSheetAction` | `DmBottomSheetAction` |
| `scaffoldMessengerKey` | `dmScaffoldMessengerKey` |

All call sites in screens update to the new names.

---

## 5. Settings Screens

### Current

- `settings_screen.dart`: `SettingsList` from `third_party/settings_ui`
- `appearance_settings_screen.dart`: Custom `_AppearancePicker` with visual theme mode previews
- `accent_color_settings_screen.dart`: Custom `_AccentColorPicker` with colored circles
- `app_settings_screen.dart`: Basic settings tiles

### New

- Import `duskmoon_settings` instead of `settings_ui`
- `SettingsList`, `SettingsSection`, `SettingsTile` come from `duskmoon_settings` (same API shape, 10 tile constructors)
- `appearance_settings_screen.dart`: Rebuild `_AppearancePicker` to dispatch `DmSetThemeMode` events to `DmThemeBloc`
- `accent_color_settings_screen.dart`: Rebuild `_AccentColorPicker` to show themes from `DmThemeData.themes` and dispatch `DmSetTheme(themeName)` events
- Remove DevicePlatform workarounds (DuskMoon settings respects `Theme.of(context).platform`)

---

## 6. Screens Update

### lib/main.dart

- Initialize `DmThemeBloc(prefs: sharedPrefs)` instead of `ThemeBloc(sharedPrefs)`
- Pass `DmThemeBloc` through `MainProvider`

### lib/app.dart

- `BlocBuilder<DmThemeBloc, DmThemeState>` instead of `BlocBuilder<ThemeBloc, ThemeState>`
- Wrap with `DuskmoonApp()` for platform detection
- Use `state.entry.light` / `state.entry.dark` / `state.themeMode`

### lib/screens/home/home_screen.dart

- `AppAdaptiveScaffold` → `DmAdaptiveScaffold`
- Status cards → `DmCard` for consistent styling
- Quick action cards → `DmCard`

### lib/screens/caddy/caddy_screen.dart

- Error recovery dialog: `showAppDialog` → `showDmDialog` with `DmDialogAction`
- Status cards → `DmCard`
- Status colors: Use `DmColorExtension` semantic tokens (success → running, error → stopped, warning → error state, info → loading)

### lib/screens/caddy/ sub-screens

- Config screen tabs: Consider `DmTabBar` for tab switching
- Buttons: `DmButton` for actions

### lib/screens/destination.dart

- Navigation destinations stay as `NavigationDestination` (used by both old and new scaffold)
- No changes needed

### lib/screens/splash_screen.dart, error_screen.dart

- Minimal changes — update any `AppAdaptiveScaffold` usage if present

---

## 7. Data Visualization

### Current

- `app_widget/chart`: Custom `LineChart`, `BarChart`, `PieChart`, `ChartData`

### New

- Replace with `duskmoon_visualization`: `DmLineChart`, `DmBarChart`, etc.
- `app_widget/chart` becomes a barrel re-export of `duskmoon_visualization` (depends on `duskmoon_visualization: any` in its pubspec.yaml)
- Screens continue to import from `app_chart` but get DuskMoon types
- Update any screen using chart widgets to the new `Dm*Chart` API

---

## 8. Provider Layer

### Current

- `app_lib/provider/lib/src/main_provider.dart`: Creates repositories and `ThemeBloc`, provides them via `MultiRepositoryProvider` + `MultiBlocProvider`

### New

- `ThemeBloc` → `DmThemeBloc` in the provider tree
- `BlocProvider<ThemeBloc>` → `BlocProvider<DmThemeBloc>`
- All `context.read<ThemeBloc>()` calls throughout the app → `context.read<DmThemeBloc>()`

---

## 9. Cleanup

### Delete

- `third_party/settings_ui/` — entire package
- `third_party/flutter_adaptive_scaffold/` — entire package
- `app_lib/theme/lib/src/color_schemes/` — all color scheme files (fire.dart, green.dart, violet.dart, wheat.dart)
- `app_lib/theme/lib/src/themes.dart` — `AppTheme` class hierarchy
- `app_lib/theme/lib/src/typography.dart` — Google Fonts typography
- `app_bloc/theme/lib/src/bloc.dart`, `event.dart`, `state.dart` — custom ThemeBloc

### Update workspace list

Remove from root `pubspec.yaml` workspace entries:
- `third_party/settings_ui`
- `third_party/flutter_adaptive_scaffold`

---

## 10. Testing

- Update existing screen tests to use `DmThemeBloc` / `DmThemeState` in test setups
- Update any mocked `ThemeBloc` to mock `DmThemeBloc`
- Settings screen tests: Update to use `duskmoon_settings` widget finders
- Feedback tests: Update to use `showDmDialog`, `showDmSuccessToast`, etc.
- Run `melos run analyze` and `melos run test` to verify

---

## Migration Order

1. Add `duskmoon_ui` dependency, remove `google_fonts`
2. Migrate `app_lib/theme` → DuskMoon theme exports
3. Migrate `app_bloc/theme` → `DmThemeBloc` re-export
4. Update `app_lib/provider` to use `DmThemeBloc`
5. Update `lib/main.dart` and `lib/app.dart`
6. Migrate `app_widget/adaptive` → DuskMoon scaffold
7. Migrate `app_widget/feedback` → DuskMoon feedback
8. Migrate `app_widget/chart` → DuskMoon visualization
9. Update all screens (home, caddy, settings)
10. Delete `third_party/settings_ui` and `third_party/flutter_adaptive_scaffold`
11. Update workspace list and run `dart pub get`
12. Run `melos run analyze` and `melos run test`
