import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class EventCategory extends Equatable {
  final String id;
  final String familyId;
  final String name;
  final String? icon;
  final int colorValue; // Stored as int, converted to Color
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventCategory({
    required this.id,
    required this.familyId,
    required this.name,
    this.icon,
    required this.colorValue,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Color get color => Color(colorValue);

  factory EventCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventCategory(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      name: data['name'] ?? '',
      icon: data['icon'],
      colorValue: data['colorValue'] ?? 0xFF2196F3,
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EventCategory copyWith({
    String? id,
    String? familyId,
    String? name,
    String? icon,
    int? colorValue,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventCategory(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        name,
        icon,
        colorValue,
        description,
        createdAt,
        updatedAt,
      ];
}
