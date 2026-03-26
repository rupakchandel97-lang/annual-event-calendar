import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ShoppingList extends Equatable {
  final String id;
  final String title;
  final String familyId;
  final String createdBy;
  final bool isShared;
  final bool isStatic;
  final int sortOrder;
  final List<String> aisleNames;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingList({
    required this.id,
    required this.title,
    required this.familyId,
    required this.createdBy,
    this.isShared = true,
    this.isStatic = false,
    this.sortOrder = 0,
    this.aisleNames = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingList(
      id: doc.id,
      title: data['title'] ?? '',
      familyId: data['familyId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      isShared: data['isShared'] ?? true,
      isStatic: data['isStatic'] ?? false,
      sortOrder: data['sortOrder'] ?? 0,
      aisleNames: List<String>.from(data['aisleNames'] ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'familyId': familyId,
      'createdBy': createdBy,
      'isShared': isShared,
      'isStatic': isStatic,
      'sortOrder': sortOrder,
      'aisleNames': aisleNames,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ShoppingList copyWith({
    String? id,
    String? title,
    String? familyId,
    String? createdBy,
    bool? isShared,
    bool? isStatic,
    int? sortOrder,
    List<String>? aisleNames,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      title: title ?? this.title,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      isShared: isShared ?? this.isShared,
      isStatic: isStatic ?? this.isStatic,
      sortOrder: sortOrder ?? this.sortOrder,
      aisleNames: aisleNames ?? this.aisleNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        familyId,
        createdBy,
        isShared,
        isStatic,
        sortOrder,
        aisleNames,
        createdAt,
        updatedAt,
      ];
}
