import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vanity_item_model.dart';
import '../models/product_model.dart';
import '../repositories/vanity_repository.dart';
import '../core/services/open_beauty_facts_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/date_utils.dart';

class VanityProvider extends ChangeNotifier {
  final VanityRepository _repository;
  final OpenBeautyFactsService _beautyFactsService;
  final NotificationService _notificationService;
  final String _userId;

  List<VanityItemModel> _activeItems = [];
  List<VanityItemModel> _finishedItems = [];
  bool _isLoading = false;
  String? _selectedCategory;
  String _searchQuery = '';

  StreamSubscription? _activeSub;
  StreamSubscription? _finishedSub;

  VanityProvider({
    required VanityRepository repository,
    required OpenBeautyFactsService beautyFactsService,
    required NotificationService notificationService,
    required String userId,
  })  : _repository = repository,
        _beautyFactsService = beautyFactsService,
        _notificationService = notificationService,
        _userId = userId {
    _subscribe();
  }

  // Getters
  List<VanityItemModel> get activeItems => _filterItems(_activeItems);
  List<VanityItemModel> get allActiveItemsRaw => _activeItems;
  List<VanityItemModel> get finishedItems => _filterItems(_finishedItems);
  List<VanityItemModel> get allFinishedItemsRaw => _finishedItems;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Counts
  int get totalActiveCount => _activeItems.where((i) => i.computedStatus == VanityStatus.active).length;
  int get totalExpiringCount => _activeItems.where((i) => i.computedStatus == VanityStatus.expiring).length;
  int get totalExpiredCount => _activeItems.where((i) => i.computedStatus == VanityStatus.expired).length;
  int get totalUnopenedCount => _activeItems.where((i) => i.computedStatus == VanityStatus.unopened).length;
  int get totalFinishedCount => _finishedItems.length;

  // Budget & Stats
  double get totalActiveVanityValue => _activeItems.fold(0.0, (sum, i) => sum + (i.price ?? 0.0));
  double get totalFinishedValue => _finishedItems.fold(0.0, (sum, i) => sum + (i.price ?? 0.0));
  double get totalLifetimeValue => totalActiveVanityValue + totalFinishedValue;

  double? get averageCostPerDay {
    final finishedWithCost = _finishedItems.where((i) => i.costPerDay != null).toList();
    if (finishedWithCost.isEmpty) return null;
    final total = finishedWithCost.fold(0.0, (sum, i) => sum + i.costPerDay!);
    return total / finishedWithCost.length;
  }

  double get repurchaseRatePercentage {
    final ratedItems = _finishedItems.where((i) => i.wouldRepurchase != null).toList();
    if (ratedItems.isEmpty) return 0.0;
    final yesCount = ratedItems.where((i) => i.wouldRepurchase == true).length;
    return (yesCount / ratedItems.length) * 100;
  }

  void _subscribe() {
    _isLoading = true;
    notifyListeners();

    _activeSub = _repository.streamVanityItems(_userId).listen((items) {
      _activeItems = items;
      _isLoading = false;
      notifyListeners();
    });

    _finishedSub = _repository.streamFinishedItems(_userId).listen((items) {
      _finishedItems = items;
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSelectedCategory(String? categoryId) {
    _selectedCategory = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  List<VanityItemModel> _filterItems(List<VanityItemModel> list) {
    return list.where((item) {
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          item.categoryId.toLowerCase() == _selectedCategory!.toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          item.productName.toLowerCase().contains(_searchQuery) ||
          item.brand.toLowerCase().contains(_searchQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Mark product as opened today (or on a given date) and compute expiry
  Future<void> markAsOpened(VanityItemModel item, {DateTime? openedDate}) async {
    final opened = openedDate ?? DateTime.now();
    final expiry = VanityDateUtils.calculateExpiryDate(opened, item.paoMonths);
    final updated = item.copyWith(
      openedDate: opened,
      expiryDate: expiry,
      status: VanityStatus.active,
    );

    await _repository.updateVanityItem(updated);
    await _notificationService.scheduleExpiryNotifications(updated);
  }

  /// Mark product as finished, prompt repurchase, and move to empties
  Future<void> markAsFinished(VanityItemModel item, {bool? wouldRepurchase, DateTime? finishedDate}) async {
    final updated = item.copyWith(
      finishedDate: finishedDate ?? DateTime.now(),
      status: VanityStatus.finished,
      wouldRepurchase: wouldRepurchase,
    );

    await _repository.updateVanityItem(updated);
    await _notificationService.cancelNotificationsForItem(item.vanityItemId);
  }

  /// Add new vanity item
  Future<VanityItemModel> addProduct({
    required String name,
    required String brand,
    required String categoryId,
    required int paoMonths,
    String? barcode,
    String? volume,
    String? imageUrl,
    double? price,
    bool openedToday = false,
  }) async {
    final now = DateTime.now();
    DateTime? opened;
    DateTime? expiry;
    VanityStatus status = VanityStatus.unopened;

    if (openedToday) {
      opened = now;
      expiry = VanityDateUtils.calculateExpiryDate(now, paoMonths);
      status = VanityStatus.active;
    }

    final item = VanityItemModel(
      vanityItemId: '',
      productId: barcode != null && barcode.isNotEmpty ? 'p_$barcode' : 'p_${now.millisecondsSinceEpoch}',
      userId: _userId,
      productName: name,
      brand: brand,
      categoryId: categoryId,
      paoMonths: paoMonths,
      barcode: barcode,
      volume: volume,
      imageUrl: imageUrl,
      price: price,
      openedDate: opened,
      expiryDate: expiry,
      status: status,
      createdAt: now,
    );

    final savedItem = await _repository.addVanityItem(item);

    if (openedToday) {
      await _notificationService.scheduleExpiryNotifications(savedItem);
    }

    return savedItem;
  }

  /// Delete vanity item
  Future<void> deleteItem(String vanityItemId) async {
    await _repository.deleteVanityItem(vanityItemId);
    await _notificationService.cancelNotificationsForItem(vanityItemId);
  }

  /// Lookup barcode via Open Beauty Facts API
  Future<ProductModel?> lookupBarcode(String barcode) async {
    // Check local cache first
    final cached = await _repository.getProductByBarcode(barcode);
    if (cached != null) return cached;

    // Fetch from Open Beauty Facts API
    final apiProduct = await _beautyFactsService.lookupBarcode(barcode);
    if (apiProduct != null) {
      await _repository.saveProduct(apiProduct);
    }
    return apiProduct;
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    _finishedSub?.cancel();
    super.dispose();
  }
}
