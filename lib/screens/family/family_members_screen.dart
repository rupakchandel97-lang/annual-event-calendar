import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/user_app_bar_title.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({Key? key}) : super(key: key);

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final _emailController = TextEditingController();

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/settings');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showInviteDialog() {
    _emailController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Family Member'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final familyId =
                  context.read<FamilyProvider>().currentFamily?.id;
              if (familyId != null) {
                final familyProvider = context.read<FamilyProvider>();
                await familyProvider.inviteMember(
                  familyId: familyId,
                  emailToInvite: _emailController.text,
                );

                if (!context.mounted) {
                  return;
                }

                final message = familyProvider.errorMessage ??
                    'Invite processed. Existing accounts are added right away, and new users can join with this email when they sign up.';
                if (familyProvider.errorMessage == null) {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: const UserAppBarTitle(title: 'Family Members'),
        elevation: 0,
      ),
      body: Consumer2<FamilyProvider, AuthProvider>(
        builder: (context, familyProvider, authProvider, _) {
          final palette = AppTheme.of(context);
          final currentUser = authProvider.currentUser;
          final isAdmin = currentUser?.role == 'admin';

          if (familyProvider.currentFamily == null) {
            return const Center(child: Text('No family found'));
          }

          return Column(
            children: [
              // Family Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt.withOpacity(palette.isDark ? 0.34 : 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family: ${familyProvider.currentFamily!.name}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${familyProvider.familyMembers.length} members',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),

              // Members List
              Expanded(
                child: ListView.builder(
                  itemCount: familyProvider.familyMembers.length,
                  itemBuilder: (context, index) {
                    final member = familyProvider.familyMembers[index];
                    final isCurrentUser = member.uid == currentUser?.uid;

                    return ListTile(
                      leading: ProfileAvatar(
                        photoUrl: member.photoUrl,
                        radius: 20,
                        iconSize: 20,
                      ),
                      title: Text(member.displayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.email),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: member.role == 'admin'
                                  ? palette.badgeAdmin
                                  : palette.badgeMember,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              member.role.toUpperCase(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      trailing: isAdmin && !isCurrentUser
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Remove Member'),
                                    content: Text(
                                        'Remove ${member.displayName} from the family?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => context.pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          familyProvider.removeMember(
                                            familyId:
                                                familyProvider.currentFamily!.id,
                                            userId: member.uid,
                                          );
                                          context.pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  '${member.displayName} removed'),
                                            ),
                                          );
                                        },
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<FamilyProvider>(
        builder: (context, familyProvider, _) {
          return FloatingActionButton(
            onPressed: _showInviteDialog,
            child: const Icon(Icons.person_add),
          );
        },
      ),
    );
  }
}
