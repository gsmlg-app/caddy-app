import 'package:app_database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  group('CaddyConfigs', () {
    test('getAllCaddyConfigs returns empty list initially', () async {
      final configs = await db.getAllCaddyConfigs();
      expect(configs, isEmpty);
    });

    test('upsertCaddyConfig inserts a new config', () async {
      await db.upsertCaddyConfig(
        name: 'test-config',
        configJson: '{"listenAddress":"localhost:8080"}',
      );

      final configs = await db.getAllCaddyConfigs();
      expect(configs, hasLength(1));
      expect(configs.first.name, 'test-config');
      expect(configs.first.configJson, '{"listenAddress":"localhost:8080"}');
      expect(configs.first.adminEnabled, isFalse);
      expect(configs.first.isActive, isFalse);
    });

    test('upsertCaddyConfig updates existing config', () async {
      await db.upsertCaddyConfig(
        name: 'test-config',
        configJson: '{"v":1}',
      );
      await db.upsertCaddyConfig(
        name: 'test-config',
        configJson: '{"v":2}',
        adminEnabled: true,
      );

      final configs = await db.getAllCaddyConfigs();
      expect(configs, hasLength(1));
      expect(configs.first.configJson, '{"v":2}');
      expect(configs.first.adminEnabled, isTrue);
    });

    test('getCaddyConfigByName returns matching config', () async {
      await db.upsertCaddyConfig(
        name: 'alpha',
        configJson: '{"a":1}',
      );
      await db.upsertCaddyConfig(
        name: 'beta',
        configJson: '{"b":2}',
      );

      final config = await db.getCaddyConfigByName('beta');
      expect(config, isNotNull);
      expect(config!.name, 'beta');
      expect(config.configJson, '{"b":2}');
    });

    test('getCaddyConfigByName returns null for missing config', () async {
      final config = await db.getCaddyConfigByName('nonexistent');
      expect(config, isNull);
    });

    test('getActiveCaddyConfig returns null when no active config', () async {
      await db.upsertCaddyConfig(
        name: 'config',
        configJson: '{}',
      );

      final active = await db.getActiveCaddyConfig();
      expect(active, isNull);
    });

    test('setActiveCaddyConfig activates correct config', () async {
      await db.upsertCaddyConfig(
        name: 'config-a',
        configJson: '{"a":1}',
        isActive: true,
      );
      await db.upsertCaddyConfig(
        name: 'config-b',
        configJson: '{"b":2}',
      );

      await db.setActiveCaddyConfig('config-b');

      final active = await db.getActiveCaddyConfig();
      expect(active, isNotNull);
      expect(active!.name, 'config-b');

      // Previous active should be deactivated
      final configA = await db.getCaddyConfigByName('config-a');
      expect(configA!.isActive, isFalse);
    });

    test('deleteCaddyConfig removes config', () async {
      await db.upsertCaddyConfig(
        name: 'to-delete',
        configJson: '{}',
      );

      await db.deleteCaddyConfig('to-delete');

      final config = await db.getCaddyConfigByName('to-delete');
      expect(config, isNull);
    });

    test('deleteCaddyConfig does not affect other configs', () async {
      await db.upsertCaddyConfig(
        name: 'keep',
        configJson: '{"keep":true}',
      );
      await db.upsertCaddyConfig(
        name: 'remove',
        configJson: '{"remove":true}',
      );

      await db.deleteCaddyConfig('remove');

      final configs = await db.getAllCaddyConfigs();
      expect(configs, hasLength(1));
      expect(configs.first.name, 'keep');
    });

    test('watchAllCaddyConfigs emits updates', () async {
      final stream = db.watchAllCaddyConfigs();

      await db.upsertCaddyConfig(
        name: 'watched',
        configJson: '{}',
      );

      final configs = await stream.first;
      expect(configs, hasLength(1));
      expect(configs.first.name, 'watched');
    });

    test('upsertCaddyConfig with adminEnabled true', () async {
      await db.upsertCaddyConfig(
        name: 'admin-config',
        configJson: '{}',
        adminEnabled: true,
        isActive: true,
      );

      final config = await db.getCaddyConfigByName('admin-config');
      expect(config!.adminEnabled, isTrue);
      expect(config.isActive, isTrue);
    });
  });
}
