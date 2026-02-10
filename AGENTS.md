# Build/Lint/Test Commands
- Run single test: `flutter test test/widget_test.dart`
- Run all tests: `melos run test` (dart + flutter tests) or `flutter test`
- Lint: `melos run analyze` + `melos run format`
- Format: `melos run format`
- Analyze: `melos run analyze`
- Build: `melos run build-runner`
- Prepare: `melos run prepare` (bootstrap + gen-l10n + build-runner)
- Fix code: `melos run fix` (applies dart fix --apply)
- Check dependencies: `melos run validate-dependencies`

# Project
- Caddy App: Flutter application for running and managing Caddy web server
- Monorepo managed by Melos with workspace packages in pubspec.yaml

# Code Style Guidelines
- Use flutter_lints from analysis_options.yaml
- Import order: dart, package, local (standard Dart convention)
- Prefer const constructors for performance
- Use BLoC pattern for state management (flutter_bloc)
- Error handling: try/catch with logging (use app_logging package)
- Naming: PascalCase for classes, camelCase for variables
- Types: always specify return types and parameter types

# Package Management
- This project uses Melos for mono-repo management
- When including packages in this project, use `<package_name>: any` in pubspec.yaml
- Do not use path dependencies for workspace packages

# Additional Notes
- Generated files (*.g.dart, *.freezed.dart) are excluded from analysis
- Localization: use `melos run gen-l10n` to generate from ARB files
