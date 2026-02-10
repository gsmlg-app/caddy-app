import 'package:app_locale/app_locale.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caddy_app/screens/caddy/caddy_secrets_screen.dart';

class MockVaultRepository implements VaultRepository {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey({required String key}) async =>
      _store.containsKey(key);

  @override
  Future<void> deleteAll() async => _store.clear();

  @override
  Future<Map<String, String>> readAll() async => Map.of(_store);
}

Widget _buildTestWidget({MockVaultRepository? vault}) {
  return RepositoryProvider<VaultRepository>(
    create: (_) => vault ?? MockVaultRepository(),
    child: MaterialApp(
      localizationsDelegates: AppLocale.localizationsDelegates,
      supportedLocales: AppLocale.supportedLocales,
      home: CaddySecretsScreen(),
    ),
  );
}

void main() {
  group('CaddySecretsScreen', () {
    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CaddySecretsScreen), findsOneWidget);
      expect(find.byIcon(Icons.key_off), findsOneWidget);
    });

    testWidgets('shows add button in app bar', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
    });

    testWidgets('add button opens dialog', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Tap the app bar add button
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows stored secrets', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_CF_API_TOKEN', value: 'test-token');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      expect(find.text('CF_API_TOKEN'), findsOneWidget);
      expect(find.byIcon(Icons.key), findsAtLeastNWidgets(1));
    });

    testWidgets('shows quick add chips when secrets exist', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_CF_API_TOKEN', value: 'test-token');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      expect(find.byType(ActionChip), findsAtLeastNWidgets(1));
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_MY_SECRET', value: 'value');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('edit button opens edit dialog', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_MY_SECRET', value: 'old-value');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('MY_SECRET'), findsAtLeastNWidgets(1));
    });

    testWidgets('saving a secret updates the list', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Open add dialog from the empty state button
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Enter key and value
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'TEST_KEY');
      await tester.enterText(textFields.last, 'test-value');

      // Tap save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('TEST_KEY'), findsOneWidget);
    });

    testWidgets('secrets are masked in display', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_SECRET', value: 'super-secret-value');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      // Should show masked value, not the actual secret
      expect(find.text('super-secret-value'), findsNothing);
      expect(
        find.text('\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
        findsOneWidget,
      );
    });

    testWidgets('only shows caddy-prefixed secrets', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_VISIBLE', value: 'yes');
      await vault.write(key: 'other_HIDDEN', value: 'no');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      expect(find.text('VISIBLE'), findsOneWidget);
      expect(find.text('HIDDEN'), findsNothing);
    });

    testWidgets('delete confirmation removes secret from list', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_TO_DELETE', value: 'val');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      expect(find.text('TO_DELETE'), findsOneWidget);

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete Secret').last);
      await tester.pumpAndSettle();

      expect(find.text('TO_DELETE'), findsNothing);
    });

    testWidgets('cancel delete does not remove secret', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_KEEP_ME', value: 'val');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('KEEP_ME'), findsOneWidget);
    });

    testWidgets('multiple secrets shown with correct count', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_SECRET_1', value: 'v1');
      await vault.write(key: 'caddy_SECRET_2', value: 'v2');
      await vault.write(key: 'caddy_SECRET_3', value: 'v3');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      expect(find.text('SECRET_1'), findsOneWidget);
      expect(find.text('SECRET_2'), findsOneWidget);
      expect(find.text('SECRET_3'), findsOneWidget);
      expect(find.byIcon(Icons.key), findsNWidgets(3));
    });

    testWidgets('quick add chips show check icon for existing secrets', (
      tester,
    ) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_CF_API_TOKEN', value: 'exists');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      // CF_API_TOKEN exists, so its chip should show check_circle
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
      // Other chips should show add_circle_outline
      expect(find.byIcon(Icons.add_circle_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('description text shown when secrets exist', (tester) async {
      final vault = MockVaultRepository();
      await vault.write(key: 'caddy_SOMETHING', value: 'val');

      await tester.pumpWidget(_buildTestWidget(vault: vault));
      await tester.pumpAndSettle();

      expect(
        find.text('Manage API tokens and credentials for Caddy modules'),
        findsOneWidget,
      );
    });

    testWidgets('empty add dialog does not save', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Open add dialog
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Try to save without entering anything
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Dialog should still be open (save didn't happen because key/value empty)
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
