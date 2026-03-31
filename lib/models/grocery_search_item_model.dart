import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GrocerySearchItem extends Equatable {
  final String id;
  final String familyId;
  final String category;
  final String itemType;
  final String itemName;
  final String iconName;
  final int sortOrder;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GrocerySearchItem({
    required this.id,
    required this.familyId,
    required this.category,
    required this.itemType,
    required this.itemName,
    this.iconName = '',
    this.sortOrder = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GrocerySearchItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GrocerySearchItem(
      id: doc.id,
      familyId: data['familyId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      itemType: data['itemType'] as String? ?? '',
      itemName: data['itemName'] as String? ?? '',
      iconName: data['iconName'] as String? ?? '',
      sortOrder: data['sortOrder'] as int? ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'category': category,
      'itemType': itemType,
      'itemName': itemName,
      'iconName': iconName,
      'sortOrder': sortOrder,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  GrocerySearchItem copyWith({
    String? id,
    String? familyId,
    String? category,
    String? itemType,
    String? itemName,
    String? iconName,
    int? sortOrder,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GrocerySearchItem(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      category: category ?? this.category,
      itemType: itemType ?? this.itemType,
      itemName: itemName ?? this.itemName,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        category,
        itemType,
        itemName,
        iconName,
        sortOrder,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
