import '../models/vanity_item_model.dart';
import '../models/product_model.dart';

abstract class VanityRepository {
  /// Stream or list of all active/expiring/expired vanity items for a user
  Stream<List<VanityItemModel>> streamVanityItems(String userId);

  /// Stream of finished / emptied vanity items for history
  Stream<List<VanityItemModel>> streamFinishedItems(String userId);

  /// Add a new vanity item
  Future<VanityItemModel> addVanityItem(VanityItemModel item);

  /// Update an existing vanity item (e.g. mark opened, mark finished, update repurchase)
  Future<void> updateVanityItem(VanityItemModel item);

  /// Delete a vanity item
  Future<void> deleteVanityItem(String vanityItemId);

  /// Save or cache a product definition
  Future<void> saveProduct(ProductModel product);

  /// Find product by barcode
  Future<ProductModel?> getProductByBarcode(String barcode);
}
