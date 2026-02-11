import 'package:app_database/app_database.dart';
import 'package:app_provider/app_provider.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_bloc/theme_bloc.dart';

class InMemoryVaultRepository implements VaultRepository {
  final Map<String, String> _data = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _data[key];

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey({required String key}) async =>
      _data.containsKey(key);

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<Map<String, String>> readAll() async => Map.from(_data);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences sharedPrefs;
  late AppDatabase database;
  late VaultRepository vault;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
    database = AppDatabase.forTesting();
    vault = InMemoryVaultRepository();
  });

  tearDown(() async {
    await database.close();
  });

  group('MainProvider', () {
    testWidgets('provides SharedPreferences to descendants', (tester) async {
      late SharedPreferences retrieved;

      await tester.pumpWidget(
        MaterialApp(
          home: MainProvider(
            sharedPrefs: sharedPrefs,
            database: database,
            vault: vault,
            child: Builder(
              builder: (context) {
                retrieved = context.read<SharedPreferences>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(identical(retrieved, sharedPrefs), isTrue);
    });

    testWidgets('provides AppDatabase to descendants', (tester) async {
      late AppDatabase retrieved;

      await tester.pumpWidget(
        MaterialApp(
          home: MainProvider(
            sharedPrefs: sharedPrefs,
            database: database,
            vault: vault,
            child: Builder(
              builder: (context) {
                retrieved = context.read<AppDatabase>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(identical(retrieved, database), isTrue);
    });

    testWidgets('provides VaultRepository to descendants', (tester) async {
      late VaultRepository retrieved;

      await tester.pumpWidget(
        MaterialApp(
          home: MainProvider(
            sharedPrefs: sharedPrefs,
            database: database,
            vault: vault,
            child: Builder(
              builder: (context) {
                retrieved = context.read<VaultRepository>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(identical(retrieved, vault), isTrue);
    });

    testWidgets('provides ThemeBloc to descendants', (tester) async {
      late ThemeBloc retrieved;

      await tester.pumpWidget(
        MaterialApp(
          home: MainProvider(
            sharedPrefs: sharedPrefs,
            database: database,
            vault: vault,
            child: Builder(
              builder: (context) {
                retrieved = context.read<ThemeBloc>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(retrieved, isA<ThemeBloc>());
    });

    testWidgets('ThemeBloc has default state', (tester) async {
      late ThemeBloc bloc;

      await tester.pumpWidget(
        MaterialApp(
          home: MainProvider(
            sharedPrefs: sharedPrefs,
            database: database,
            vault: vault,
            child: Builder(
              builder: (context) {
                bloc = context.read<ThemeBloc>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(bloc.state.themeMode, ThemeMode.system);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainProvider(
            sharedPrefs: sharedPrefs,
            database: database,
            vault: vault,
            child: const Text('Hello'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('child can dispatch ThemeBloc events', (tester) async {
      late ThemeBloc bloc;

      await tester.pumpWidget(
        MaterialApp(
          home: MainProvider(
            sharedPrefs: sharedPrefs,
            database: database,
            vault: vault,
            child: Builder(
              builder: (context) {
                bloc = context.read<ThemeBloc>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      bloc.add(const ChangeThemeMode(ThemeMode.dark));
      await tester.pump();

      expect(bloc.state.themeMode, ThemeMode.dark);
    });
  });
}
