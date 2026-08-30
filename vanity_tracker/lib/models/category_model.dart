class CategoryModel {
  final String categoryId;
  final String categoryName;
  final int defaultPaoMonths;
  final String iconName;

  const CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.defaultPaoMonths,
    this.iconName = 'sparkles',
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      categoryId: id,
      categoryName: map['category_name'] as String? ?? 'General',
      defaultPaoMonths: (map['default_pao_months'] as num?)?.toInt() ?? 12,
      iconName: map['icon_name'] as String? ?? 'sparkles',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'default_pao_months': defaultPaoMonths,
      'icon_name': iconName,
    };
  }

  /// Default categories seed as specified in requirements
  static List<CategoryModel> get defaultCategories => const [
        CategoryModel(
          categoryId: 'serum',
          categoryName: 'Serum',
          defaultPaoMonths: 12,
          iconName: 'water_drop',
        ),
        CategoryModel(
          categoryId: 'sunscreen',
          categoryName: 'Sunscreen',
          defaultPaoMonths: 12,
          iconName: 'wb_sunny',
        ),
        CategoryModel(
          categoryId: 'mascara',
          categoryName: 'Mascara',
          defaultPaoMonths: 3,
          iconName: 'remove_red_eye',
        ),
        CategoryModel(
          categoryId: 'foundation',
          categoryName: 'Foundation',
          defaultPaoMonths: 12,
          iconName: 'face',
        ),
        CategoryModel(
          categoryId: 'lipstick',
          categoryName: 'Lipstick',
          defaultPaoMonths: 24,
          iconName: 'brush',
        ),
        CategoryModel(
          categoryId: 'moisturizer',
          categoryName: 'Moisturizer',
          defaultPaoMonths: 12,
          iconName: 'spa',
        ),
        CategoryModel(
          categoryId: 'cleanser',
          categoryName: 'Cleanser',
          defaultPaoMonths: 12,
          iconName: 'cleaning_services',
        ),
        CategoryModel(
          categoryId: 'eye_cream',
          categoryName: 'Eye Cream',
          defaultPaoMonths: 6,
          iconName: 'visibility',
        ),
        CategoryModel(
          categoryId: 'toner',
          categoryName: 'Toner',
          defaultPaoMonths: 12,
          iconName: 'opacity',
        ),
      ];

  static CategoryModel findById(String id) {
    return defaultCategories.firstWhere(
      (c) => c.categoryId.toLowerCase() == id.toLowerCase(),
      orElse: () => CategoryModel(
        categoryId: id,
        categoryName: id[0].toUpperCase() + id.substring(1),
        defaultPaoMonths: 12,
      ),
    );
  }
}
