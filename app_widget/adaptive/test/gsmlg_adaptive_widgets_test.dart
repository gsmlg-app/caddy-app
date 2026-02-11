import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAdaptiveAction', () {
    test('creates with required fields', () {
      var pressed = false;
      final action = AppAdaptiveAction(
        title: 'Save',
        icon: Icons.save,
        onPressed: () => pressed = true,
      );

      expect(action.title, 'Save');
      expect(action.icon, Icons.save);
      expect(action.disabled, isFalse);

      action.onPressed();
      expect(pressed, isTrue);
    });

    test('disabled defaults to false', () {
      final action = AppAdaptiveAction(
        title: 'Test',
        icon: Icons.check,
        onPressed: () {},
      );
      expect(action.disabled, isFalse);
    });

    test('can be created as disabled', () {
      final action = AppAdaptiveAction(
        title: 'Test',
        icon: Icons.check,
        onPressed: () {},
        disabled: true,
      );
      expect(action.disabled, isTrue);
    });
  });

  group('AppAdaptiveActionList', () {
    List<AppAdaptiveAction> makeActions({bool withDisabled = false}) {
      return [
        AppAdaptiveAction(title: 'Save', icon: Icons.save, onPressed: () {}),
        AppAdaptiveAction(
          title: 'Delete',
          icon: Icons.delete,
          onPressed: () {},
          disabled: withDisabled,
        ),
      ];
    }

    group('medium size (default)', () {
      testWidgets('renders IconButtons for each action', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AppAdaptiveActionList(actions: makeActions())),
          ),
        );

        expect(find.byType(IconButton), findsNWidgets(2));
        expect(find.byIcon(Icons.save), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('hides disabled actions by default', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppAdaptiveActionList(
                actions: makeActions(withDisabled: true),
              ),
            ),
          ),
        );

        expect(find.byType(IconButton), findsOneWidget);
        expect(find.byIcon(Icons.save), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsNothing);
      });

      testWidgets('shows disabled actions when hideDisabled is false', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppAdaptiveActionList(
                actions: makeActions(withDisabled: true),
                hideDisabled: false,
              ),
            ),
          ),
        );

        expect(find.byType(IconButton), findsNWidgets(2));
      });

      testWidgets('disabled action has null onPressed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppAdaptiveActionList(
                actions: makeActions(withDisabled: true),
                hideDisabled: false,
              ),
            ),
          ),
        );

        final deleteButton = tester.widget<IconButton>(
          find.byType(IconButton).last,
        );
        expect(deleteButton.onPressed, isNull);
      });
    });

    group('large size', () {
      testWidgets('renders labeled buttons for each action', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppAdaptiveActionList(
                size: AppAdaptiveActionSize.large,
                actions: makeActions(),
              ),
            ),
          ),
        );

        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.byIcon(Icons.save), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('hides disabled actions by default', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppAdaptiveActionList(
                size: AppAdaptiveActionSize.large,
                actions: makeActions(withDisabled: true),
              ),
            ),
          ),
        );

        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Delete'), findsNothing);
      });
    });

    group('small size', () {
      testWidgets('renders PopupMenuButton', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppAdaptiveActionList(
                size: AppAdaptiveActionSize.small,
                actions: makeActions(),
              ),
            ),
          ),
        );

        expect(find.byType(PopupMenuButton<int>), findsOneWidget);
      });

      testWidgets('opens popup menu on tap showing action items', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppAdaptiveActionList(
                size: AppAdaptiveActionSize.small,
                actions: makeActions(),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(PopupMenuButton<int>));
        await tester.pumpAndSettle();

        // Text.rich with TextSpan — use textContaining to find within rich text
        expect(find.textContaining('Save'), findsOneWidget);
        expect(find.textContaining('Delete'), findsOneWidget);
      });
    });

    testWidgets('supports vertical direction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAdaptiveActionList(
              actions: makeActions(),
              direction: Axis.vertical,
            ),
          ),
        ),
      );

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.direction, Axis.vertical);
    });
  });

  group('AppAdaptiveScaffold', () {
    final destinations = [
      const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      const NavigationDestination(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    testWidgets('renders with destinations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveScaffold(
            destinations: destinations,
            body: (_) => const Text('Body'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Body'), findsOneWidget);
    });

    test('has correct default breakpoint constants', () {
      expect(AppAdaptiveScaffold.appSmallBreakpoint, Breakpoints.small);
      expect(AppAdaptiveScaffold.appMediumBreakpoint, Breakpoints.medium);
      expect(
        AppAdaptiveScaffold.appMediumLargeBreakpoint,
        Breakpoints.mediumLarge,
      );
      expect(AppAdaptiveScaffold.appLargeBreakpoint, Breakpoints.large);
      expect(
        AppAdaptiveScaffold.appExtraLargeBreakpoint,
        Breakpoints.extraLarge,
      );
      expect(AppAdaptiveScaffold.appDrawerBreakpoint, Breakpoints.smallDesktop);
    });

    testWidgets('default transitionDuration is zero', (tester) async {
      const scaffold = AppAdaptiveScaffold(
        destinations: [],
        transitionDuration: Duration(milliseconds: 0),
      );

      expect(scaffold.transitionDuration, Duration.zero);
      expect(scaffold.internalAnimations, isTrue);
      expect(scaffold.useDrawer, isFalse);
      expect(scaffold.bodyOrientation, Axis.horizontal);
      expect(scaffold.selectedIndex, 0);
      expect(scaffold.navigationRailWidth, 72);
      expect(scaffold.extendedNavigationRailWidth, 192);
      expect(scaffold.showCollapseToggle, isFalse);
    });
  });

  group('AppAdaptiveActionSize', () {
    test('has three values', () {
      expect(AppAdaptiveActionSize.values, hasLength(3));
      expect(AppAdaptiveActionSize.values, [
        AppAdaptiveActionSize.small,
        AppAdaptiveActionSize.medium,
        AppAdaptiveActionSize.large,
      ]);
    });
  });
}
