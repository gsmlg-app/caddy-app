import 'package:app_theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_bloc/theme_bloc.dart';

void main() {
  group('ThemeBloc', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initial state uses default theme and system mode', () {
      final bloc = ThemeBloc(prefs);
      expect(bloc.state.theme.name, themeList.first.name);
      expect(bloc.state.themeMode, ThemeMode.system);
      bloc.close();
    });

    test('initial state reads saved theme from preferences', () async {
      SharedPreferences.setMockInitialValues({
        'themeName': themeList.last.name,
        'themeMode': 'dark',
      });
      final savedPrefs = await SharedPreferences.getInstance();

      final bloc = ThemeBloc(savedPrefs);
      expect(bloc.state.theme.name, themeList.last.name);
      expect(bloc.state.themeMode, ThemeMode.dark);
      bloc.close();
    });

    test('initial state reads light mode from preferences', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'light'});
      final savedPrefs = await SharedPreferences.getInstance();

      final bloc = ThemeBloc(savedPrefs);
      expect(bloc.state.themeMode, ThemeMode.light);
      bloc.close();
    });

    test('initial state defaults to system for unknown themeMode', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'unknown'});
      final savedPrefs = await SharedPreferences.getInstance();

      final bloc = ThemeBloc(savedPrefs);
      expect(bloc.state.themeMode, ThemeMode.system);
      bloc.close();
    });

    test(
      'initial state defaults to first theme for unknown themeName',
      () async {
        SharedPreferences.setMockInitialValues({'themeName': 'nonexistent'});
        final savedPrefs = await SharedPreferences.getInstance();

        final bloc = ThemeBloc(savedPrefs);
        expect(bloc.state.theme.name, themeList.first.name);
        bloc.close();
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'emits new state when ChangeThemeMode is added',
      build: () => ThemeBloc(prefs),
      act: (bloc) => bloc.add(const ChangeThemeMode(ThemeMode.dark)),
      expect: () => [
        ThemeState(theme: themeList.first, themeMode: ThemeMode.dark),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'persists themeMode to SharedPreferences',
      build: () => ThemeBloc(prefs),
      act: (bloc) => bloc.add(const ChangeThemeMode(ThemeMode.light)),
      verify: (_) {
        expect(prefs.getString('themeMode'), 'light');
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'emits new state when ChangeTheme is added',
      build: () => ThemeBloc(prefs),
      act: (bloc) => bloc.add(ChangeTheme(themeList.last)),
      expect: () => [
        ThemeState(theme: themeList.last, themeMode: ThemeMode.system),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'persists themeName to SharedPreferences',
      build: () => ThemeBloc(prefs),
      act: (bloc) => bloc.add(ChangeTheme(themeList.last)),
      verify: (_) {
        expect(prefs.getString('themeName'), themeList.last.name);
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'handles multiple sequential theme changes',
      build: () => ThemeBloc(prefs),
      act: (bloc) {
        bloc.add(const ChangeThemeMode(ThemeMode.dark));
        bloc.add(ChangeTheme(themeList.last));
        bloc.add(const ChangeThemeMode(ThemeMode.light));
      },
      expect: () => [
        ThemeState(theme: themeList.first, themeMode: ThemeMode.dark),
        ThemeState(theme: themeList.last, themeMode: ThemeMode.dark),
        ThemeState(theme: themeList.last, themeMode: ThemeMode.light),
      ],
    );
  });

  group('ThemeState', () {
    test('copyWith returns new state with updated theme', () {
      final state = ThemeState(theme: themeList.first);
      final updated = state.copyWith(theme: themeList.last);
      expect(updated.theme.name, themeList.last.name);
      expect(updated.themeMode, ThemeMode.system);
    });

    test('copyWith returns new state with updated themeMode', () {
      final state = ThemeState(theme: themeList.first);
      final updated = state.copyWith(themeMode: ThemeMode.dark);
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.theme.name, themeList.first.name);
    });

    test('copyWith with no arguments returns equivalent state', () {
      final state = ThemeState(
        theme: themeList.first,
        themeMode: ThemeMode.dark,
      );
      final updated = state.copyWith();
      expect(updated, equals(state));
    });

    test('equality based on props', () {
      final state1 = ThemeState(
        theme: themeList.first,
        themeMode: ThemeMode.dark,
      );
      final state2 = ThemeState(
        theme: themeList.first,
        themeMode: ThemeMode.dark,
      );
      expect(state1, equals(state2));
    });

    test('inequality when theme differs', () {
      final state1 = ThemeState(theme: themeList.first);
      final state2 = ThemeState(theme: themeList.last);
      expect(state1, isNot(equals(state2)));
    });

    test('inequality when themeMode differs', () {
      final state1 = ThemeState(
        theme: themeList.first,
        themeMode: ThemeMode.light,
      );
      final state2 = ThemeState(
        theme: themeList.first,
        themeMode: ThemeMode.dark,
      );
      expect(state1, isNot(equals(state2)));
    });
  });
}
