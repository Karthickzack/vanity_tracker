import 'package:intl/intl.dart';

enum VanityStatus {
  unopened,
  active,
  expiring,
  expired,
  finished;

  static VanityStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'unopened':
        return VanityStatus.unopened;
      case 'active':
        return VanityStatus.active;
      case 'expiring':
      case 'expiring_soon':
        return VanityStatus.expiring;
      case 'expired':
        return VanityStatus.expired;
      case 'finished':
        return VanityStatus.finished;
      default:
        return VanityStatus.unopened;
    }
  }

  String get nameString {
    switch (this) {
      case VanityStatus.unopened:
        return 'unopened';
      case VanityStatus.active:
        return 'active';
      case VanityStatus.expiring:
        return 'expiring';
      case VanityStatus.expired:
        return 'expired';
      case VanityStatus.finished:
        return 'finished';
    }
  }
}

class VanityItemModel {
  final String vanityItemId;
  final String productId;
  final String userId;
  final String productName;
  final String brand;
  final String categoryId;
  final int paoMonths;
  final String? barcode;
  final String? imageUrl;
  final String? volume;
  final DateTime? openedDate;
  final DateTime? expiryDate;
  final VanityStatus status;
  final double? price;
  final DateTime? finishedDate;
  final bool? wouldRepurchase;
  final DateTime createdAt;

  const VanityItemModel({
    required this.vanityItemId,
    required this.productId,
    required this.userId,
    required this.productName,
    required this.brand,
    required this.categoryId,
    required this.paoMonths,
    this.barcode,
    this.imageUrl,
    this.volume,
    this.openedDate,
    this.expiryDate,
    required this.status,
    this.price,
    this.finishedDate,
    this.wouldRepurchase,
    required this.createdAt,
  });

  /// Computed days until expiry from given reference date (default: now)
  int? daysUntilExpiry([DateTime? referenceDate]) {
    if (expiryDate == null) return null;
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return target.difference(today).inDays;
  }

  /// Computed status based on dates
  VanityStatus get computedStatus {
    if (finishedDate != null || status == VanityStatus.finished) {
      return VanityStatus.finished;
    }
    if (openedDate == null || expiryDate == null) {
      return VanityStatus.unopened;
    }
    final days = daysUntilExpiry();
    if (days == null) return VanityStatus.unopened;
    if (days < 0) return VanityStatus.expired;
    if (days <= 30) return VanityStatus.expiring;
    return VanityStatus.active;
  }

  /// Total days the product was in use (opened to finished, or opened to today)
  int get daysInUse {
    if (openedDate == null) return 0;
    final endDate = finishedDate ?? DateTime.now();
    final diff = endDate.difference(openedDate!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  /// Cost per day used (price / daysInUse)
  double? get costPerDay {
    if (price == null || price! <= 0 || openedDate == null) return null;
    final days = daysInUse;
    if (days <= 0) return price;
    return price! / days;
  }

  String get formattedOpenedDate =>
      openedDate != null ? DateFormat.yMMMd().format(openedDate!) : 'Not opened yet';

  String get formattedExpiryDate =>
      expiryDate != null ? DateFormat.yMMMd().format(expiryDate!) : 'N/A';

  String get formattedFinishedDate =>
      finishedDate != null ? DateFormat.yMMMd().format(finishedDate!) : 'N/A';

  factory VanityItemModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      // If Firestore Timestamp
      if (val.runtimeType.toString().contains('Timestamp')) {
        try {
          return (val as dynamic).toDate();
        } catch (_) {}
      }
      return null;
    }

    final rawOpened = parseDate(map['opened_date']);
    final rawExpiry = parseDate(map['expiry_date']);
    final rawFinished = parseDate(map['finished_date']);
    final rawCreated = parseDate(map['created_at']) ?? DateTime.now();

    return VanityItemModel(
      vanityItemId: id,
      productId: map['product_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      productName: map['name'] as String? ?? map['product_name'] as String? ?? 'Skincare Item',
      brand: map['brand'] as String? ?? 'Brand',
      categoryId: map['category_id'] as String? ?? 'serum',
      paoMonths: (map['pao_months'] as num?)?.toInt() ?? 12,
      barcode: map['barcode'] as String?,
      imageUrl: map['image_url'] as String?,
      volume: map['volume'] as String?,
      openedDate: rawOpened,
      expiryDate: rawExpiry,
      status: VanityStatus.fromString(map['status'] as String?),
      price: (map['price'] as num?)?.toDouble(),
      finishedDate: rawFinished,
      wouldRepurchase: map['would_repurchase'] as bool?,
      createdAt: rawCreated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vanity_item_id': vanityItemId,
      'product_id': productId,
      'user_id': userId,
      'name': productName,
      'brand': brand,
      'category_id': categoryId,
      'pao_months': paoMonths,
      if (barcode != null) 'barcode': barcode,
      if (imageUrl != null) 'image_url': imageUrl,
      if (volume != null) 'volume': volume,
      if (openedDate != null) 'opened_date': openedDate!.toIso8601String(),
      if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String(),
      'status': computedStatus.nameString,
      if (price != null) 'price': price,
      if (finishedDate != null) 'finished_date': finishedDate!.toIso8601String(),
      if (wouldRepurchase != null) 'would_repurchase': wouldRepurchase,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VanityItemModel copyWith({
    String? vanityItemId,
    String? productId,
    String? userId,
    String? productName,
    String? brand,
    String? categoryId,
    int? paoMonths,
    String? barcode,
    String? imageUrl,
    String? volume,
    DateTime? openedDate,
    DateTime? expiryDate,
    VanityStatus? status,
    double? price,
    DateTime? finishedDate,
    bool? wouldRepurchase,
    DateTime? createdAt,
  }) {
    return VanityItemModel(
      vanityItemId: vanityItemId ?? this.vanityItemId,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      paoMonths: paoMonths ?? this.paoMonths,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      volume: volume ?? this.volume,
      openedDate: openedDate ?? this.openedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      price: price ?? this.price,
      finishedDate: finishedDate ?? this.finishedDate,
      wouldRepurchase: wouldRepurchase ?? this.wouldRepurchase,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
