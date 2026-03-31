import 'package:flutter_test/flutter_test.dart';
import 'package:family_calendar/data/imported_grocery_catalog.dart';

void main() {
  test('imported grocery catalog has 319 clean rows', () {
    expect(importedGroceryCatalog, hasLength(319));

    for (final row in importedGroceryCatalog) {
      expect((row['category'] ?? '').contains('System.Xml.XmlElement'), isFalse);
      expect((row['itemType'] ?? '').contains('System.Xml.XmlElement'), isFalse);
      expect((row['itemName'] ?? '').contains('System.Xml.XmlElement'), isFalse);

      expect((row['category'] ?? '').trim(), isNotEmpty);
      expect((row['itemType'] ?? '').trim(), isNotEmpty);
      expect((row['itemName'] ?? '').trim(), isNotEmpty);
    }
  });
}
