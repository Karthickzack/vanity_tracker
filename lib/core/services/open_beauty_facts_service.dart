import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../../models/product_model.dart';
import '../../models/category_model.dart';

class OpenBeautyFactsService {
  static const String _baseUrl = 'https://world.openbeautyfacts.org/api/v2/product';
  final http.Client _client;

  OpenBeautyFactsService({http.Client? client}) : _client = client ?? http.Client();

  /// Queries Open Beauty Facts API by barcode.
  /// Returns a populated [ProductModel] if found, or `null` if not found / network failure.
  Future<ProductModel?> lookupBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    final url = Uri.parse('$_baseUrl/$cleanBarcode.json');
    try {
      dev.log('Looking up barcode: $cleanBarcode at $url', name: 'OpenBeautyFacts');
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'VanityTrackerApp/1.0 (contact: info@vanitytracker.app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'];
        if (status == 1 && data['product'] != null) {
          final productData = data['product'] as Map<String, dynamic>;
          return _parseProductData(cleanBarcode, productData);
        }
      } else {
        dev.log('API returned status code: ${response.statusCode}', name: 'OpenBeautyFacts');
      }
    } catch (e, stack) {
      dev.log('Error querying Open Beauty Facts: $e', name: 'OpenBeautyFacts', error: e, stackTrace: stack);
    }
    return null;
  }

  /// Parses Open Beauty Facts API response into our internal [ProductModel]
  ProductModel _parseProductData(String barcode, Map<String, dynamic> product) {
    final productName = product['product_name'] as String? ??
        product['product_name_en'] as String? ??
        product['generic_name'] as String? ??
        'Beauty Product';

    final brand = product['brands'] as String? ??
        product['brand_owner'] as String? ??
        'Brand Unknown';

    final imageUrl = product['image_front_url'] as String? ??
        product['image_url'] as String? ??
        product['image_small_url'] as String?;

    final volume = product['quantity'] as String? ?? product['volume'] as String?;

    // Try to guess or match category
    final categoryTags = (product['categories_tags'] as List<dynamic>?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        [];
    final categoryString = product['categories'] as String? ?? '';

    final detectedCategoryId = _matchCategory(categoryTags, categoryString, productName);
    final category = CategoryModel.findById(detectedCategoryId);

    return ProductModel(
      productId: 'p_$barcode',
      barcode: barcode,
      name: productName.trim(),
      brand: brand.split(',').first.trim(),
      categoryId: category.categoryId,
      paoMonths: category.defaultPaoMonths,
      imageUrl: imageUrl,
      volume: volume,
    );
  }

  /// Helper to map API category tags to our standard category IDs
  String _matchCategory(List<String> tags, String categoriesText, String name) {
    final combined = '${tags.join(' ')} $categoriesText $name'.toLowerCase();

    if (combined.contains('mascara')) return 'mascara';
    if (combined.contains('sunscreen') || combined.contains('sun') || combined.contains('spf')) return 'sunscreen';
    if (combined.contains('serum') || combined.contains('ampoule')) return 'serum';
    if (combined.contains('lipstick') || combined.contains('lip gloss') || combined.contains('lip balm')) return 'lipstick';
    if (combined.contains('foundation') || combined.contains('bb cream') || combined.contains('cc cream') || combined.contains('concealer')) return 'foundation';
    if (combined.contains('eye cream') || combined.contains('eye contour')) return 'eye_cream';
    if (combined.contains('toner') || combined.contains('essence') || combined.contains('lotion')) return 'toner';
    if (combined.contains('cleanser') || combined.contains('micellar') || combined.contains('foam') || combined.contains('face wash')) return 'cleanser';
    if (combined.contains('moisturizer') || combined.contains('cream') || combined.contains('gel') || combined.contains('hydrat')) return 'moisturizer';

    return 'serum'; // Default fallback
  }
}
