import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';

class FamilyProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Family? _currentFamily;
  List<User> _familyMembers = [];
  bool _isLoading = false;
  String? _errorMessage;

  Family? get currentFamily => _currentFamily;
  List<User> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> createFamily({
    required String adminId,
    required String familyName,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final family = Family(
        id: _firestore.collection('families').doc().id,
        name: familyName,
        adminId: adminId,
        memberIds: [adminId],
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('families')
          .doc(family.id)
          .set(family.toFirestore());

      // Update user's familyId
      await _firestore.collection('users').doc(adminId).update({
        'familyId': family.id,
        'role': 'admin',
      });

      _currentFamily = family;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFamily(String familyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (doc.exists) {
        _currentFamily = Family.fromFirestore(doc);
        await _loadFamilyMembers(familyId);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFamilyMembers(String familyId) async {
    try {
      final members = <User>[];
      for (final memberId in _currentFamily!.memberIds) {
        final doc =
            await _firestore.collection('users').doc(memberId).get();
        if (doc.exists) {
          members.add(User.fromFirestore(doc));
        }
      }
      _familyMembers = members;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> inviteMember({
    required String familyId,
    required String emailToInvite,
  }) async {
    try {
      final family = await _firestore.collection('families').doc(familyId).get();
      if (family.exists) {
        final updatedFamily = Family.fromFirestore(family);
        if (!updatedFamily.pendingInvites.contains(emailToInvite)) {
          final newPendingInvites = [...updatedFamily.pendingInvites, emailToInvite];
          await _firestore.collection('families').doc(familyId).update({
            'pendingInvites': newPendingInvites,
            'updatedAt': DateTime.now(),
          });
          // In production, send email invitation here
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addMember({
    required String familyId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      if (_currentFamily != null) {
        final newMembers = [..._currentFamily!.memberIds, userId];
        await _firestore.collection('families').doc(familyId).update({
          'memberIds': newMembers,
          'updatedAt': DateTime.now(),
        });

        await _firestore.collection('users').doc(userId).update({
          'familyId': familyId,
          'role': role,
        });

        await loadFamily(familyId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeMember({
    required String familyId,
    required String userId,
  }) async {
    try {
      if (_currentFamily != null) {
        final updatedMembers = _currentFamily!.memberIds
            .where((id) => id != userId)
            .toList();
        
        await _firestore.collection('families').doc(familyId).update({
          'memberIds': updatedMembers,
          'updatedAt': DateTime.now(),
        });

        await _firestore.collection('users').doc(userId).update({
          'familyId': null,
          'role': 'member',
        });

        await loadFamily(familyId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateFamily({
    required String familyId,
    required String name,
    String? description,
    String? photoUrl,
  }) async {
    try {
      final updates = {
        'name': name,
        'updatedAt': DateTime.now(),
      };
      if (description != null) updates['description'] = description;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('families').doc(familyId).update(updates);
      await loadFamily(familyId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
