import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vanity_tracker/core/services/open_beauty_facts_service.dart';

void main() {
  group('OpenBeautyFactsService Tests', () {
    test('Successfully looks up and parses product JSON', () async {
      final mockResponse = {
        'status': 1,
        'product': {
          'product_name': 'Lash Sensational Sky High Mascara',
          'brands': 'Maybelline New York',
          'categories_tags': ['en:mascaras', 'en:eye-makeup'],
          'categories': 'Makeup, Mascara',
          'quantity': '7.2 ml',
          'image_front_url': 'https://images.openbeautyfacts.org/sample.jpg',
        }
      };

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('041554590500')) {
          return http.Response(jsonEncode(mockResponse), 200);
        }
        return http.Response(jsonEncode({'status': 0}), 404);
      });

      final service = OpenBeautyFactsService(client: mockClient);
      final product = await service.lookupBarcode('041554590500');

      expect(product, isNotNull);
      expect(product!.name, 'Lash Sensational Sky High Mascara');
      expect(product.brand, 'Maybelline New York');
      expect(product.categoryId, 'mascara');
      expect(product.paoMonths, 3); // Default Mascara PAO
      expect(product.volume, '7.2 ml');
      expect(product.imageUrl, 'https://images.openbeautyfacts.org/sample.jpg');
    });

    test('Returns null when barcode is not found', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'status': 0}), 200);
      });

      final service = OpenBeautyFactsService(client: mockClient);
      final product = await service.lookupBarcode('9999999999999');

      expect(product, isNull);
    });

    test('Correctly maps Sunscreen category and assigns 12 months PAO', () async {
      final mockResponse = {
        'status': 1,
        'product': {
          'product_name': 'Anthelios Ultra-Light Fluid SPF 50+',
          'brands': 'La Roche-Posay',
          'categories_tags': ['en:sunscreens', 'en:face-sunscreen'],
          'categories': 'Sun care, Sunscreen',
        }
      };

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = OpenBeautyFactsService(client: mockClient);
      final product = await service.lookupBarcode('3337875777798');

      expect(product, isNotNull);
      expect(product!.categoryId, 'sunscreen');
      expect(product.paoMonths, 12);
    });
  });
}
