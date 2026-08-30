import 'package:flutter_test/flutter_test.dart';
import 'package:vanity_tracker/core/utils/date_utils.dart';
import 'package:vanity_tracker/models/vanity_item_model.dart';

void main() {
  group('Cost-Per-Day and Budget Tests', () {
    test('Calculates cost per day accurately for finished product', () {
      final opened = DateTime(2025, 1, 1);
      final finished = DateTime(2025, 4, 1); // 90 days
      const price = 45.00;

      final costPerDay = VanityDateUtils.calculateCostPerDay(price, opened, finished);
      expect(costPerDay, closeTo(0.50, 0.01)); // $45 / 90 days = $0.50/day
    });

    test('Handles 0 days or same day finished gracefully with min 1 day', () {
      final opened = DateTime(2025, 1, 1);
      final finished = DateTime(2025, 1, 1);
      const price = 25.00;

      final costPerDay = VanityDateUtils.calculateCostPerDay(price, opened, finished);
      expect(costPerDay, 25.00);
    });

    test('Returns null when price is missing or 0', () {
      final opened = DateTime(2025, 1, 1);
      final finished = DateTime(2025, 3, 1);

      expect(VanityDateUtils.calculateCostPerDay(null, opened, finished), isNull);
      expect(VanityDateUtils.calculateCostPerDay(0.0, opened, finished), isNull);
    });

    test('VanityItemModel costPerDay getter evaluates properly', () {
      final item = VanityItemModel(
        vanityItemId: 'item_test',
        productId: 'p_test',
        userId: 'user_1',
        productName: 'Dew Drops',
        brand: 'Glow Recipe',
        categoryId: 'serum',
        paoMonths: 12,
        price: 35.00,
        openedDate: DateTime.now().subtract(const Duration(days: 70)),
        status: VanityStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 75)),
      );

      expect(item.daysInUse, 70);
      expect(item.costPerDay, closeTo(0.50, 0.01));
    });
  });
}
