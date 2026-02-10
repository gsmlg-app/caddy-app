# Caddy App

A Flutter application for running and managing [Caddy](https://caddyserver.com/) web server. Built with a modular monorepo architecture, BLoC state management, and multi-platform support.

## Features

- **Caddy Server Management** - Start, stop, and configure Caddy web server
- **Multi-Platform** - Runs on Android, iOS, macOS, Linux, Windows, and Web
- **Theme Management** - Multiple color schemes with dynamic switching
- **Internationalization** - Full i18n support
- **BLoC State Management** - Clean architecture with separation of concerns
- **Responsive Design** - Adaptive widgets for multiple platforms

## Architecture

This project follows clean architecture principles with a monorepo structure:

- **Main App**: `lib/` - Entry point and main application code
- **State Management**: `app_bloc/` - BLoC pattern implementations
- **Core Libraries**: `app_lib/` - Database, theme, locale, logging, providers
- **UI Components**: `app_widget/` - Reusable widgets and UI elements
- **Native Plugins**: `app_plugin/` - Platform-specific native code
- **Third-party**: `third_party/` - Modified third-party packages

## Getting Started

### Prerequisites

- Flutter SDK >= 3.8.0
- Dart >= 3.8.0
- Git with LFS support

### Setup

```bash
# Install global tools
dart pub global activate melos
dart pub global activate mason_cli

# Bootstrap the project
melos bootstrap
mason get

# Full preparation (code generation)
melos run prepare

# Run the app
flutter run
```

## Development

```bash
melos run analyze          # Lint all packages
melos run format           # Format all packages
melos run test             # Run all tests
melos run prepare          # Full setup (bootstrap + gen-l10n + build-runner)
```

## Running the App

```bash
flutter run                # Default device
flutter run -d chrome      # Web
flutter run -d macos       # macOS
flutter run -d linux       # Linux
```

## License

This project is licensed under the MIT License.
