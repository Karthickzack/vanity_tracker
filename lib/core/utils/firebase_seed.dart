import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';

class FirebaseSeedService {
  /// Seeds default categories into Cloud Firestore in Test Mode
  static Future<void> seedDefaultCategories() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final categoriesCollection = firestore.collection('categories');

      for (final cat in CategoryModel.defaultCategories) {
        final docRef = categoriesCollection.doc(cat.categoryId);
        batch.set(docRef, cat.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      dev.log('Successfully seeded default categories into Firestore', name: 'FirebaseSeed');
    } catch (e) {
      dev.log('Error seeding Firestore categories: $e', name: 'FirebaseSeed');
    }
  }
}
