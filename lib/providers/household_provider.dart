import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inventory_item_model.dart';
import '../models/shopping_history_item_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../utils/constants.dart';

class HouseholdProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _shoppingListsSubscription;
  StreamSubscription<QuerySnapshot>? _shoppingItemsSubscription;
  StreamSubscription<QuerySnapshot>? _shoppingHistorySubscription;
  StreamSubscription<QuerySnapshot>? _inventorySubscription;

  String? _userId;
  String? _familyId;
  bool _isLoading = false;
  bool _disposed = false;
  bool _notifyScheduled = false;
  String? _errorMessage;
  bool _seedingDefaults = false;

  Map<String, ShoppingList> _shoppingLists = {};
  Map<String, ShoppingItem> _shoppingItems = {};
  Map<String, ShoppingHistoryItem> _historyItems = {};
  Map<String, InventoryItem> _inventoryItems = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ShoppingList> get shoppingLists => _shoppingLists.values.toList()
    ..sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) {
        return orderCompare;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
  List<ShoppingHistoryItem> get historyItems => _historyItems.values.toList()
    ..sort((a, b) {
      final recentCompare = b.lastAddedAt.compareTo(a.lastAddedAt);
      if (recentCompare != 0) {
        return recentCompare;
      }
      return b.purchaseCount.compareTo(a.purchaseCount);
    });
  List<InventoryItem> get inventoryItems => _inventoryItems.values.toList()
    ..sort((a, b) {
      final statusWeight = <InventoryStatus, int>{
        InventoryStatus.outOfStock: 0,
        InventoryStatus.runningLow: 1,
        InventoryStatus.inStock: 2,
      };
      final compare = (statusWeight[a.status] ?? 99).compareTo(
        statusWeight[b.status] ?? 99,
      );
      if (compare != 0) {
        return compare;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  static const Map<String, List<String>> _staticShoppingListAliases = {
    'Grocery List': ['grocery list'],
    'House Project': ['house project', 'house projects'],
    'Packing List': ['packing list'],
    'Gift Ideas': ['gift ideas', 'gift idea'],
    'Trip Ideas': ['trip ideas', 'trip idea'],
    'Movies to Watch': ['movies to watch', 'movie to watch', 'moview to watch'],
    'Others': ['others', 'other'],
  };

  static const List<String> _groceryAisles = [
    'Produce',
    'Dairy',
    'Pantry',
    'Frozen',
    'Household',
  ];

  void syncSession({
    required String? userId,
    required String? familyId,
  }) {
    final userChanged = userId != _userId;
    final familyChanged = familyId != _familyId;
    if (!userChanged && !familyChanged) {
      return;
    }

    _userId = userId;
    _familyId = familyId;
    if (_userId == null || _familyId == null) {
      clear();
      return;
    }
    _startListening();
  }

  void clear() {
    _cancelSubscriptions();
    _shoppingLists = {};
    _shoppingItems = {};
    _historyItems = {};
    _inventoryItems = {};
    _isLoading = false;
    _errorMessage = null;
    _userId = null;
    _familyId = null;
    _notifySafely();
  }

  Future<void> createShoppingList({
    required String title,
    bool isShared = true,
    bool isStatic = false,
    List<String> aisleNames = const [],
  }) async {
    if (_familyId == null || _userId == null) return;
    try {
      final doc =
          _firestore.collection(AppConstants.shoppingListsCollection).doc();
      final list = ShoppingList(
        id: doc.id,
        title: title.trim(),
        familyId: _familyId!,
        createdBy: _userId!,
        isShared: isShared,
        isStatic: isStatic,
        sortOrder: _nextShoppingListSortOrder(),
        aisleNames: aisleNames.where((item) => item.trim().isNotEmpty).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await doc.set(list.toFirestore());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> ensureDefaultShoppingLists() async {
    if (_familyId == null || _userId == null || _seedingDefaults) {
      return;
    }

    _seedingDefaults = true;
    try {
      await _cleanupStaticShoppingListsOnce();

      final snapshot = await _firestore
          .collection(AppConstants.shoppingListsCollection)
          .where('familyId', isEqualTo: _familyId)
          .get();

      final existingByKey = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      final batch = _firestore.batch();
      var hasBatchUpdates = false;
      var nextSortOrder = snapshot.docs
          .map((doc) => (doc.data()['sortOrder'] as int?) ?? 0)
          .fold<int>(-1, (current, next) => next > current ? next : current) +
          1;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final title = (data['title'] as String? ?? '').trim();
        final staticKey = _canonicalStaticListTitle(title);
        if (staticKey == null) {
          continue;
        }

        existingByKey.putIfAbsent(staticKey, () => doc);

        final currentIsShared = data['isShared'] == true;
        final currentIsStatic = data['isStatic'] == true;
        final aisleNames = List<String>.from(data['aisleNames'] ?? const []);
        final expectedAisles =
            staticKey == 'Grocery List' ? _groceryAisles : const <String>[];

        if (title != staticKey ||
            !currentIsShared ||
            !currentIsStatic ||
            !_sameTrimmedList(aisleNames, expectedAisles)) {
          batch.update(doc.reference, {
            'title': staticKey,
            'isShared': true,
            'isStatic': true,
            'aisleNames': expectedAisles,
            'updatedAt': Timestamp.now(),
          });
          hasBatchUpdates = true;
        }
      }

      for (final title in _staticShoppingListAliases.keys) {
        if (existingByKey.containsKey(title)) {
          continue;
        }

        final doc =
            _firestore.collection(AppConstants.shoppingListsCollection).doc();
        final list = ShoppingList(
          id: doc.id,
          title: title,
          familyId: _familyId!,
          createdBy: _userId!,
          isShared: true,
          isStatic: true,
          sortOrder: nextSortOrder++,
          aisleNames: title == 'Grocery List' ? _groceryAisles : const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        batch.set(doc, list.toFirestore());
        hasBatchUpdates = true;
      }

      if (hasBatchUpdates) {
        await batch.commit();
      }
    } finally {
      _seedingDefaults = false;
    }
  }

  Future<void> updateShoppingList({
    required ShoppingList list,
    required String title,
    bool? isShared,
    List<String>? aisleNames,
  }) async {
    try {
      final protectedTitle = list.isStatic
          ? (_canonicalStaticListTitle(list.title) ?? list.title)
          : title.trim();
      final protectedShared = list.isStatic ? true : (isShared ?? list.isShared);
      final protectedAisles = list.isStatic
          ? (protectedTitle == 'Grocery List' ? _groceryAisles : const <String>[])
          : (aisleNames ?? list.aisleNames);
      final updated = list.copyWith(
        title: protectedTitle,
        isShared: protectedShared,
        isStatic: list.isStatic,
        aisleNames: protectedAisles,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(AppConstants.shoppingListsCollection)
          .doc(list.id)
          .update(updated.toFirestore());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> reorderShoppingLists(List<ShoppingList> orderedLists) async {
    try {
      final batch = _firestore.batch();
      for (var index = 0; index < orderedLists.length; index++) {
        final list = orderedLists[index];
        batch.update(
          _firestore.collection(AppConstants.shoppingListsCollection).doc(list.id),
          {
            'sortOrder': index,
            'updatedAt': Timestamp.now(),
          },
        );
      }
      await batch.commit();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> deleteShoppingList(ShoppingList list) async {
    if (list.isStatic) {
      _errorMessage = 'Static lists cannot be deleted.';
      _notifySafely();
      return;
    }
    try {
      final batch = _firestore.batch();
      final items = await _firestore
          .collection(AppConstants.shoppingItemsCollection)
          .where('listId', isEqualTo: list.id)
          .get();
      for (final doc in items.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(
        _firestore.collection(AppConstants.shoppingListsCollection).doc(list.id),
      );
      await batch.commit();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> addShoppingItem({
    required ShoppingList list,
    required String name,
    int quantity = 1,
    String? category,
    String? aisle,
    String? note,
  }) async {
    if (_userId == null || _familyId == null) return;
    try {
      final resolvedCategory = _resolveCategory(name, category);
      final resolvedAisle = _resolveAisle(name, aisle);
      final doc =
          _firestore.collection(AppConstants.shoppingItemsCollection).doc();
      final item = ShoppingItem(
        id: doc.id,
        listId: list.id,
        familyId: _familyId!,
        name: name.trim(),
        category: resolvedCategory,
        aisle: resolvedAisle,
        quantity: quantity,
        note: _nullableTrim(note),
        createdBy: _userId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await doc.set(item.toFirestore());
      await _touchShoppingList(list.id);
      await _upsertHistory(item);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> updateShoppingItem({
    required ShoppingItem item,
    String? name,
    int? quantity,
    String? category,
    String? aisle,
    String? note,
    bool? checked,
  }) async {
    try {
      final resolvedName = (name ?? item.name).trim();
      final updated = item.copyWith(
        name: resolvedName,
        quantity: quantity ?? item.quantity,
        category: _resolveCategory(resolvedName, category ?? item.category),
        aisle: _resolveAisle(resolvedName, aisle ?? item.aisle),
        note: _nullableTrim(note ?? item.note),
        clearNote: _nullableTrim(note ?? item.note) == null,
        checked: checked ?? item.checked,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(AppConstants.shoppingItemsCollection)
          .doc(item.id)
          .update(updated.toFirestore());
      await _touchShoppingList(item.listId);
      if (!updated.checked) {
        await _upsertHistory(updated);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> deleteShoppingItem(ShoppingItem item) async {
    try {
      await _firestore
          .collection(AppConstants.shoppingItemsCollection)
          .doc(item.id)
          .delete();
      await _touchShoppingList(item.listId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> createInventoryItem({
    required String name,
    required String category,
    String quantityLabel = '',
    String locationLabel = '',
    InventoryStatus status = InventoryStatus.inStock,
  }) async {
    if (_familyId == null || _userId == null) return;
    try {
      final doc =
          _firestore.collection(AppConstants.inventoryItemsCollection).doc();
      final item = InventoryItem(
        id: doc.id,
        familyId: _familyId!,
        name: name.trim(),
        category: category.trim(),
        quantityLabel: quantityLabel.trim(),
        locationLabel: locationLabel.trim(),
        status: status,
        createdBy: _userId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await doc.set(item.toFirestore());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> updateInventoryItem({
    required InventoryItem item,
    required String name,
    required String category,
    String quantityLabel = '',
    String locationLabel = '',
    required InventoryStatus status,
    bool? suggestedForShopping,
  }) async {
    try {
      final updated = item.copyWith(
        name: name.trim(),
        category: category.trim(),
        quantityLabel: quantityLabel.trim(),
        locationLabel: locationLabel.trim(),
        status: status,
        suggestedForShopping:
            suggestedForShopping ?? item.suggestedForShopping,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(AppConstants.inventoryItemsCollection)
          .doc(item.id)
          .update(updated.toFirestore());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> deleteInventoryItem(InventoryItem item) async {
    try {
      await _firestore
          .collection(AppConstants.inventoryItemsCollection)
          .doc(item.id)
          .delete();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _notifySafely();
    }
  }

  Future<void> addInventoryItemToShopping({
    required InventoryItem item,
    required ShoppingList list,
  }) async {
    await addShoppingItem(
      list: list,
      name: item.name,
      category: item.category,
      aisle: item.locationLabel.isEmpty ? null : item.locationLabel,
      note: item.quantityLabel,
    );
    await updateInventoryItem(
      item: item,
      name: item.name,
      category: item.category,
      quantityLabel: item.quantityLabel,
      locationLabel: item.locationLabel,
      status: item.status,
      suggestedForShopping: true,
    );
  }

  List<ShoppingItem> itemsForList(
    String listId, {
    bool includeChecked = true,
  }) {
    final items = _shoppingItems.values
        .where((item) => item.listId == listId)
        .where((item) => includeChecked || !item.checked)
        .toList()
      ..sort((a, b) {
        final checkedCompare = (a.checked ? 1 : 0).compareTo(b.checked ? 1 : 0);
        if (checkedCompare != 0) {
          return checkedCompare;
        }
        final aisleCompare = a.aisle.toLowerCase().compareTo(b.aisle.toLowerCase());
        if (aisleCompare != 0) {
          return aisleCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return items;
  }

  void _startListening() {
    _cancelSubscriptions();
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    _shoppingListsSubscription = _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('familyId', isEqualTo: _familyId)
        .snapshots()
        .listen((snapshot) {
      _shoppingLists = {
        for (final doc in snapshot.docs) doc.id: ShoppingList.fromFirestore(doc),
      };
      _markLoaded();
    }, onError: _handleError);

    _shoppingItemsSubscription = _firestore
        .collection(AppConstants.shoppingItemsCollection)
        .where('familyId', isEqualTo: _familyId)
        .snapshots()
        .listen((snapshot) {
      _shoppingItems = {
        for (final doc in snapshot.docs) doc.id: ShoppingItem.fromFirestore(doc),
      };
      _markLoaded();
    }, onError: _handleError);

    _shoppingHistorySubscription = _firestore
        .collection(AppConstants.shoppingHistoryCollection)
        .where('familyId', isEqualTo: _familyId)
        .snapshots()
        .listen((snapshot) {
      _historyItems = {
        for (final doc in snapshot.docs)
          doc.id: ShoppingHistoryItem.fromFirestore(doc),
      };
      _markLoaded();
    }, onError: _handleError);

    _inventorySubscription = _firestore
        .collection(AppConstants.inventoryItemsCollection)
        .where('familyId', isEqualTo: _familyId)
        .snapshots()
        .listen((snapshot) {
      _inventoryItems = {
        for (final doc in snapshot.docs) doc.id: InventoryItem.fromFirestore(doc),
      };
      _markLoaded();
    }, onError: _handleError);
  }

  void _markLoaded() {
    _isLoading = false;
    _notifySafely();
  }

  void _handleError(Object error) {
    _isLoading = false;
    _errorMessage = error.toString();
    _notifySafely();
  }

  Future<void> _touchShoppingList(String listId) async {
    await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .doc(listId)
        .update({'updatedAt': Timestamp.now()});
  }

  Future<void> _upsertHistory(ShoppingItem item) async {
    final historyId = '${item.familyId}_${item.name.trim().toLowerCase().replaceAll(' ', '_')}';
    final ref =
        _firestore.collection(AppConstants.shoppingHistoryCollection).doc(historyId);
    final existing = await ref.get();
    final purchaseCount = existing.exists
        ? ((existing.data()?['purchaseCount'] as int?) ?? 0) + 1
        : 1;
    await ref.set({
      'familyId': item.familyId,
      'name': item.name,
      'category': item.category,
      'aisle': item.aisle,
      'purchaseCount': purchaseCount,
      'lastAddedAt': Timestamp.now(),
    });
  }

  String _resolveCategory(String name, String? explicit) {
    final trimmed = explicit?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    final lower = name.toLowerCase();
    if (RegExp(r'milk|cheese|yogurt|butter').hasMatch(lower)) return 'Dairy';
    if (RegExp(r'apple|banana|orange|lettuce|tomato|onion').hasMatch(lower)) {
      return 'Produce';
    }
    if (RegExp(r'bread|rice|pasta|cereal').hasMatch(lower)) return 'Pantry';
    if (RegExp(r'chicken|beef|fish|egg').hasMatch(lower)) return 'Protein';
    if (RegExp(r'soap|detergent|towel|cleaner').hasMatch(lower)) {
      return 'Household';
    }
    return 'Other';
  }

  String _resolveAisle(String name, String? explicit) {
    final trimmed = explicit?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    final category = _resolveCategory(name, null);
    return switch (category) {
      'Dairy' => 'Dairy',
      'Produce' => 'Produce',
      'Pantry' => 'Pantry',
      'Protein' => 'Meat',
      'Household' => 'Household',
      _ => 'General',
    };
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  int _nextShoppingListSortOrder() {
    if (_shoppingLists.isEmpty) {
      return 0;
    }
    final maxOrder = _shoppingLists.values
        .map((list) => list.sortOrder)
        .fold<int>(0, (current, next) => next > current ? next : current);
    return maxOrder + 1;
  }

  String? staticListTitleFor(String title) {
    return _canonicalStaticListTitle(title);
  }

  bool isStaticListTitle(String title) {
    return _canonicalStaticListTitle(title) != null;
  }

  Future<void> _cleanupStaticShoppingListsOnce() async {
    if (_familyId == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cleanupKey = 'static_shopping_cleanup_${_familyId!}';
    if (prefs.getBool(cleanupKey) == true) {
      return;
    }

    final snapshot = await _firestore
        .collection(AppConstants.shoppingListsCollection)
        .where('familyId', isEqualTo: _familyId)
        .get();

    final groupedDocs = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in snapshot.docs) {
      final title = (doc.data()['title'] as String? ?? '').trim();
      final staticTitle = _canonicalStaticListTitle(title);
      if (staticTitle == null) {
        continue;
      }
      groupedDocs.putIfAbsent(staticTitle, () => []).add(doc);
    }

    for (final entry in groupedDocs.entries) {
      final staticTitle = entry.key;
      final docs = entry.value;
      docs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aStatic = aData['isStatic'] == true ? 0 : 1;
        final bStatic = bData['isStatic'] == true ? 0 : 1;
        if (aStatic != bStatic) {
          return aStatic.compareTo(bStatic);
        }

        final aExact = ((aData['title'] as String? ?? '').trim() == staticTitle)
            ? 0
            : 1;
        final bExact = ((bData['title'] as String? ?? '').trim() == staticTitle)
            ? 0
            : 1;
        if (aExact != bExact) {
          return aExact.compareTo(bExact);
        }

        final aCreated =
            (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bCreated =
            (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return aCreated.compareTo(bCreated);
      });

      final keepDoc = docs.first;
      final batch = _firestore.batch();
      batch.update(keepDoc.reference, {
        'title': staticTitle,
        'isShared': true,
        'isStatic': true,
        'aisleNames': staticTitle == 'Grocery List' ? _groceryAisles : const [],
        'updatedAt': Timestamp.now(),
      });

      for (final duplicate in docs.skip(1)) {
        final items = await _firestore
            .collection(AppConstants.shoppingItemsCollection)
            .where('listId', isEqualTo: duplicate.id)
            .get();
        for (final item in items.docs) {
          batch.delete(item.reference);
        }
        batch.delete(duplicate.reference);
      }

      await batch.commit();
    }

    await prefs.setBool(cleanupKey, true);
  }

  String? _canonicalStaticListTitle(String title) {
    final normalized = title.trim().toLowerCase();
    for (final entry in _staticShoppingListAliases.entries) {
      if (entry.value.contains(normalized)) {
        return entry.key;
      }
    }
    return null;
  }

  bool _sameTrimmedList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index].trim() != b[index].trim()) {
        return false;
      }
    }
    return true;
  }

  void _notifySafely() {
    if (_disposed || _notifyScheduled) {
      return;
    }
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) {
        _notifyScheduled = false;
        return;
      }
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  void _cancelSubscriptions() {
    _shoppingListsSubscription?.cancel();
    _shoppingItemsSubscription?.cancel();
    _shoppingHistorySubscription?.cancel();
    _inventorySubscription?.cancel();
    _shoppingListsSubscription = null;
    _shoppingItemsSubscription = null;
    _shoppingHistorySubscription = null;
    _inventorySubscription = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSubscriptions();
    super.dispose();
  }
}
