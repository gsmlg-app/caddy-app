import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DmAction', () {
    test('creates with required fields', () {
      var pressed = false;
      final action = DmAction(
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
      final action = DmAction(
        title: 'Test',
        icon: Icons.check,
        onPressed: () {},
      );
      expect(action.disabled, isFalse);
    });

    test('can be created as disabled', () {
      final action = DmAction(
        title: 'Test',
        icon: Icons.check,
        onPressed: () {},
        disabled: true,
      );
      expect(action.disabled, isTrue);
    });
  });

  group('DmActionList', () {
    List<DmAction> makeActions({bool withDisabled = false}) {
      return [
        DmAction(title: 'Save', icon: Icons.save, onPressed: () {}),
        DmAction(
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
            home: Scaffold(body: DmActionList(actions: makeActions())),
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
              body: DmActionList(actions: makeActions(withDisabled: true)),
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
              body: DmActionList(
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
              body: DmActionList(
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
              body: DmActionList(
                size: DmActionSize.large,
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
              body: DmActionList(
                size: DmActionSize.large,
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
              body: DmActionList(
                size: DmActionSize.small,
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
              body: DmActionList(
                size: DmActionSize.small,
                actions: makeActions(),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(PopupMenuButton<int>));
        await tester.pumpAndSettle();

        // Text.rich with TextSpan -- use textContaining to find within rich text
        expect(find.textContaining('Save'), findsOneWidget);
        expect(find.textContaining('Delete'), findsOneWidget);
      });
    });

    testWidgets('supports vertical direction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DmActionList(
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

  group('DmScaffold', () {
    test('has correct default breakpoint constants', () {
      expect(DmScaffold.smallBreakpoint, Breakpoints.small);
      expect(DmScaffold.mediumBreakpoint, Breakpoints.medium);
      expect(DmScaffold.mediumLargeBreakpoint, Breakpoints.mediumLarge);
      expect(DmScaffold.largeBreakpoint, Breakpoints.large);
      expect(DmScaffold.extraLargeBreakpoint, Breakpoints.extraLarge);
      expect(DmScaffold.drawerBreakpoint, Breakpoints.smallDesktop);
    });
  });

  group('DmActionSize', () {
    test('has three values', () {
      expect(DmActionSize.values, hasLength(3));
      expect(DmActionSize.values, [
        DmActionSize.small,
        DmActionSize.medium,
        DmActionSize.large,
      ]);
    });
  });
}
