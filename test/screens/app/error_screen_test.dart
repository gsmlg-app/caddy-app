import 'package:flutter/material.dart';
import 'package:caddy_app/screens/app/error_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app_locale/app_locale.dart';

// Test version of SplashScreen that doesn't use Timer
class TestSplashScreen extends StatelessWidget {
  const TestSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const Center(child: Text('Splash Screen')),
    );
  }
}

void main() {
  group('ErrorScreen Tests', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/error',
        routes: [
          GoRoute(
            name: ErrorScreen.name,
            path: ErrorScreen.path,
            builder: (context, state) => ErrorScreen(routerState: state),
          ),
          GoRoute(
            name: 'splash',
            path: '/',
            builder: (context, state) => const TestSplashScreen(),
          ),
        ],
      );
    });

    testWidgets('renders correctly with error message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorScreen), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('button navigates to splash screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
        ),
      );

      await tester.pumpAndSettle();

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(TestSplashScreen), findsOneWidget);
    });

    testWidgets('has correct static name and path', (
      WidgetTester tester,
    ) async {
      expect(ErrorScreen.name, 'Error');
      expect(ErrorScreen.path, '/error');
    });

    testWidgets('displays error title text with error color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
        ),
      );

      await tester.pumpAndSettle();

      // Error title text should exist (localized "An error occurred")
      final titleFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.color != null &&
            widget.style!.color ==
                Theme.of(
                  tester.element(find.byType(ErrorScreen)),
                ).colorScheme.error,
      );
      expect(titleFinder, findsOneWidget);
    });

    testWidgets('displays back-to-home button text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
        ),
      );

      await tester.pumpAndSettle();

      // The button should contain localized "Back to Home" text
      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);

      // Verify button has a Text child
      final buttonWidget = tester.widget<ElevatedButton>(button);
      expect(buttonWidget.child, isA<Text>());
    });

    testWidgets('wraps content in Semantics widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('uses custom theme error color for title', (
      WidgetTester tester,
    ) async {
      final customRouter = GoRouter(
        initialLocation: '/error',
        routes: [
          GoRoute(
            name: ErrorScreen.name,
            path: ErrorScreen.path,
            builder: (context, state) => ErrorScreen(routerState: state),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: customRouter,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              error: Colors.purple,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The error title should use the custom error color
      final titleFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.style?.color == Colors.purple,
      );
      expect(titleFinder, findsOneWidget);
    });

    testWidgets('has three containers in column', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
        ),
      );

      await tester.pumpAndSettle();

      // Error title, error message, and button containers
      expect(find.byType(Container), findsNWidgets(3));
    });
  });
}
