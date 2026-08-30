class ProductModel {
  final String productId;
  final String? barcode;
  final String name;
  final String brand;
  final String categoryId;
  final int paoMonths;
  final String? imageUrl;
  final String? volume;

  const ProductModel({
    required this.productId,
    this.barcode,
    required this.name,
    required this.brand,
    required this.categoryId,
    required this.paoMonths,
    this.imageUrl,
    this.volume,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      productId: id,
      barcode: map['barcode'] as String?,
      name: map['name'] as String? ?? 'Unnamed Product',
      brand: map['brand'] as String? ?? 'Generic Brand',
      categoryId: map['category_id'] as String? ?? 'serum',
      paoMonths: (map['pao_months'] as num?)?.toInt() ?? 12,
      imageUrl: map['image_url'] as String?,
      volume: map['volume'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      if (barcode != null) 'barcode': barcode,
      'name': name,
      'brand': brand,
      'category_id': categoryId,
      'pao_months': paoMonths,
      if (imageUrl != null) 'image_url': imageUrl,
      if (volume != null) 'volume': volume,
    };
  }

  ProductModel copyWith({
    String? productId,
    String? barcode,
    String? name,
    String? brand,
    String? categoryId,
    int? paoMonths,
    String? imageUrl,
    String? volume,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      categoryId: categoryId ?? this.categoryId,
      paoMonths: paoMonths ?? this.paoMonths,
      imageUrl: imageUrl ?? this.imageUrl,
      volume: volume ?? this.volume,
    );
  }
}
