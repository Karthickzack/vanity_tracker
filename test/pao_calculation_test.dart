import 'package:flutter_test/flutter_test.dart';
import 'package:vanity_tracker/core/utils/date_utils.dart';
import 'package:vanity_tracker/models/vanity_item_model.dart';

void main() {
  group('PAO Expiry Calculation Tests', () {
    test('Calculates 12 months PAO correctly', () {
      final opened = DateTime(2025, 1, 15);
      final expiry = VanityDateUtils.calculateExpiryDate(opened, 12);
      expect(expiry.year, 2026);
      expect(expiry.month, 1);
      expect(expiry.day, 15);
    });

    test('Calculates 3 months PAO (Mascara) correctly', () {
      final opened = DateTime(2025, 1, 10);
      final expiry = VanityDateUtils.calculateExpiryDate(opened, 3);
      expect(expiry.year, 2025);
      expect(expiry.month, 4);
      expect(expiry.day, 10);
    });

    test('Calculates 24 months PAO (Lipstick) correctly', () {
      final opened = DateTime(2024, 6, 1);
      final expiry = VanityDateUtils.calculateExpiryDate(opened, 24);
      expect(expiry.year, 2026);
      expect(expiry.month, 6);
      expect(expiry.day, 1);
    });

    test('Handles month-end boundaries safely', () {
      final opened = DateTime(2025, 1, 31);
      final expiry = VanityDateUtils.calculateExpiryDate(opened, 1); // Feb 28
      expect(expiry.month, 2);
      expect(expiry.day, 28);
    });
  });

  group('Urgency Category Color Tests', () {
    test('Item with >30 days remaining is GREEN', () {
      final today = DateTime(2025, 6, 1);
      final expiry = DateTime(2025, 9, 1); // 92 days
      final category = VanityDateUtils.getUrgencyCategory(DateTime(2025, 1, 1), expiry, today);
      expect(category, 'green');
    });

    test('Item with 15 days remaining is AMBER (Expiring Soon)', () {
      final today = DateTime(2025, 6, 1);
      final expiry = DateTime(2025, 6, 16); // 15 days
      final category = VanityDateUtils.getUrgencyCategory(DateTime(2025, 1, 1), expiry, today);
      expect(category, 'amber');
    });

    test('Item with <0 days remaining is RED (Expired)', () {
      final today = DateTime(2025, 6, 1);
      final expiry = DateTime(2025, 5, 20); // -12 days
      final category = VanityDateUtils.getUrgencyCategory(DateTime(2024, 5, 20), expiry, today);
      expect(category, 'red');
    });

    test('Unopened item returns unopened category', () {
      final category = VanityDateUtils.getUrgencyCategory(null, null);
      expect(category, 'unopened');
    });
  });

  group('VanityItemModel Computed Status Tests', () {
    test('Item marked finished has finished status regardless of expiry', () {
      final item = VanityItemModel(
        vanityItemId: 'item_1',
        productId: 'p_1',
        userId: 'user_1',
        productName: 'Serum',
        brand: 'Brand',
        categoryId: 'serum',
        paoMonths: 12,
        openedDate: DateTime(2025, 1, 1),
        expiryDate: DateTime(2026, 1, 1),
        status: VanityStatus.active,
        finishedDate: DateTime(2025, 6, 1),
        createdAt: DateTime(2025, 1, 1),
      );
      expect(item.computedStatus, VanityStatus.finished);
    });
  });
}
