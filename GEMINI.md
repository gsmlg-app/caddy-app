# Gemini Project Configuration

This file helps Gemini understand the project structure and conventions.

## Project Overview

Caddy App - A Flutter application for running and managing Caddy web server.

## Key Technologies

*   Flutter
*   Dart
*   Caddy (web server)

## Important Directories

*   `lib/`: Main application source code.
*   `app_bloc/`: BLoC pattern implementation.
*   `app_lib/`: Shared libraries.
*   `app_widget/`: Reusable widgets.
*   `app_plugin/`: Native platform plugins.
*   `test/`: Tests.

## Commands

*   `melos bootstrap`: Bootstrap all workspace packages.
*   `melos run prepare`: Full setup (bootstrap + gen-l10n + build-runner).
*   `melos run analyze`: Lint all packages.
*   `melos run test`: Run all tests.
*   `flutter run`: Run the application.
