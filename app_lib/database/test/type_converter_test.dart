import 'package:app_database/src/type_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = StringListConverter();

  group('StringListConverter', () {
    group('toSql', () {
      test('encodes empty list', () {
        expect(converter.toSql([]), '[]');
      });

      test('encodes single item', () {
        expect(converter.toSql(['hello']), '["hello"]');
      });

      test('encodes multiple items', () {
        final result = converter.toSql(['a', 'b', 'c']);
        expect(result, '["a","b","c"]');
      });

      test('encodes items with special characters', () {
        final result = converter.toSql(['hello "world"', 'foo\\bar']);
        expect(result, contains('hello'));
        expect(result, contains('world'));
      });

      test('encodes items with unicode', () {
        final result = converter.toSql(['日本語', '🚀']);
        expect(result, contains('日本語'));
        expect(result, contains('🚀'));
      });

      test('encodes items with empty strings', () {
        final result = converter.toSql(['', '', '']);
        expect(result, '["","",""]');
      });
    });

    group('fromSql', () {
      test('decodes empty list', () {
        expect(converter.fromSql('[]'), <String>[]);
      });

      test('decodes single item', () {
        expect(converter.fromSql('["hello"]'), ['hello']);
      });

      test('decodes multiple items', () {
        expect(converter.fromSql('["a","b","c"]'), ['a', 'b', 'c']);
      });

      test('decodes items with special characters', () {
        final result = converter.fromSql('["hello \\"world\\""]');
        expect(result, ['hello "world"']);
      });

      test('decodes items with unicode', () {
        final result = converter.fromSql('["日本語","🚀"]');
        expect(result, ['日本語', '🚀']);
      });

      test('converts non-string items to strings', () {
        // JSON numbers are decoded as int/double, but converter calls toString()
        final result = converter.fromSql('[1,2,3]');
        expect(result, ['1', '2', '3']);
      });

      test('converts booleans to strings', () {
        final result = converter.fromSql('[true,false]');
        expect(result, ['true', 'false']);
      });
    });

    group('round-trip', () {
      test('empty list survives round-trip', () {
        final original = <String>[];
        expect(converter.fromSql(converter.toSql(original)), original);
      });

      test('simple list survives round-trip', () {
        final original = ['one', 'two', 'three'];
        expect(converter.fromSql(converter.toSql(original)), original);
      });

      test('list with special characters survives round-trip', () {
        final original = ['path/to/file', 'key=value', 'a & b'];
        expect(converter.fromSql(converter.toSql(original)), original);
      });

      test('list with unicode survives round-trip', () {
        final original = ['日本語', '한국어', 'العربية'];
        expect(converter.fromSql(converter.toSql(original)), original);
      });

      test('list with empty strings survives round-trip', () {
        final original = ['', 'a', '', 'b', ''];
        expect(converter.fromSql(converter.toSql(original)), original);
      });

      test('large list survives round-trip', () {
        final original = List.generate(100, (i) => 'item_$i');
        expect(converter.fromSql(converter.toSql(original)), original);
      });
    });
  });
}
