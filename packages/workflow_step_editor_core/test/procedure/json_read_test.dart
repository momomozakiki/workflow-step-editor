import 'package:test/test.dart';
import 'package:workflow_step_editor_core/procedure/json_read.dart';

void main() {
  group('JsonReader.asMap', () {
    test('passes through a map, stringifying keys', () {
      expect(JsonReader.asMap({'a': 1}), {'a': 1});
    });
    test('non-map yields empty map', () {
      expect(JsonReader.asMap('nope'), isEmpty);
      expect(JsonReader.asMap(null), isEmpty);
    });
  });

  group('JsonReader.asString', () {
    test('passes through a string', () {
      expect(JsonReader.asString('hi'), 'hi');
    });
    test('non-string yields fallback', () {
      expect(JsonReader.asString(42, fallback: 'x'), 'x');
      expect(JsonReader.asString(null), '');
    });
  });

  group('JsonReader.asArgb', () {
    test('passes through an int, masked to 32 bits', () {
      expect(JsonReader.asArgb(0xFFD4E2FF, fallback: 0), 0xFFD4E2FF);
      expect(JsonReader.asArgb(0x1FFFFFFFF, fallback: 0), 0xFFFFFFFF);
    });
    test('parses a decimal and a hex string', () {
      expect(JsonReader.asArgb('255', fallback: 0), 255);
      expect(JsonReader.asArgb('#D4E2FF', fallback: 0), 0xD4E2FF);
    });
    test('unparseable value yields fallback', () {
      expect(JsonReader.asArgb('zzz', fallback: 7), 7);
      expect(JsonReader.asArgb(null, fallback: 7), 7);
    });
  });

  group('JsonReader.asList', () {
    test('passes through a list', () {
      expect(JsonReader.asList([1, 2]), [1, 2]);
    });
    test('non-list yields empty list', () {
      expect(JsonReader.asList('nope'), isEmpty);
      expect(JsonReader.asList(null), isEmpty);
    });
  });
}
