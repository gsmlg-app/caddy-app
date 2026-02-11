import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory mock of FlutterSecureStorage for testing.
class MockFlutterSecureStorage extends FlutterSecureStorage {
  MockFlutterSecureStorage() : super();

  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_data);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }
}

void main() {
  group('SecureStorageVaultRepository without namespace', () {
    late SecureStorageVaultRepository vault;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      vault = SecureStorageVaultRepository(storage: mockStorage);
    });

    test('write and read a secret', () async {
      await vault.write(key: 'token', value: 'abc123');
      final result = await vault.read(key: 'token');
      expect(result, 'abc123');
    });

    test('read returns null for missing key', () async {
      final result = await vault.read(key: 'missing');
      expect(result, isNull);
    });

    test('delete removes a secret', () async {
      await vault.write(key: 'del', value: 'v');
      await vault.delete(key: 'del');
      expect(await vault.read(key: 'del'), isNull);
    });

    test('containsKey is true for existing key', () async {
      await vault.write(key: 'exists', value: 'v');
      expect(await vault.containsKey(key: 'exists'), isTrue);
    });

    test('containsKey is false for missing key', () async {
      expect(await vault.containsKey(key: 'nope'), isFalse);
    });

    test('deleteAll clears all secrets', () async {
      await vault.write(key: 'a', value: '1');
      await vault.write(key: 'b', value: '2');
      await vault.deleteAll();
      expect(await vault.readAll(), isEmpty);
    });

    test('readAll returns all stored secrets', () async {
      await vault.write(key: 'x', value: '10');
      await vault.write(key: 'y', value: '20');
      final all = await vault.readAll();
      expect(all, {'x': '10', 'y': '20'});
    });
  });

  group('SecureStorageVaultRepository with namespace', () {
    late SecureStorageVaultRepository vault;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      vault = SecureStorageVaultRepository(
        storage: mockStorage,
        namespace: 'caddy',
      );
    });

    test('write stores with namespace prefix', () async {
      await vault.write(key: 'token', value: 'secret');

      // Verify the underlying storage has prefixed key
      final rawResult = await mockStorage.read(key: 'caddy_token');
      expect(rawResult, 'secret');
    });

    test('read uses namespace prefix', () async {
      // Write directly to underlying storage with prefix
      await mockStorage.write(key: 'caddy_api_key', value: 'mykey');

      final result = await vault.read(key: 'api_key');
      expect(result, 'mykey');
    });

    test('containsKey uses namespace prefix', () async {
      await vault.write(key: 'token', value: 'v');
      expect(await vault.containsKey(key: 'token'), isTrue);

      // Without namespace prefix, the raw key shouldn't exist
      expect(await mockStorage.containsKey(key: 'token'), isFalse);
    });

    test('delete uses namespace prefix', () async {
      await vault.write(key: 'token', value: 'v');
      await vault.delete(key: 'token');
      expect(await vault.read(key: 'token'), isNull);
    });

    test('readAll only returns keys with namespace prefix stripped', () async {
      await vault.write(key: 'a', value: '1');
      await vault.write(key: 'b', value: '2');

      // Add a key without our namespace prefix directly
      await mockStorage.write(key: 'other_key', value: 'other');

      final all = await vault.readAll();
      expect(all, {'a': '1', 'b': '2'});
      expect(all.containsKey('other_key'), isFalse);
    });

    test('deleteAll only removes namespaced keys', () async {
      await vault.write(key: 'mine', value: 'v1');
      await mockStorage.write(key: 'foreign_key', value: 'v2');

      await vault.deleteAll();

      // Our key should be gone
      expect(await vault.read(key: 'mine'), isNull);

      // Foreign key should still exist
      final foreign = await mockStorage.read(key: 'foreign_key');
      expect(foreign, 'v2');
    });

    test('empty namespace behaves like no namespace', () async {
      final emptyNsVault = SecureStorageVaultRepository(
        storage: mockStorage,
        namespace: '',
      );

      await emptyNsVault.write(key: 'raw', value: 'val');
      final result = await mockStorage.read(key: 'raw');
      expect(result, 'val');
    });
  });
}
