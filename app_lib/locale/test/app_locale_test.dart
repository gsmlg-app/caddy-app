import 'package:app_locale/app_locale.dart';
import 'package:app_locale/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocale', () {
    test('supportedLocales contains English', () {
      expect(AppLocale.supportedLocales, contains(const Locale('en')));
    });

    test('supportedLocales is not empty', () {
      expect(AppLocale.supportedLocales.isNotEmpty, true);
    });

    test('localizationsDelegates has 4 delegates', () {
      expect(AppLocale.localizationsDelegates, hasLength(4));
    });

    test('localizationsDelegates includes AppLocalizations delegate', () {
      expect(
        AppLocale.localizationsDelegates,
        contains(AppLocalizations.delegate),
      );
    });

    test('localizationsDelegates includes material delegate', () {
      expect(
        AppLocale.localizationsDelegates,
        contains(GlobalMaterialLocalizations.delegate),
      );
    });

    test('localizationsDelegates includes cupertino delegate', () {
      expect(
        AppLocale.localizationsDelegates,
        contains(GlobalCupertinoLocalizations.delegate),
      );
    });

    test('localizationsDelegates includes widgets delegate', () {
      expect(
        AppLocale.localizationsDelegates,
        contains(GlobalWidgetsLocalizations.delegate),
      );
    });
  });

  group('Localization extension', () {
    testWidgets('context.l10n returns AppLocalizations', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = context.l10n;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n, isA<AppLocalizations>());
    });

    testWidgets('context.l10n.appName returns Caddy App', (tester) async {
      late String appName;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: Builder(
            builder: (context) {
              appName = context.l10n.appName;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(appName, 'Caddy App');
    });

    testWidgets('context.l10n provides parameterized strings', (tester) async {
      late String listenAddress;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          home: Builder(
            builder: (context) {
              listenAddress = context.l10n.caddyListenAddress(':8080');
              return const SizedBox();
            },
          ),
        ),
      );

      expect(listenAddress, 'Listen: :8080');
    });
  });
}
