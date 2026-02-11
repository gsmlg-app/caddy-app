import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('themeList', () {
    test('contains 4 themes', () {
      expect(themeList, hasLength(4));
    });

    test('contains all theme types in order', () {
      expect(themeList[0], isA<VioletTheme>());
      expect(themeList[1], isA<GreenTheme>());
      expect(themeList[2], isA<FireTheme>());
      expect(themeList[3], isA<WheatTheme>());
    });
  });

  group('VioletTheme', () {
    late VioletTheme theme;
    setUp(() => theme = VioletTheme());

    test('has name Violet', () {
      expect(theme.name, 'Violet');
    });

    test('toString returns name', () {
      expect(theme.toString(), 'Violet');
    });

    test('provides light theme with Material3', () {
      expect(theme.lightTheme.useMaterial3, isTrue);
      expect(theme.lightTheme.colorScheme.brightness, Brightness.light);
    });

    test('provides dark theme with Material3', () {
      expect(theme.darkTheme.useMaterial3, isTrue);
      expect(theme.darkTheme.colorScheme.brightness, Brightness.dark);
    });

    test('light theme has AppBar with zero elevation', () {
      expect(theme.lightTheme.appBarTheme.elevation, 0);
    });

    test('dark theme has NavigationRail styling', () {
      expect(theme.darkTheme.navigationRailTheme.backgroundColor, isNotNull);
      expect(theme.darkTheme.navigationRailTheme.indicatorColor, isNotNull);
    });
  });

  group('GreenTheme', () {
    late GreenTheme theme;
    setUp(() => theme = GreenTheme());

    test('has name Green', () {
      expect(theme.name, 'Green');
    });

    test('provides light and dark themes', () {
      expect(theme.lightTheme.colorScheme.brightness, Brightness.light);
      expect(theme.darkTheme.colorScheme.brightness, Brightness.dark);
    });
  });

  group('FireTheme', () {
    late FireTheme theme;
    setUp(() => theme = FireTheme());

    test('has name Fire', () {
      expect(theme.name, 'Fire');
    });

    test('provides light and dark themes', () {
      expect(theme.lightTheme.colorScheme.brightness, Brightness.light);
      expect(theme.darkTheme.colorScheme.brightness, Brightness.dark);
    });
  });

  group('WheatTheme', () {
    late WheatTheme theme;
    setUp(() => theme = WheatTheme());

    test('has name Wheat', () {
      expect(theme.name, 'Wheat');
    });

    test('provides light and dark themes', () {
      expect(theme.lightTheme.colorScheme.brightness, Brightness.light);
      expect(theme.darkTheme.colorScheme.brightness, Brightness.dark);
    });
  });

  group('DynamicTheme', () {
    test('creates from seed color', () {
      final theme = DynamicTheme.fromSeed(Colors.blue);
      expect(theme.name, 'Dynamic');
    });

    test('provides light and dark themes from seed', () {
      final theme = DynamicTheme.fromSeed(Colors.teal);
      expect(theme.lightTheme.colorScheme.brightness, Brightness.light);
      expect(theme.darkTheme.colorScheme.brightness, Brightness.dark);
    });

    test('uses Material3', () {
      final theme = DynamicTheme.fromSeed(Colors.red);
      expect(theme.lightTheme.useMaterial3, isTrue);
      expect(theme.darkTheme.useMaterial3, isTrue);
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
      for (final theme in themeList) {
        expect(
          theme.lightTheme.navigationDrawerTheme.backgroundColor,
          isNotNull,
        );
        expect(
          theme.darkTheme.navigationDrawerTheme.backgroundColor,
          isNotNull,
        );
      }
    });

    test('all themes have AppBar with scrolledUnderElevation', () {
      for (final theme in themeList) {
        expect(theme.lightTheme.appBarTheme.scrolledUnderElevation, 1);
        expect(theme.darkTheme.appBarTheme.scrolledUnderElevation, 1);
      }
    });

    test('all themes have distinct color schemes', () {
      final primaryColors = themeList
          .map((t) => t.lightTheme.colorScheme.primary.value)
          .toSet();
      expect(primaryColors, hasLength(4));
    });
  });
}
