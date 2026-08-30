import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vanity_item_model.dart';
import '../models/product_model.dart';
import 'vanity_repository.dart';

class FirestoreRepository implements VanityRepository {
  final FirebaseFirestore _firestore;

  FirestoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      _firestore.collection('vanity_items');

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  @override
  Stream<List<VanityItemModel>> streamVanityItems(String userId) {
    return _itemsCollection
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        return VanityItemModel.fromMap(doc.data(), doc.id);
      }).where((item) => item.finishedDate == null && item.status != VanityStatus.finished).toList();

      // Sort by days-until-expiry ascending (unopened at the end or prioritized)
      items.sort((a, b) {
        final aDays = a.daysUntilExpiry();
        final bDays = b.daysUntilExpiry();
        if (aDays == null && bDays == null) return 0;
        if (aDays == null) return 1;
        if (bDays == null) return -1;
        return aDays.compareTo(bDays);
      });

      return items;
    });
  }

  @override
  Stream<List<VanityItemModel>> streamFinishedItems(String userId) {
    return _itemsCollection
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => VanityItemModel.fromMap(doc.data(), doc.id))
          .where((item) => item.finishedDate != null || item.status == VanityStatus.finished)
          .toList();

      items.sort((a, b) {
        final aDate = a.finishedDate ?? DateTime(2000);
        final bDate = b.finishedDate ?? DateTime(2000);
        return bDate.compareTo(aDate); // Most recently finished first
      });

      return items;
    });
  }

  @override
  Future<VanityItemModel> addVanityItem(VanityItemModel item) async {
    try {
      final docRef = _itemsCollection.doc(
        item.vanityItemId.isNotEmpty ? item.vanityItemId : null,
      );
      final itemToSave = item.copyWith(vanityItemId: docRef.id);
      await docRef.set(itemToSave.toMap());
      return itemToSave;
    } catch (e) {
      dev.log('Error adding vanity item to Firestore: $e', name: 'FirestoreRepository');
      rethrow;
    }
  }

  @override
  Future<void> updateVanityItem(VanityItemModel item) async {
    try {
      await _itemsCollection.doc(item.vanityItemId).update(item.toMap());
    } catch (e) {
      dev.log('Error updating vanity item in Firestore: $e', name: 'FirestoreRepository');
      rethrow;
    }
  }

  @override
  Future<void> deleteVanityItem(String vanityItemId) async {
    try {
      await _itemsCollection.doc(vanityItemId).delete();
    } catch (e) {
      dev.log('Error deleting vanity item from Firestore: $e', name: 'FirestoreRepository');
      rethrow;
    }
  }

  @override
  Future<void> saveProduct(ProductModel product) async {
    try {
      await _productsCollection.doc(product.productId).set(
            product.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      dev.log('Error saving product to Firestore: $e', name: 'FirestoreRepository');
    }
  }

  @override
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      final query = await _productsCollection
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return ProductModel.fromMap(doc.data(), doc.id);
      }
    } catch (e) {
      dev.log('Error getting product by barcode from Firestore: $e', name: 'FirestoreRepository');
    }
    return null;
  }
}
