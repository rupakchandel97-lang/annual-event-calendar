import 'dart:io';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart' as app_user;

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  app_user.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeUser();
  }

  void _initializeUser() {
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserFromFirestore(firebaseUser);
        if (_currentUser != null) {
          await _ensureFamilyAssignment(_currentUser!);
        }
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserFromFirestore(User firebaseUser) async {
    try {
      print('DEBUG: Loading user from Firestore. UID: ${firebaseUser.uid}');
      final doc = await _resolveUserDocument(firebaseUser);
      print('DEBUG: Firestore doc exists: ${doc?.exists ?? false}');

      if (doc != null && doc.exists) {
        _currentUser = await _resolveProfilePhotoUrl(
          app_user.User.fromFirestore(doc),
        );
        print('DEBUG: User loaded successfully: ${_currentUser?.email}');
      } else {
        print(
            'DEBUG: User document does not exist in Firestore. Creating a fallback profile.');
        final fallbackUser = app_user.User(
          uid: firebaseUser.uid,
          email: firebaseUser.email?.trim().toLowerCase() ?? '',
          displayName: firebaseUser.displayName?.trim().isNotEmpty == true
              ? firebaseUser.displayName!.trim()
              : (firebaseUser.email?.split('@').first ?? 'User'),
          photoUrl: firebaseUser.photoURL ?? '',
          themeId: 'current_default',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(fallbackUser.toFirestore(), SetOptions(merge: true));
        _currentUser = await _resolveProfilePhotoUrl(fallbackUser);
      }
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error loading user from Firestore: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveUserDocument(
    User firebaseUser,
  ) async {
    final usersCollection = _firestore.collection('users');
    final uid = firebaseUser.uid;
    final normalizedEmail = firebaseUser.email?.trim().toLowerCase();

    final directDoc = await usersCollection.doc(uid).get();
    if (directDoc.exists) {
      return directDoc;
    }

    DocumentSnapshot<Map<String, dynamic>>? legacyDoc;

    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      final emailQuery = await usersCollection
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        legacyDoc = emailQuery.docs.first;
      }

      if (legacyDoc == null) {
        final allUsers = await usersCollection.get();
        for (final candidate in allUsers.docs) {
          final candidateEmail =
              (candidate.data()['email'] as String? ?? '').trim().toLowerCase();
          if (candidateEmail == normalizedEmail) {
            legacyDoc = candidate;
            break;
          }
        }
      }
    }

    if (legacyDoc == null || !legacyDoc.exists) {
      return null;
    }

    final legacyData = legacyDoc.data() ?? <String, dynamic>{};
    final mergedData = <String, dynamic>{
      ...legacyData,
      'email': normalizedEmail ?? (legacyData['email'] as String? ?? ''),
      'photoUrl':
          firebaseUser.photoURL ?? (legacyData['photoUrl'] as String? ?? ''),
      'themeId': legacyData['themeId'] ?? 'current_default',
      'notificationPreferences':
          legacyData['notificationPreferences'] ?? const <String, dynamic>{},
      'updatedAt': Timestamp.now(),
    };

    final displayName = (legacyData['displayName'] as String? ?? '').trim();
    if (displayName.isEmpty) {
      mergedData['displayName'] =
          firebaseUser.displayName?.trim().isNotEmpty == true
              ? firebaseUser.displayName!.trim()
              : (normalizedEmail?.split('@').first ?? 'User');
    }

    if (legacyData['createdAt'] == null) {
      mergedData['createdAt'] = Timestamp.now();
    }

    await usersCollection.doc(uid).set(mergedData, SetOptions(merge: true));

    if (legacyDoc.id != uid) {
      await _migrateLegacyReferences(
        legacyUserId: legacyDoc.id,
        canonicalUserId: uid,
      );
    }

    return usersCollection.doc(uid).get();
  }

  Future<void> _migrateLegacyReferences({
    required String legacyUserId,
    required String canonicalUserId,
  }) async {
    try {
      final legacyAdminFamilies = await _firestore
          .collection('families')
          .where('adminId', isEqualTo: legacyUserId)
          .get();
      for (final familyDoc in legacyAdminFamilies.docs) {
        final memberIds =
            List<String>.from(familyDoc.data()['memberIds'] ?? []);
        final updatedMemberIds = memberIds
            .map((memberId) =>
                memberId == legacyUserId ? canonicalUserId : memberId)
            .toSet()
            .toList();
        await familyDoc.reference.update({
          'adminId': canonicalUserId,
          'memberIds': updatedMemberIds,
          'updatedAt': Timestamp.now(),
        });
      }

      final memberFamilies = await _firestore
          .collection('families')
          .where('memberIds', arrayContains: legacyUserId)
          .get();
      for (final familyDoc in memberFamilies.docs) {
        final memberIds =
            List<String>.from(familyDoc.data()['memberIds'] ?? []);
        final updatedMemberIds = memberIds
            .map((memberId) =>
                memberId == legacyUserId ? canonicalUserId : memberId)
            .toSet()
            .toList();
        await familyDoc.reference.update({
          'memberIds': updatedMemberIds,
          'updatedAt': Timestamp.now(),
        });
      }

      final legacyEvents = await _firestore
          .collection('events')
          .where('createdBy', isEqualTo: legacyUserId)
          .get();
      for (final eventDoc in legacyEvents.docs) {
        await eventDoc.reference.update({
          'createdBy': canonicalUserId,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('DEBUG: Error migrating legacy references: $e');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      print('DEBUG: Starting signUp for $normalizedEmail');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      print('DEBUG: Auth user created. UID: ${userCredential.user?.uid}');

      final newUser = app_user.User(
        uid: userCredential.user!.uid,
        email: normalizedEmail,
        displayName: displayName,
        themeId: 'current_default',
        notificationPreferences: const app_user.NotificationPreferences(),
        role: 'admin', // First user is admin
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('DEBUG: Creating Firestore user document...');
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toFirestore());

      print('DEBUG: Firestore user document created successfully');
      _currentUser = newUser;
      await _ensureFamilyAssignment(_currentUser!);
      print('DEBUG: signUp complete. currentUser: ${_currentUser?.email}');
    } on FirebaseAuthException catch (e) {
      print('DEBUG: FirebaseAuthException in signUp: ${e.message}');
      _errorMessage = e.message;
    } catch (e) {
      print('DEBUG: General Exception in signUp: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      print('DEBUG: Starting signIn for $normalizedEmail');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      print('DEBUG: SignIn successful. UID: ${userCredential.user?.uid}');

      // Load user data after successful auth
      if (userCredential.user != null) {
        await _loadUserFromFirestore(userCredential.user!);
        print('DEBUG: User loaded from Firestore. currentUser: $_currentUser');

        if (_currentUser != null) {
          await _ensureFamilyAssignment(_currentUser!);
        }
      }
    } on FirebaseAuthException catch (e) {
      print('DEBUG: FirebaseAuthException: ${e.message}');
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      print('DEBUG: General Exception: $e');
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      print(
          'DEBUG: signIn finished. isLoading: $_isLoading, currentUser: $_currentUser');
      notifyListeners();
    }
  }

  Future<void> _createDefaultFamily(String uid, String displayName) async {
    try {
      final familyId = _firestore.collection('families').doc().id;

      // Create family document
      await _firestore.collection('families').doc(familyId).set({
        'name': '${displayName}\'s Family',
        'adminId': uid,
        'memberIds': [uid],
        'pendingInvites': [],
        'shoppingPlaces': [],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Update user's familyId
      await _firestore.collection('users').doc(uid).update({
        'familyId': familyId,
      });

      // Reload user to get updated familyId
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        await _loadUserFromFirestore(refreshedUser);
      }
      print('DEBUG: Default family created: $familyId');
    } catch (e) {
      print('DEBUG: Error creating default family: $e');
      _errorMessage = 'Failed to create family: $e';
      notifyListeners();
    }
  }

  Future<void> _ensureFamilyAssignment(app_user.User user) async {
    final joinedFromInvite = await _claimPendingFamilyInvite(user);
    if (joinedFromInvite) {
      return;
    }

    final repairedFamily = await _repairCurrentFamilyAssignment(user);
    if (repairedFamily) {
      return;
    }

    final restoredFamily = await _restoreExistingFamilyAssignment(user);
    if (restoredFamily) {
      return;
    }

    print(
        'DEBUG: User has no pending invite or recoverable family. Creating default family...');
    await _createDefaultFamily(user.uid, user.displayName);
  }

  Future<bool> _repairCurrentFamilyAssignment(app_user.User user) async {
    final currentFamilyId = user.familyId?.trim();
    final normalizedEmail = user.email.trim().toLowerCase();
    String? eventFamilyId;

    try {
      final createdEvents = await _firestore
          .collection('events')
          .where('createdBy', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (createdEvents.docs.isNotEmpty) {
        eventFamilyId =
            (createdEvents.docs.first.data()['familyId'] as String? ?? '')
                .trim();
        if (eventFamilyId.isEmpty) {
          eventFamilyId = null;
        }
      }

      if (eventFamilyId == null) {
        final allEvents =
            await _firestore.collection('events').limit(250).get();
        for (final doc in allEvents.docs) {
          final data = doc.data();
          final familyId = (data['familyId'] as String? ?? '').trim();
          final createdByEmail =
              (data['createdByEmail'] as String? ?? '').trim().toLowerCase();
          final ownerEmail =
              (data['ownerEmail'] as String? ?? '').trim().toLowerCase();
          final email = (data['email'] as String? ?? '').trim().toLowerCase();

          if (familyId.isNotEmpty &&
              {createdByEmail, ownerEmail, email}.contains(normalizedEmail)) {
            eventFamilyId = familyId;
            break;
          }
        }
      }

      if (currentFamilyId == null || currentFamilyId.isEmpty) {
        return false;
      }

      final currentFamilyDoc =
          await _firestore.collection('families').doc(currentFamilyId).get();

      if (eventFamilyId != null && eventFamilyId != currentFamilyId) {
        await _firestore.collection('users').doc(user.uid).update({
          'familyId': eventFamilyId,
          'updatedAt': Timestamp.now(),
        });
        final refreshedUser = _auth.currentUser;
        if (refreshedUser != null) {
          await _loadUserFromFirestore(refreshedUser);
        }
        print('DEBUG: Repaired mismatched family assignment to $eventFamilyId');
        return true;
      }

      if (!currentFamilyDoc.exists) {
        return false;
      }

      final familyData = currentFamilyDoc.data() ?? <String, dynamic>{};
      final memberIds = List<String>.from(familyData['memberIds'] ?? []);
      final isAdmin = familyData['adminId'] == user.uid;
      final isMember = memberIds.contains(user.uid);

      if (isAdmin || isMember) {
        return true;
      }

      memberIds.add(user.uid);
      await currentFamilyDoc.reference.update({
        'memberIds': memberIds,
        'updatedAt': Timestamp.now(),
      });
      await _firestore.collection('users').doc(user.uid).update({
        'role': isAdmin ? 'admin' : 'member',
        'updatedAt': Timestamp.now(),
      });
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        await _loadUserFromFirestore(refreshedUser);
      }
      print('DEBUG: Repaired missing family membership for $currentFamilyId');
      return true;
    } catch (e) {
      print('DEBUG: Error repairing current family assignment: $e');
      return false;
    }
  }

  Future<bool> _restoreExistingFamilyAssignment(app_user.User user) async {
    final normalizedEmail = user.email.trim().toLowerCase();

    try {
      QuerySnapshot<Map<String, dynamic>> memberFamilySnapshot =
          await _firestore
              .collection('families')
              .where('memberIds', arrayContains: user.uid)
              .limit(1)
              .get();

      if (memberFamilySnapshot.docs.isEmpty) {
        memberFamilySnapshot = await _firestore
            .collection('families')
            .where('adminId', isEqualTo: user.uid)
            .limit(1)
            .get();
      }

      String? recoveredFamilyId;
      String recoveredRole = 'member';

      if (memberFamilySnapshot.docs.isNotEmpty) {
        final familyDoc = memberFamilySnapshot.docs.first;
        recoveredFamilyId = familyDoc.id;
        recoveredRole =
            familyDoc.data()['adminId'] == user.uid ? 'admin' : 'member';
      }

      if (recoveredFamilyId == null) {
        final createdEvents = await _firestore
            .collection('events')
            .where('createdBy', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (createdEvents.docs.isNotEmpty) {
          final familyId =
              (createdEvents.docs.first.data()['familyId'] as String? ?? '')
                  .trim();
          if (familyId.isNotEmpty) {
            recoveredFamilyId = familyId;
          }
        }
      }

      if (recoveredFamilyId == null) {
        final allEvents =
            await _firestore.collection('events').limit(250).get();
        for (final doc in allEvents.docs) {
          final data = doc.data();
          final familyId = (data['familyId'] as String? ?? '').trim();
          final createdByEmail =
              (data['createdByEmail'] as String? ?? '').trim().toLowerCase();
          final ownerEmail =
              (data['ownerEmail'] as String? ?? '').trim().toLowerCase();
          final email = (data['email'] as String? ?? '').trim().toLowerCase();

          if (familyId.isNotEmpty &&
              {createdByEmail, ownerEmail, email}.contains(normalizedEmail)) {
            recoveredFamilyId = familyId;
            break;
          }
        }
      }

      if (recoveredFamilyId == null) {
        return false;
      }

      final familyDoc =
          await _firestore.collection('families').doc(recoveredFamilyId).get();
      if (familyDoc.exists) {
        final familyData = familyDoc.data() ?? <String, dynamic>{};
        final memberIds = List<String>.from(familyData['memberIds'] ?? []);
        if (!memberIds.contains(user.uid)) {
          memberIds.add(user.uid);
          await familyDoc.reference.update({
            'memberIds': memberIds,
            'updatedAt': Timestamp.now(),
          });
        }

        if (familyData['adminId'] == user.uid) {
          recoveredRole = 'admin';
        }
      }

      await _firestore.collection('users').doc(user.uid).update({
        'familyId': recoveredFamilyId,
        'role': recoveredRole,
        'updatedAt': Timestamp.now(),
      });

      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        await _loadUserFromFirestore(refreshedUser);
      }
      print('DEBUG: Restored family assignment: $recoveredFamilyId');
      return true;
    } catch (e) {
      print('DEBUG: Error restoring family assignment: $e');
      return false;
    }
  }

  Future<bool> _claimPendingFamilyInvite(app_user.User user) async {
    final normalizedEmail = user.email.trim().toLowerCase();
    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('families')
        .where('pendingInvites', arrayContains: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      final families = await _firestore.collection('families').get();
      for (final familyDoc in families.docs) {
        final pendingInvites =
            List<String>.from(familyDoc.data()['pendingInvites'] ?? []);
        if (pendingInvites
            .map((invite) => invite.trim().toLowerCase())
            .contains(normalizedEmail)) {
          snapshot = await _firestore
              .collection('families')
              .where(FieldPath.documentId, isEqualTo: familyDoc.id)
              .limit(1)
              .get();
          break;
        }
      }
    }

    if (snapshot.docs.isEmpty) {
      return false;
    }

    final familyDoc = snapshot.docs.first;
    final familyData = familyDoc.data();
    final memberIds = List<String>.from(familyData['memberIds'] ?? []);
    final pendingInvites =
        List<String>.from(familyData['pendingInvites'] ?? []);

    if (!memberIds.contains(user.uid)) {
      memberIds.add(user.uid);
    }

    await familyDoc.reference.update({
      'memberIds': memberIds,
      'pendingInvites': pendingInvites
          .where((invite) => invite.trim().toLowerCase() != normalizedEmail)
          .toList(),
      'updatedAt': Timestamp.now(),
    });

    await _firestore.collection('users').doc(user.uid).update({
      'familyId': familyDoc.id,
      'role': 'member',
      'updatedAt': Timestamp.now(),
    });

    final refreshedUser = _auth.currentUser;
    if (refreshedUser != null) {
      await _loadUserFromFirestore(refreshedUser);
    }
    print('DEBUG: User joined invited family: ${familyDoc.id}');
    return true;
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    String? themeId,
    String? languageCode,
    app_user.NotificationPreferences? notificationPreferences,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (themeId != null) updates['themeId'] = themeId;
      if (languageCode != null) updates['languageCode'] = languageCode;
      if (notificationPreferences != null) {
        updates['notificationPreferences'] = notificationPreferences.toMap();
      }
      updates['updatedAt'] = Timestamp.now();

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updates);

      _currentUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        themeId: themeId ?? _currentUser!.themeId,
        languageCode: languageCode ?? _currentUser!.languageCode,
        notificationPreferences:
            notificationPreferences ?? _currentUser!.notificationPreferences,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<app_user.User> _resolveProfilePhotoUrl(app_user.User user) async {
    final trimmedUrl = user.photoUrl.trim();
    if (trimmedUrl.isEmpty) {
      return user;
    }

    final uri = Uri.tryParse(trimmedUrl);
    final isHttpUrl = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (isHttpUrl) {
      return user;
    }

    if (trimmedUrl.startsWith('img/')) {
      return user;
    }

    if (!trimmedUrl.startsWith('gs://')) {
      return user.copyWith(photoUrl: '');
    }

    try {
      final downloadUrl =
          await _storage.refFromURL(trimmedUrl).getDownloadURL();
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
        'updatedAt': Timestamp.now(),
      });
      await _auth.currentUser?.updatePhotoURL(downloadUrl);
      return user.copyWith(photoUrl: downloadUrl);
    } catch (e) {
      print('DEBUG: Unable to resolve gs:// profile URL for ${user.uid}: $e');
      return user.copyWith(photoUrl: '');
    }
  }

  Future<bool> uploadProfilePhoto(File imageFile) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final extension = imageFile.path.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        _ => 'image/$extension',
      };
      final storageRef = _storage
          .ref()
          .child('profile_photos')
          .child(_currentUser!.uid)
          .child('avatar_${DateTime.now().millisecondsSinceEpoch}.$extension');

      final snapshot = await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: contentType),
      );

      final photoUrl = await _getDownloadUrlWithRetry(snapshot.ref);
      await updateProfile(photoUrl: photoUrl);
      await _auth.currentUser?.updatePhotoURL(photoUrl);
      _errorMessage = null;
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = e.message ?? e.toString();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> setBundledProfilePhoto(String assetPath) async {
    if (_currentUser == null) {
      return false;
    }

    final didUpdate = await updateProfile(photoUrl: assetPath);
    return didUpdate;
  }

  Future<String> _getDownloadUrlWithRetry(
    Reference storageRef, {
    int maxAttempts = 4,
  }) async {
    FirebaseException? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await storageRef.getDownloadURL();
      } on FirebaseException catch (e) {
        lastError = e;
        final isRetryableNotFound =
            e.code == 'object-not-found' && attempt < maxAttempts;
        if (!isRetryableNotFound) {
          rethrow;
        }

        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      }
    }

    throw lastError ??
        FirebaseException(
          plugin: 'firebase_storage',
          message: 'Unable to resolve uploaded profile photo URL.',
        );
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
