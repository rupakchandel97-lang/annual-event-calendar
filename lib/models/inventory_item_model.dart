import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum InventoryStatus { inStock, runningLow, outOfStock }

InventoryStatus inventoryStatusFromString(String? value) {
  switch (value) {
    case 'runningLow':
      return InventoryStatus.runningLow;
    case 'outOfStock':
      return InventoryStatus.outOfStock;
    case 'inStock':
    default:
      return InventoryStatus.inStock;
  }
}

class InventoryItem extends Equatable {
  final String id;
  final String familyId;
  final String name;
  final String category;
  final String locationLabel;
  final String quantityLabel;
  final InventoryStatus status;
  final bool suggestedForShopping;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
    required this.id,
    required this.familyId,
    required this.name,
    required this.category,
    this.locationLabel = '',
    this.quantityLabel = '',
    this.status = InventoryStatus.inStock,
    this.suggestedForShopping = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'Household',
      locationLabel: data['locationLabel'] ?? '',
      quantityLabel: data['quantityLabel'] ?? '',
      status: inventoryStatusFromString(data['status']),
      suggestedForShopping: data['suggestedForShopping'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'name': name,
      'category': category,
      'locationLabel': locationLabel,
      'quantityLabel': quantityLabel,
      'status': status.name,
      'suggestedForShopping': suggestedForShopping,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? familyId,
    String? name,
    String? category,
    String? locationLabel,
    String? quantityLabel,
    InventoryStatus? status,
    bool? suggestedForShopping,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      category: category ?? this.category,
      locationLabel: locationLabel ?? this.locationLabel,
      quantityLabel: quantityLabel ?? this.quantityLabel,
      status: status ?? this.status,
      suggestedForShopping:
          suggestedForShopping ?? this.suggestedForShopping,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        name,
        category,
        locationLabel,
        quantityLabel,
        status,
        suggestedForShopping,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
