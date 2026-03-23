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

  void clear() {
    _currentFamily = null;
    _familyMembers = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

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
      final normalizedEmail = emailToInvite.trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        _errorMessage = 'Please enter an email address';
        notifyListeners();
        return;
      }

      final family = await _firestore.collection('families').doc(familyId).get();
      if (!family.exists) {
        _errorMessage = 'Family not found';
        notifyListeners();
        return;
      }

      final updatedFamily = Family.fromFirestore(family);
      final existingUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? existingUserDoc =
          existingUserQuery.docs.isNotEmpty ? existingUserQuery.docs.first : null;
      if (existingUserDoc == null) {
        final allUsers = await _firestore.collection('users').get();
        for (final userDoc in allUsers.docs) {
          final userEmail =
              (userDoc.data()['email'] as String? ?? '').trim().toLowerCase();
          if (userEmail == normalizedEmail) {
            existingUserDoc = userDoc;
            break;
          }
        }
      }

      if (existingUserDoc != null) {
        final existingUser = User.fromFirestore(existingUserDoc);

        if (updatedFamily.memberIds.contains(existingUser.uid)) {
          _errorMessage = 'This member is already part of the family';
          notifyListeners();
          return;
        }

        if (existingUser.familyId != null && existingUser.familyId != familyId) {
          _errorMessage = 'This user already belongs to another family';
          notifyListeners();
          return;
        }

        final cleanedPendingInvites = updatedFamily.pendingInvites
            .where((invite) => invite.trim().toLowerCase() != normalizedEmail)
            .toList();
        await _firestore.collection('families').doc(familyId).update({
          'pendingInvites': cleanedPendingInvites,
          'updatedAt': Timestamp.now(),
        });
        await addMember(familyId: familyId, userId: existingUser.uid);
        return;
      }

      final alreadyInvited = updatedFamily.pendingInvites
          .map((invite) => invite.trim().toLowerCase())
          .contains(normalizedEmail);

      if (alreadyInvited) {
        _errorMessage = 'Invitation already pending for this email';
        notifyListeners();
        return;
      }

      final newPendingInvites = [
        ...updatedFamily.pendingInvites,
        normalizedEmail,
      ];

      await _firestore.collection('families').doc(familyId).update({
        'pendingInvites': newPendingInvites,
        'updatedAt': Timestamp.now(),
      });

      _errorMessage = null;
      await loadFamily(familyId);
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
      _errorMessage = null;
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      if (!familyDoc.exists) {
        _errorMessage = 'Family not found';
        notifyListeners();
        return;
      }

      final family = Family.fromFirestore(familyDoc);
      final newMembers = family.memberIds.contains(userId)
          ? family.memberIds
          : [...family.memberIds, userId];
      await _firestore.collection('families').doc(familyId).update({
        'memberIds': newMembers,
        'updatedAt': Timestamp.now(),
      });

      await _firestore.collection('users').doc(userId).update({
        'familyId': familyId,
        'role': role,
      });

      await loadFamily(familyId);
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
          'updatedAt': Timestamp.now(),
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
        'updatedAt': Timestamp.now(),
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
