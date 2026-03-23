import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  runApp(const FirestoreResetApp());
}

class FirestoreResetApp extends StatelessWidget {
  const FirestoreResetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firestore Reset Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC96A2B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const FirestoreResetScreen(),
    );
  }
}

class FirestoreResetScreen extends StatefulWidget {
  const FirestoreResetScreen({super.key});

  @override
  State<FirestoreResetScreen> createState() => _FirestoreResetScreenState();
}

class _FirestoreResetScreenState extends State<FirestoreResetScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _confirmationController =
      TextEditingController();

  bool _isResetting = false;
  String? _statusMessage;
  int _eventsDeleted = 0;
  int _familiesDeleted = 0;
  int _usersDeleted = 0;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _resetFirestore() async {
    if (_confirmationController.text.trim().toUpperCase() != 'RESET') {
      setState(() {
        _statusMessage = 'Type RESET exactly before running the cleanup.';
      });
      return;
    }

    setState(() {
      _isResetting = true;
      _statusMessage = 'Deleting Firestore documents...';
      _eventsDeleted = 0;
      _familiesDeleted = 0;
      _usersDeleted = 0;
    });

    try {
      _eventsDeleted = await _deleteCollection('events');
      _familiesDeleted = await _deleteCollection('families');
      _usersDeleted = await _deleteCollection('users');

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage =
            'Cleanup complete. Firestore collections were cleared successfully.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Cleanup failed: $e';
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isResetting = false;
      });
    }
  }

  Future<int> _deleteCollection(String collectionPath) async {
    int deletedCount = 0;

    while (true) {
      final snapshot = await _firestore
          .collection(collectionPath)
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      deletedCount += snapshot.docs.length;
    }

    return deletedCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Reset Tool'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will permanently delete all documents from the Firestore collections below:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('events'),
                    const Text('families'),
                    const Text('users'),
                    const SizedBox(height: 16),
                    Text(
                      'It does not delete Firebase Authentication accounts.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmationController,
                      enabled: !_isResetting,
                      decoration: const InputDecoration(
                        labelText: 'Type RESET to confirm',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isResetting ? null : _resetFirestore,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isResetting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text('Delete Firestore Data'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SummaryRow(
                      label: 'Events deleted',
                      value: _eventsDeleted.toString(),
                    ),
                    _SummaryRow(
                      label: 'Families deleted',
                      value: _familiesDeleted.toString(),
                    ),
                    _SummaryRow(
                      label: 'Users deleted',
                      value: _usersDeleted.toString(),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(_statusMessage!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
