import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DmThemeData.themes', () {
    test('contains expected number of themes', () {
      expect(DmThemeData.themes, hasLength(greaterThanOrEqualTo(2)));
    });

    test('all themes are DmThemeEntry instances', () {
      for (final theme in DmThemeData.themes) {
        expect(theme, isA<DmThemeEntry>());
      }
    });
  });

  group('DmThemeEntry properties', () {
    late DmThemeEntry theme;
    setUp(() => theme = DmThemeData.themes.first);

    test('has a name', () {
      expect(theme.name, isNotEmpty);
    });

    test('provides light theme with Material3', () {
      expect(theme.light.useMaterial3, isTrue);
      expect(theme.light.colorScheme.brightness, Brightness.light);
    });

    test('provides dark theme with Material3', () {
      expect(theme.dark.useMaterial3, isTrue);
      expect(theme.dark.colorScheme.brightness, Brightness.dark);
    });

    test('light theme has AppBar with zero elevation', () {
      expect(theme.light.appBarTheme.elevation, 0);
    });

    test('dark theme has NavigationRail styling', () {
      expect(theme.dark.navigationRailTheme.backgroundColor, isNotNull);
      expect(theme.dark.navigationRailTheme.indicatorColor, isNotNull);
    });
  });

  group('Second theme entry', () {
    late DmThemeEntry theme;
    setUp(() => theme = DmThemeData.themes.last);

    test('has a name', () {
      expect(theme.name, isNotEmpty);
    });

    test('provides light and dark themes', () {
      expect(theme.light.colorScheme.brightness, Brightness.light);
      expect(theme.dark.colorScheme.brightness, Brightness.dark);
    });
  });

  group('ThemeModeExtension', () {
    group('fromString', () {
      test('parses system', () {
        expect(ThemeModeExtension.fromString('system'), ThemeMode.system);
      });

      test('parses ThemeMode.system', () {
        expect(
          ThemeModeExtension.fromString('ThemeMode.system'),
          ThemeMode.system,
        );
      });

      test('parses light', () {
        expect(ThemeModeExtension.fromString('light'), ThemeMode.light);
      });

      test('parses ThemeMode.light', () {
        expect(
          ThemeModeExtension.fromString('ThemeMode.light'),
          ThemeMode.light,
        );
      });

      test('parses dark', () {
        expect(ThemeModeExtension.fromString('dark'), ThemeMode.dark);
      });

      test('parses ThemeMode.dark', () {
        expect(ThemeModeExtension.fromString('ThemeMode.dark'), ThemeMode.dark);
      });

      test('returns system for null', () {
        expect(ThemeModeExtension.fromString(null), ThemeMode.system);
      });

      test('returns system for unknown string', () {
        expect(ThemeModeExtension.fromString('unknown'), ThemeMode.system);
      });
    });

    group('title', () {
      test('system title', () {
        expect(ThemeMode.system.title, 'System');
      });

      test('light title', () {
        expect(ThemeMode.light.title, 'Light');
      });

      test('dark title', () {
        expect(ThemeMode.dark.title, 'Dark');
      });
    });

    group('icon', () {
      testWidgets('system icon', (tester) async {
        await tester.pumpWidget(MaterialApp(home: ThemeMode.system.icon));
        expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
      });

      testWidgets('light icon', (tester) async {
        await tester.pumpWidget(MaterialApp(home: ThemeMode.light.icon));
        expect(find.byIcon(Icons.light_mode), findsOneWidget);
      });

      testWidgets('dark icon', (tester) async {
        await tester.pumpWidget(MaterialApp(home: ThemeMode.dark.icon));
        expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      });
    });

    group('iconOutlined', () {
      testWidgets('system outlined icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ThemeMode.system.iconOutlined),
        );
        expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
      });

      testWidgets('light outlined icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ThemeMode.light.iconOutlined),
        );
        expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      });

      testWidgets('dark outlined icon', (tester) async {
        await tester.pumpWidget(MaterialApp(home: ThemeMode.dark.iconOutlined));
        expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      });
    });
  });

  group('Theme data structure', () {
    test('all themes have NavigationDrawer styling', () {
      for (final theme in DmThemeData.themes) {
        expect(theme.light.navigationDrawerTheme.backgroundColor, isNotNull);
        expect(theme.dark.navigationDrawerTheme.backgroundColor, isNotNull);
      }
    });

    test('all themes have AppBar with scrolledUnderElevation', () {
      for (final theme in DmThemeData.themes) {
        expect(theme.light.appBarTheme.scrolledUnderElevation, 1);
        expect(theme.dark.appBarTheme.scrolledUnderElevation, 1);
      }
    });

    test('all themes have distinct color schemes', () {
      final primaryColors = DmThemeData.themes
          .map((t) => t.light.colorScheme.primary.toARGB32())
          .toSet();
      expect(primaryColors, hasLength(DmThemeData.themes.length));
    });
  });
}
