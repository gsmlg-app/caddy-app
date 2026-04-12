import 'package:bloc_test/bloc_test.dart';
import 'package:duskmoon_ui/duskmoon_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DmThemeBloc', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initial state uses default theme and system mode', () {
      final bloc = DmThemeBloc(prefs: prefs);
      expect(bloc.state.entry.name, DmThemeData.themes.first.name);
      expect(bloc.state.themeMode, ThemeMode.system);
      bloc.close();
    });

    test('initial state reads saved theme from preferences', () async {
      SharedPreferences.setMockInitialValues({
        'themeName': DmThemeData.themes.last.name,
        'themeMode': 'dark',
      });
      final savedPrefs = await SharedPreferences.getInstance();

      final bloc = DmThemeBloc(prefs: savedPrefs);
      expect(bloc.state.entry.name, DmThemeData.themes.last.name);
      expect(bloc.state.themeMode, ThemeMode.dark);
      bloc.close();
    });

    test('initial state reads light mode from preferences', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'light'});
      final savedPrefs = await SharedPreferences.getInstance();

      final bloc = DmThemeBloc(prefs: savedPrefs);
      expect(bloc.state.themeMode, ThemeMode.light);
      bloc.close();
    });

    test('initial state defaults to system for unknown themeMode', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'unknown'});
      final savedPrefs = await SharedPreferences.getInstance();

      final bloc = DmThemeBloc(prefs: savedPrefs);
      expect(bloc.state.themeMode, ThemeMode.system);
      bloc.close();
    });

    test(
      'initial state defaults to first theme for unknown themeName',
      () async {
        SharedPreferences.setMockInitialValues({'themeName': 'nonexistent'});
        final savedPrefs = await SharedPreferences.getInstance();

        final bloc = DmThemeBloc(prefs: savedPrefs);
        expect(bloc.state.entry.name, DmThemeData.themes.first.name);
        bloc.close();
      },
    );

    blocTest<DmThemeBloc, DmThemeState>(
      'emits new state when DmSetThemeMode is added',
      build: () => DmThemeBloc(prefs: prefs),
      act: (bloc) => bloc.add(const DmSetThemeMode(ThemeMode.dark)),
      expect: () => [
        DmThemeState(
          themeName: DmThemeData.themes.first.name,
          themeMode: ThemeMode.dark,
        ),
      ],
    );

    blocTest<DmThemeBloc, DmThemeState>(
      'persists themeMode to SharedPreferences',
      build: () => DmThemeBloc(prefs: prefs),
      act: (bloc) => bloc.add(const DmSetThemeMode(ThemeMode.light)),
      verify: (_) {
        expect(prefs.getString('themeMode'), 'light');
      },
    );

    blocTest<DmThemeBloc, DmThemeState>(
      'emits new state when DmSetTheme is added',
      build: () => DmThemeBloc(prefs: prefs),
      act: (bloc) => bloc.add(DmSetTheme(DmThemeData.themes.last.name)),
      expect: () => [
        DmThemeState(
          themeName: DmThemeData.themes.last.name,
          themeMode: ThemeMode.system,
        ),
      ],
    );

    blocTest<DmThemeBloc, DmThemeState>(
      'persists themeName to SharedPreferences',
      build: () => DmThemeBloc(prefs: prefs),
      act: (bloc) => bloc.add(DmSetTheme(DmThemeData.themes.last.name)),
      verify: (_) {
        expect(prefs.getString('themeName'), DmThemeData.themes.last.name);
      },
    );

    blocTest<DmThemeBloc, DmThemeState>(
      'handles multiple sequential theme changes',
      build: () => DmThemeBloc(prefs: prefs),
      act: (bloc) {
        bloc.add(const DmSetThemeMode(ThemeMode.dark));
        bloc.add(DmSetTheme(DmThemeData.themes.last.name));
        bloc.add(const DmSetThemeMode(ThemeMode.light));
      },
      expect: () => [
        DmThemeState(
          themeName: DmThemeData.themes.first.name,
          themeMode: ThemeMode.dark,
        ),
        DmThemeState(
          themeName: DmThemeData.themes.last.name,
          themeMode: ThemeMode.dark,
        ),
        DmThemeState(
          themeName: DmThemeData.themes.last.name,
          themeMode: ThemeMode.light,
        ),
      ],
    );
  });

  group('DmThemeState', () {
    test('copyWith returns new state with updated themeName', () {
      final state = DmThemeState(themeName: DmThemeData.themes.first.name);
      final updated = state.copyWith(themeName: DmThemeData.themes.last.name);
      expect(updated.entry.name, DmThemeData.themes.last.name);
      expect(updated.themeMode, ThemeMode.system);
    });

    test('copyWith returns new state with updated themeMode', () {
      final state = DmThemeState(themeName: DmThemeData.themes.first.name);
      final updated = state.copyWith(themeMode: ThemeMode.dark);
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.entry.name, DmThemeData.themes.first.name);
    });

    test('copyWith with no arguments returns equivalent state', () {
      final state = DmThemeState(
        themeName: DmThemeData.themes.first.name,
        themeMode: ThemeMode.dark,
      );
      final updated = state.copyWith();
      expect(updated, equals(state));
    });

    test('equality based on props', () {
      final state1 = DmThemeState(
        themeName: DmThemeData.themes.first.name,
        themeMode: ThemeMode.dark,
      );
      final state2 = DmThemeState(
        themeName: DmThemeData.themes.first.name,
        themeMode: ThemeMode.dark,
      );
      expect(state1, equals(state2));
    });

    test('inequality when theme differs', () {
      final state1 = DmThemeState(themeName: DmThemeData.themes.first.name);
      final state2 = DmThemeState(themeName: DmThemeData.themes.last.name);
      expect(state1, isNot(equals(state2)));
    });

    test('inequality when themeMode differs', () {
      final state1 = DmThemeState(
        themeName: DmThemeData.themes.first.name,
        themeMode: ThemeMode.light,
      );
      final state2 = DmThemeState(
        themeName: DmThemeData.themes.first.name,
        themeMode: ThemeMode.dark,
      );
      expect(state1, isNot(equals(state2)));
    });
  });
}
