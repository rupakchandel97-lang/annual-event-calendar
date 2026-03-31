import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ShoppingItem extends Equatable {
  final String id;
  final String listId;
  final String familyId;
  final String name;
  final String category;
  final String aisle;
  final String shoppingPlace;
  final bool checked;
  final int quantity;
  final int sortOrder;
  final String? note;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.familyId,
    required this.name,
    required this.category,
    required this.aisle,
    this.shoppingPlace = '',
    this.checked = false,
    this.quantity = 1,
    this.sortOrder = 0,
    this.note,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      listId: data['listId'] ?? '',
      familyId: data['familyId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'Other',
      aisle: data['aisle'] ?? 'General',
      shoppingPlace: data['shoppingPlace'] ?? '',
      checked: data['checked'] ?? false,
      quantity: data['quantity'] ?? 1,
      sortOrder: data['sortOrder'] ?? 0,
      note: data['note'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listId': listId,
      'familyId': familyId,
      'name': name,
      'category': category,
      'aisle': aisle,
      'shoppingPlace': shoppingPlace,
      'checked': checked,
      'quantity': quantity,
      'sortOrder': sortOrder,
      'note': note,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? familyId,
    String? name,
    String? category,
    String? aisle,
    String? shoppingPlace,
    bool? checked,
    int? quantity,
    int? sortOrder,
    String? note,
    bool clearNote = false,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      category: category ?? this.category,
      aisle: aisle ?? this.aisle,
      shoppingPlace: shoppingPlace ?? this.shoppingPlace,
      checked: checked ?? this.checked,
      quantity: quantity ?? this.quantity,
      sortOrder: sortOrder ?? this.sortOrder,
      note: clearNote ? null : (note ?? this.note),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        listId,
        familyId,
        name,
        category,
        aisle,
        shoppingPlace,
        checked,
        quantity,
        sortOrder,
        note,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
