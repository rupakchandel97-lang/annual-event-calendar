import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EventCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EventCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories(String familyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('familyId', isEqualTo: familyId)
          .get();

      _categories = snapshot.docs
          .map((doc) => EventCategory.fromFirestore(doc))
          .toList();

      // Add default categories if none exist
      if (_categories.isEmpty) {
        await _addDefaultCategories(familyId);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _addDefaultCategories(String familyId) async {
    final defaults = [
      ('Sports', 0xFF4CAF50),
      ('School', 0xFF2196F3),
      ('Birthday', 0xFFFF9800),
      ('Holiday', 0xFFE91E63),
      ('Doctor', 0xFFF44336),
      ('Entertainment', 0xFF9C27B0),
    ];

    for (final (name, color) in defaults) {
      await addCategory(
        familyId: familyId,
        name: name,
        color: Color(color),
      );
    }
  }

  Future<void> addCategory({
    required String familyId,
    required String name,
    required Color color,
    String? icon,
    String? description,
  }) async {
    try {
      final newCategory = EventCategory(
        id: _firestore.collection('categories').doc().id,
        familyId: familyId,
        name: name,
        icon: icon,
        colorValue: color.value,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('categories')
          .doc(newCategory.id)
          .set(newCategory.toFirestore());

      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required Color color,
    String? icon,
    String? description,
  }) async {
    try {
      final index =
          _categories.indexWhere((cat) => cat.id == categoryId);
      if (index != -1) {
        final updated = _categories[index].copyWith(
          name: name,
          colorValue: color.value,
          icon: icon,
          description: description,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('categories')
            .doc(categoryId)
            .update(updated.toFirestore());

        _categories[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
      _categories.removeWhere((cat) => cat.id == categoryId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  EventCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}
