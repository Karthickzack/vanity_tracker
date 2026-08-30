import 'dart:async';
import '../models/vanity_item_model.dart';
import '../models/product_model.dart';
import '../core/utils/date_utils.dart';
import 'vanity_repository.dart';

class LocalDemoRepository implements VanityRepository {
  final List<VanityItemModel> _items = [];
  final Map<String, ProductModel> _products = {};

  final _activeItemsController = StreamController<List<VanityItemModel>>.broadcast();
  final _finishedItemsController = StreamController<List<VanityItemModel>>.broadcast();

  LocalDemoRepository() {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();

    // 1. Fresh Item (> 30 days - GREEN)
    final hyaluronicOpened = now.subtract(const Duration(days: 45));
    final hyaluronicExpiry = VanityDateUtils.calculateExpiryDate(hyaluronicOpened, 12);
    final hyaluronic = VanityItemModel(
      vanityItemId: 'item_1',
      productId: 'p_the_ordinary_ha',
      userId: 'demo_user_1',
      productName: 'Hyaluronic Acid 2% + B5',
      brand: 'The Ordinary',
      categoryId: 'serum',
      paoMonths: 12,
      barcode: '769915190198',
      volume: '30ml',
      imageUrl: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400',
      openedDate: hyaluronicOpened,
      expiryDate: hyaluronicExpiry,
      status: VanityStatus.active,
      price: 8.90,
      createdAt: now.subtract(const Duration(days: 50)),
    );

    // 2. Expiring Soon Item (0 - 30 days - AMBER)
    // Opened 2.5 months ago with 3 months PAO (Mascara)
    final mascaraOpened = now.subtract(const Duration(days: 75));
    final mascaraExpiry = VanityDateUtils.calculateExpiryDate(mascaraOpened, 3);
    final mascara = VanityItemModel(
      vanityItemId: 'item_2',
      productId: 'p_sky_high_mascara',
      userId: 'demo_user_1',
      productName: 'Lash Sensational Sky High Mascara',
      brand: 'Maybelline',
      categoryId: 'mascara',
      paoMonths: 3,
      barcode: '041554590500',
      volume: '7.2ml',
      imageUrl: 'https://images.unsplash.com/photo-1631214524020-7e18db9a8f92?w=400',
      openedDate: mascaraOpened,
      expiryDate: mascaraExpiry,
      status: VanityStatus.expiring,
      price: 12.99,
      createdAt: now.subtract(const Duration(days: 80)),
    );

    // 3. Expired Item (< 0 days - RED)
    // Opened 14 months ago with 12 months PAO (Sunscreen)
    final sunscreenOpened = now.subtract(const Duration(days: 420));
    final sunscreenExpiry = VanityDateUtils.calculateExpiryDate(sunscreenOpened, 12);
    final sunscreen = VanityItemModel(
      vanityItemId: 'item_3',
      productId: 'p_laroche_anthelios',
      userId: 'demo_user_1',
      productName: 'Anthelios UVmune 400 Invisible Fluid SPF50+',
      brand: 'La Roche-Posay',
      categoryId: 'sunscreen',
      paoMonths: 12,
      barcode: '3337875777798',
      volume: '50ml',
      imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400',
      openedDate: sunscreenOpened,
      expiryDate: sunscreenExpiry,
      status: VanityStatus.expired,
      price: 22.50,
      createdAt: now.subtract(const Duration(days: 430)),
    );

    // 4. Unopened Item (New in box / Back-up)
    final moisturizer = VanityItemModel(
      vanityItemId: 'item_4',
      productId: 'p_cerave_cream',
      userId: 'demo_user_1',
      productName: 'Moisturizing Cream with Ceramides',
      brand: 'CeraVe',
      categoryId: 'moisturizer',
      paoMonths: 12,
      barcode: '3337875597372',
      volume: '454g',
      imageUrl: 'https://images.unsplash.com/photo-1608248597359-54d9c490a07e?w=400',
      openedDate: null,
      expiryDate: null,
      status: VanityStatus.unopened,
      price: 19.99,
      createdAt: now.subtract(const Duration(days: 10)),
    );

    // 5. Finished Item (Increment 2 Empties History)
    final finishedSerumOpened = now.subtract(const Duration(days: 180));
    final finishedSerumExpiry = VanityDateUtils.calculateExpiryDate(finishedSerumOpened, 12);
    final finishedSerum = VanityItemModel(
      vanityItemId: 'item_5',
      productId: 'p_glow_recipe_dew',
      userId: 'demo_user_1',
      productName: 'Watermelon Glow Niacinamide Dew Drops',
      brand: 'Glow Recipe',
      categoryId: 'serum',
      paoMonths: 12,
      barcode: '850019443015',
      volume: '40ml',
      imageUrl: 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=400',
      openedDate: finishedSerumOpened,
      expiryDate: finishedSerumExpiry,
      status: VanityStatus.finished,
      price: 35.00,
      finishedDate: now.subtract(const Duration(days: 15)),
      wouldRepurchase: true,
      createdAt: now.subtract(const Duration(days: 190)),
    );

    // 6. Another Finished Item (Not repurchased)
    final finishedCleanserOpened = now.subtract(const Duration(days: 120));
    final finishedCleanserExpiry = VanityDateUtils.calculateExpiryDate(finishedCleanserOpened, 12);
    final finishedCleanser = VanityItemModel(
      vanityItemId: 'item_6',
      productId: 'p_drunk_elephant_cleanser',
      userId: 'demo_user_1',
      productName: 'Beste No. 9 Jelly Cleanser',
      brand: 'Drunk Elephant',
      categoryId: 'cleanser',
      paoMonths: 12,
      barcode: '856545006093',
      volume: '150ml',
      imageUrl: 'https://images.unsplash.com/photo-1556228722-d0b5b03513a9?w=400',
      openedDate: finishedCleanserOpened,
      expiryDate: finishedCleanserExpiry,
      status: VanityStatus.finished,
      price: 34.00,
      finishedDate: now.subtract(const Duration(days: 30)),
      wouldRepurchase: false,
      createdAt: now.subtract(const Duration(days: 130)),
    );

    _items.addAll([hyaluronic, mascara, sunscreen, moisturizer, finishedSerum, finishedCleanser]);
    _notifyStreams();
  }

