import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ShoppingHistoryItem extends Equatable {
  final String id;
  final String familyId;
  final String name;
  final String category;
  final String aisle;
  final int purchaseCount;
  final DateTime lastAddedAt;

  const ShoppingHistoryItem({
    required this.id,
    required this.familyId,
    required this.name,
    required this.category,
    required this.aisle,
    required this.purchaseCount,
    required this.lastAddedAt,
  });

  factory ShoppingHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingHistoryItem(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'Other',
      aisle: data['aisle'] ?? 'General',
      purchaseCount: data['purchaseCount'] ?? 0,
      lastAddedAt: (data['lastAddedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'name': name,
      'category': category,
      'aisle': aisle,
      'purchaseCount': purchaseCount,
      'lastAddedAt': Timestamp.fromDate(lastAddedAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        name,
        category,
        aisle,
        purchaseCount,
        lastAddedAt,
      ];
}
