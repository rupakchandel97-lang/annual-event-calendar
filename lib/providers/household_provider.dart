import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/imported_grocery_catalog.dart';
import '../models/grocery_search_item_model.dart';
import '../models/inventory_item_model.dart';
import '../models/shopping_history_item_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../utils/asset_catalog.dart';
import '../utils/constants.dart';

class HouseholdProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _shoppingListsSubscription;
  StreamSubscription<QuerySnapshot>? _shoppingItemsSubscription;
  StreamSubscription<QuerySnapshot>? _shoppingHistorySubscription;
  StreamSubscription<QuerySnapshot>? _grocerySearchItemsSubscription;
  StreamSubscription<QuerySnapshot>? _inventorySubscription;

  String? _userId;
  String? _familyId;
  bool _isLoading = false;
  bool _disposed = false;
  bool _notifyScheduled = false;
  String? _errorMessage;
  bool _seedingDefaults = false;
  bool _groceryCatalogMigrationInProgress = false;

  Map<String, ShoppingList> _shoppingLists = {};
  Map<String, ShoppingItem> _shoppingItems = {};
  Map<String, ShoppingHistoryItem> _historyItems = {};
  Map<String, GrocerySearchItem> _grocerySearchItems = {};
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
  List<GrocerySearchItem> get grocerySearchItems =>
      _grocerySearchItems.values.toList()
        ..sort((a, b) {
          final categoryCompare =
              a.category.toLowerCase().compareTo(b.category.toLowerCase());
          if (categoryCompare != 0) {
            return categoryCompare;
          }
          final typeCompare =
              a.itemType.toLowerCase().compareTo(b.itemType.toLowerCase());
          if (typeCompare != 0) {
            return typeCompare;
          }
          final orderCompare = a.sortOrder.compareTo(b.sortOrder);
          if (orderCompare != 0) {
            return orderCompare;
          }
          return a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
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

  static const String _importedGroceryCatalogVersion = '2026_03_30_excel_v3';

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
    _grocerySearchItems = {};
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

      final existingByKey =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      final batch = _firestore.batch();
      var hasBatchUpdates = false;
      var nextSortOrder = snapshot.docs
              .map((doc) => (doc.data()['sortOrder'] as int?) ?? 0)
              .fold<int>(
                  -1, (current, next) => next > current ? next : current) +
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

      await _migrateImportedGroceryCatalogIfNeeded();
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
      final protectedShared =
          list.isStatic ? true : (isShared ?? list.isShared);
      final protectedAisles = list.isStatic
          ? (protectedTitle == 'Grocery List'
              ? _groceryAisles
              : const <String>[])
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
          _firestore
              .collection(AppConstants.shoppingListsCollection)
              .doc(list.id),
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
        _firestore
            .collection(AppConstants.shoppingListsCollection)
            .doc(list.id),
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
    String? shoppingPlace,
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
        shoppingPlace: _nullableTrim(shoppingPlace) ?? '',
        quantity: quantity,
        sortOrder: _nextShoppingItemSortOrder(list.id),
        note: _nullableTrim(note),
        createdBy: _userId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await doc.set(item.toFirestore());
      await _touchShoppingList(list.id);
      await _upsertHistory(item);
      if (_isCanonicalGroceryListTitle(list.title)) {
        await upsertGrocerySearchItem(
          itemName: item.name,
          category: item.category,
          itemType: item.aisle,
        );
      }
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
    String? shoppingPlace,
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
        shoppingPlace: _nullableTrim(shoppingPlace ?? item.shoppingPlace) ?? '',
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
      final list = _shoppingLists[item.listId];
      if (list != null && _isCanonicalGroceryListTitle(list.title)) {
        await upsertGrocerySearchItem(
          itemName: updated.name,
          category: updated.category,
          itemType: updated.aisle,
        );
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
        suggestedForShopping: suggestedForShopping ?? item.suggestedForShopping,
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
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) {
          return orderCompare;
        }
        final aisleCompare =
            a.aisle.toLowerCase().compareTo(b.aisle.toLowerCase());
        if (aisleCompare != 0) {
          return aisleCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return items;
  }

  Future<void> ensureDefaultGrocerySearchItems() async {
    if (_familyId == null || _userId == null) {
      return;
    }

    final existing = await _firestore
        .collection(AppConstants.grocerySearchItemsCollection)
        .where('familyId', isEqualTo: _familyId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final iconNames = await groceryIconNames();
    if (iconNames.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final batch = _firestore.batch();
    var sortOrder = 0;

    for (final iconName in iconNames) {
      final normalizedIcon = AssetCatalog.normalizedLookup(iconName);
      if (normalizedIcon == 'no image' || normalizedIcon == 'not found') {
        continue;
      }

      final doc = _firestore
          .collection(AppConstants.grocerySearchItemsCollection)
          .doc();
      final item = GrocerySearchItem(
        id: doc.id,
        familyId: _familyId!,
        category: _resolveCategory(iconName, null),
        itemType: _resolveAisle(iconName, null),
        itemName: iconName,
        iconName: iconName,
        sortOrder: sortOrder++,
        createdBy: _userId!,
        createdAt: now,
        updatedAt: now,
      );
      batch.set(doc, item.toFirestore());
    }

    await batch.commit();
  }

  Future<void> upsertGrocerySearchItem({
    required String itemName,
    String? category,
    String? itemType,
    String? iconName,
  }) async {
    if (_familyId == null || _userId == null) {
      return;
    }

    final trimmedName = itemName.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final existing = _findGrocerySearchItemByName(trimmedName);
    final now = DateTime.now();
    final resolvedCategory =
        _nullableTrim(category) ?? _resolveCategory(trimmedName, null);
    final resolvedItemType =
        _nullableTrim(itemType) ?? _resolveAisle(trimmedName, null);
    final resolvedIconName = await resolveGroceryIconName(
      itemName: trimmedName,
      preferredIconName: iconName,
    );

    if (existing != null) {
      await _firestore
          .collection(AppConstants.grocerySearchItemsCollection)
          .doc(existing.id)
          .update(
            existing
                .copyWith(
                  itemName: trimmedName,
                  category: resolvedCategory,
                  itemType: resolvedItemType,
                  iconName: resolvedIconName,
                  updatedAt: now,
                )
                .toFirestore(),
          );
      return;
    }

    final doc =
        _firestore.collection(AppConstants.grocerySearchItemsCollection).doc();
    final item = GrocerySearchItem(
      id: doc.id,
      familyId: _familyId!,
      category: resolvedCategory,
      itemType: resolvedItemType,
      itemName: trimmedName,
      iconName: resolvedIconName,
      sortOrder: _nextGrocerySearchSortOrder(),
      createdBy: _userId!,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(item.toFirestore());
  }

  Future<void> replaceGrocerySearchItems(List<GrocerySearchItem> items) async {
    if (_familyId == null || _userId == null) {
      return;
    }

    final operations = <void Function(WriteBatch batch)>[];
    final keptIds = <String>{};
    final seenKeys = <String>{};
    final now = DateTime.now();
    var sortOrder = 0;

    for (final rawItem in items) {
      final trimmedName = rawItem.itemName.trim();
      if (trimmedName.isEmpty) {
        continue;
      }

      final dedupeKey = [
        AssetCatalog.normalizedLookup(rawItem.category),
        AssetCatalog.normalizedLookup(rawItem.itemType),
        AssetCatalog.normalizedLookup(trimmedName),
      ].join('|');
      if (!seenKeys.add(dedupeKey)) {
        continue;
      }

      final doc = rawItem.id.isEmpty
          ? _firestore
              .collection(AppConstants.grocerySearchItemsCollection)
              .doc()
          : _firestore
              .collection(AppConstants.grocerySearchItemsCollection)
              .doc(rawItem.id);
      keptIds.add(doc.id);

      final item = rawItem.copyWith(
        id: doc.id,
        familyId: _familyId!,
        itemName: trimmedName,
        category: rawItem.category.trim(),
        itemType: rawItem.itemType.trim(),
        iconName: await resolveGroceryIconName(
          itemName: trimmedName,
          preferredIconName: rawItem.iconName,
        ),
        sortOrder: sortOrder++,
        createdBy: rawItem.createdBy.isEmpty ? _userId! : rawItem.createdBy,
        createdAt: rawItem.id.isEmpty ? now : rawItem.createdAt,
        updatedAt: now,
      );
      operations.add((batch) => batch.set(doc, item.toFirestore()));
    }

    final existingSnapshot = await _firestore
        .collection(AppConstants.grocerySearchItemsCollection)
        .where('familyId', isEqualTo: _familyId)
        .get();
    for (final existing in existingSnapshot.docs) {
      if (!keptIds.contains(existing.id)) {
        operations.add((batch) => batch.delete(existing.reference));
      }
    }

    await _commitBatchedWrites(operations);
  }

  Future<void> resetImportedGroceryCatalog() async {
    if (_familyId == null || _userId == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final migrationKey =
        'grocery_catalog_migration_${_familyId!}_$_importedGroceryCatalogVersion';

    if (importedGroceryCatalog.isEmpty) {
      await ensureDefaultGrocerySearchItems();
      await prefs.setBool(migrationKey, true);
      return;
    }

    final now = DateTime.now();
    final items = importedGroceryCatalog
        .map(
          (row) => GrocerySearchItem(
            id: '',
            familyId: _familyId!,
            category: (row['category'] ?? '').trim(),
            itemType: (row['itemType'] ?? '').trim(),
            itemName: (row['itemName'] ?? '').trim(),
            iconName: '',
            sortOrder: 0,
            createdBy: _userId!,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();

    await replaceGrocerySearchItems(items);
    await prefs.setBool(migrationKey, true);
  }

  Future<List<String>> groceryIconNames() async {
    final assets = await AssetCatalog.listAssets('img/_Grocery List/');
    final names = assets.map(AssetCatalog.labelFromAssetPath).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  Future<String> resolveGroceryIconName({
    required String itemName,
    String? preferredIconName,
  }) async {
    final iconNames = await groceryIconNames();
    final normalizedPreferred =
        AssetCatalog.normalizedLookup(preferredIconName ?? '');
    if (normalizedPreferred.isNotEmpty) {
      for (final iconName in iconNames) {
        if (AssetCatalog.normalizedLookup(iconName) == normalizedPreferred) {
          return iconName;
        }
      }
    }

    final normalizedName = AssetCatalog.normalizedLookup(itemName);
    for (final iconName in iconNames) {
      if (AssetCatalog.normalizedLookup(iconName) == normalizedName) {
        return iconName;
      }
    }

    return 'No Image';
  }

  GrocerySearchItem? grocerySearchItemForName(String itemName) {
    return _findGrocerySearchItemByName(itemName);
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
        for (final doc in snapshot.docs)
          doc.id: ShoppingList.fromFirestore(doc),
      };
      _markLoaded();
    }, onError: _handleError);

    _shoppingItemsSubscription = _firestore
        .collection(AppConstants.shoppingItemsCollection)
        .where('familyId', isEqualTo: _familyId)
        .snapshots()
        .listen((snapshot) {
      _shoppingItems = {
        for (final doc in snapshot.docs)
          doc.id: ShoppingItem.fromFirestore(doc),
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

    _grocerySearchItemsSubscription = _firestore
        .collection(AppConstants.grocerySearchItemsCollection)
        .where('familyId', isEqualTo: _familyId)
        .snapshots()
        .listen((snapshot) {
      _grocerySearchItems = {
        for (final doc in snapshot.docs)
          doc.id: GrocerySearchItem.fromFirestore(doc),
      };
      _markLoaded();
    }, onError: _handleError);

    _inventorySubscription = _firestore
        .collection(AppConstants.inventoryItemsCollection)
        .where('familyId', isEqualTo: _familyId)
        .snapshots()
        .listen((snapshot) {
      _inventoryItems = {
        for (final doc in snapshot.docs)
          doc.id: InventoryItem.fromFirestore(doc),
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
    final historyId =
        '${item.familyId}_${item.name.trim().toLowerCase().replaceAll(' ', '_')}';
    final ref = _firestore
        .collection(AppConstants.shoppingHistoryCollection)
        .doc(historyId);
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

  int _nextShoppingItemSortOrder(String listId) {
    final listItems =
        _shoppingItems.values.where((item) => item.listId == listId);
    if (listItems.isEmpty) {
      return 0;
    }
    final maxOrder = listItems
        .map((item) => item.sortOrder)
        .fold<int>(0, (current, next) => next > current ? next : current);
    return maxOrder + 1;
  }

  int _nextGrocerySearchSortOrder() {
    if (_grocerySearchItems.isEmpty) {
      return 0;
    }
    final maxOrder = _grocerySearchItems.values
        .map((item) => item.sortOrder)
        .fold<int>(0, (current, next) => next > current ? next : current);
    return maxOrder + 1;
  }

  Future<void> _migrateImportedGroceryCatalogIfNeeded() async {
    if (_familyId == null ||
        _userId == null ||
        _groceryCatalogMigrationInProgress) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final migrationKey =
        'grocery_catalog_migration_${_familyId!}_$_importedGroceryCatalogVersion';
    if (prefs.getBool(migrationKey) == true) {
      return;
    }

    _groceryCatalogMigrationInProgress = true;
    try {
      if (importedGroceryCatalog.isEmpty) {
        await ensureDefaultGrocerySearchItems();
        await prefs.setBool(migrationKey, true);
        return;
      }

      await resetImportedGroceryCatalog();
    } finally {
      _groceryCatalogMigrationInProgress = false;
    }
  }

  Future<void> _commitBatchedWrites(
    List<void Function(WriteBatch batch)> operations,
  ) async {
    if (operations.isEmpty) {
      return;
    }

    const maxOperationsPerBatch = 400;
    for (var start = 0; start < operations.length; start += maxOperationsPerBatch) {
      final batch = _firestore.batch();
      final end = (start + maxOperationsPerBatch < operations.length)
          ? start + maxOperationsPerBatch
          : operations.length;
      for (var index = start; index < end; index++) {
        operations[index](batch);
      }
      await batch.commit();
    }
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

    final groupedDocs =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
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

        final aExact =
            ((aData['title'] as String? ?? '').trim() == staticTitle) ? 0 : 1;
        final bExact =
            ((bData['title'] as String? ?? '').trim() == staticTitle) ? 0 : 1;
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
    _grocerySearchItemsSubscription?.cancel();
    _inventorySubscription?.cancel();
    _shoppingListsSubscription = null;
    _shoppingItemsSubscription = null;
    _shoppingHistorySubscription = null;
    _grocerySearchItemsSubscription = null;
    _inventorySubscription = null;
  }

  GrocerySearchItem? _findGrocerySearchItemByName(String itemName) {
    final lookup = AssetCatalog.normalizedLookup(itemName);
    for (final item in _grocerySearchItems.values) {
      if (AssetCatalog.normalizedLookup(item.itemName) == lookup) {
        return item;
      }
    }
    return null;
  }

  bool _isCanonicalGroceryListTitle(String title) {
    return title.trim().toLowerCase() == 'grocery list';
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSubscriptions();
    super.dispose();
  }
}