  void _notifyStreams() {
    final active = _items
        .where((i) => i.finishedDate == null && i.status != VanityStatus.finished)
        .toList();

    // Sort by days until expiry ascending
    active.sort((a, b) {
      final aDays = a.daysUntilExpiry();
      final bDays = b.daysUntilExpiry();
      if (aDays == null && bDays == null) return 0;
      if (aDays == null) return 1;
      if (bDays == null) return -1;
      return aDays.compareTo(bDays);
    });

    final finished = _items
        .where((i) => i.finishedDate != null || i.status == VanityStatus.finished)
        .toList();

    finished.sort((a, b) {
      final aDate = a.finishedDate ?? DateTime(2000);
      final bDate = b.finishedDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    _activeItemsController.add(List.unmodifiable(active));
    _finishedItemsController.add(List.unmodifiable(finished));
  }

  @override
  Stream<List<VanityItemModel>> streamVanityItems(String userId) {
    // Immediate emission
    Timer.run(() => _notifyStreams());
    return _activeItemsController.stream;
  }

  @override
  Stream<List<VanityItemModel>> streamFinishedItems(String userId) {
    Timer.run(() => _notifyStreams());
    return _finishedItemsController.stream;
  }

  @override
  Future<VanityItemModel> addVanityItem(VanityItemModel item) async {
    final newItem = item.vanityItemId.isNotEmpty
        ? item
        : item.copyWith(
            vanityItemId: 'item_${DateTime.now().millisecondsSinceEpoch}',
          );
    _items.add(newItem);
    _notifyStreams();
    return newItem;
  }

  @override
  Future<void> updateVanityItem(VanityItemModel item) async {
    final index = _items.indexWhere((i) => i.vanityItemId == item.vanityItemId);
    if (index >= 0) {
      _items[index] = item;
      _notifyStreams();
    }
  }

  @override
  Future<void> deleteVanityItem(String vanityItemId) async {
    _items.removeWhere((i) => i.vanityItemId == vanityItemId);
    _notifyStreams();
  }

  @override
  Future<void> saveProduct(ProductModel product) async {
    _products[product.productId] = product;
    if (product.barcode != null) {
      _products[product.barcode!] = product;
    }
  }

  @override
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    return _products[barcode];
  }

  void dispose() {
    _activeItemsController.close();
    _finishedItemsController.close();
  }
}
