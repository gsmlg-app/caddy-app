import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_bloc/nav_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final destinations = [
    const NavigationDestination(
      key: ValueKey('home'),
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    const NavigationDestination(
      key: ValueKey('caddy'),
      icon: Icon(Icons.dns),
      label: 'Caddy',
    ),
    const NavigationDestination(
      key: ValueKey('settings'),
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  group('NavigationState', () {
    test('initial state has currentIndex 0', () {
      final state = NavigationState(destinations: destinations);
      expect(state.currentIndex, 0);
    });

    test('currentDestination returns correct destination', () {
      final state = NavigationState(
        destinations: destinations,
        currentIndex: 1,
      );
      expect(state.currentDestination.label, 'Caddy');
    });

    test('isFirst returns true at index 0', () {
      final state = NavigationState(destinations: destinations);
      expect(state.isFirst, isTrue);
    });

    test('isFirst returns false at index 1', () {
      final state = NavigationState(
        destinations: destinations,
        currentIndex: 1,
      );
      expect(state.isFirst, isFalse);
    });

    test('isLast returns true at last index', () {
      final state = NavigationState(
        destinations: destinations,
        currentIndex: 2,
      );
      expect(state.isLast, isTrue);
    });

    test('isLast returns false at index 0', () {
      final state = NavigationState(destinations: destinations);
      expect(state.isLast, isFalse);
    });

    test('copyWith updates currentIndex', () {
      final state = NavigationState(destinations: destinations);
      final updated = state.copyWith(currentIndex: 2);
      expect(updated.currentIndex, 2);
      expect(updated.destinations, destinations);
    });

    test('copyWith with no args returns equivalent state', () {
      final state = NavigationState(
        destinations: destinations,
        currentIndex: 1,
      );
      final copy = state.copyWith();
      expect(copy, equals(state));
    });

    test('equality with same props', () {
      final a = NavigationState(destinations: destinations, currentIndex: 1);
      final b = NavigationState(destinations: destinations, currentIndex: 1);
      expect(a, equals(b));
    });

    test('inequality with different currentIndex', () {
      final a = NavigationState(destinations: destinations, currentIndex: 0);
      final b = NavigationState(destinations: destinations, currentIndex: 1);
      expect(a, isNot(equals(b)));
    });
  });

  group('NavigationBloc', () {
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
    });

    blocTest<NavigationBloc, NavigationState>(
      'initial state has index 0 and all destinations',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      verify: (bloc) {
        expect(bloc.state.currentIndex, 0);
        expect(bloc.state.destinations, destinations);
      },
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigateToIndex emits state with new index',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      act: (bloc) => bloc.add(const NavigateToIndex(2)),
      expect: () => [
        NavigationState(destinations: destinations, currentIndex: 2),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigateToIndex ignores negative index',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      act: (bloc) => bloc.add(const NavigateToIndex(-1)),
      expect: () => <NavigationState>[],
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigateToIndex ignores index >= destinations length',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      act: (bloc) => bloc.add(const NavigateToIndex(3)),
      expect: () => <NavigationState>[],
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigateToName emits state for matching name',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      act: (bloc) => bloc.add(const NavigateToName('caddy')),
      expect: () => [
        NavigationState(destinations: destinations, currentIndex: 1),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigateToName ignores unknown name',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      act: (bloc) => bloc.add(const NavigateToName('nonexistent')),
      expect: () => <NavigationState>[],
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigateNext advances to next destination',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      act: (bloc) => bloc.add(const NavigateNext()),
      expect: () => [
        NavigationState(destinations: destinations, currentIndex: 1),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigateNext wraps around from last to first',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      seed: () => NavigationState(destinations: destinations, currentIndex: 2),
      act: (bloc) => bloc.add(const NavigateNext()),
      expect: () => [
        NavigationState(destinations: destinations, currentIndex: 0),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigatePrevious goes to previous destination',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      seed: () => NavigationState(destinations: destinations, currentIndex: 2),
      act: (bloc) => bloc.add(const NavigatePrevious()),
      expect: () => [
        NavigationState(destinations: destinations, currentIndex: 1),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigatePrevious wraps around from first to last',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      act: (bloc) => bloc.add(const NavigatePrevious()),
      expect: () => [
        NavigationState(destinations: destinations, currentIndex: 2),
      ],
    );

    blocTest<NavigationBloc, NavigationState>(
      'NavigateBack does not emit state (no context available)',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      act: (bloc) => bloc.add(const NavigateBack()),
      expect: () => <NavigationState>[],
    );

    blocTest<NavigationBloc, NavigationState>(
      'sequential navigation through all destinations',
      build: () => NavigationBloc(
        navigatorKey: navigatorKey,
        destinations: destinations,
      ),
      act: (bloc) {
        bloc.add(const NavigateNext());
        bloc.add(const NavigateNext());
        bloc.add(const NavigateNext());
      },
      expect: () => [
        NavigationState(destinations: destinations, currentIndex: 1),
        NavigationState(destinations: destinations, currentIndex: 2),
        NavigationState(destinations: destinations, currentIndex: 0),
      ],
    );
  });
}
