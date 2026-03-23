import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/user_app_bar_title.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  void _clearLoadedData() {
    context.read<FamilyProvider>().clear();
    context.read<CategoryProvider>().clear();
    context.read<EventProvider>().clear();
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  Future<void> _pickProfilePhoto() async {
    try {
      XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1400,
      );

      if (pickedFile == null) {
        final lostData = await _imagePicker.retrieveLostData();
        if (!lostData.isEmpty && lostData.files != null && lostData.files!.isNotEmpty) {
          pickedFile = lostData.files!.first;
        }
      }

      if (pickedFile == null || !mounted) {
        return;
      }

      await context.read<AuthProvider>().uploadProfilePhoto(File(pickedFile.path));

      if (!mounted) {
        return;
      }

      final message = context.read<AuthProvider>().errorMessage == null
          ? 'Profile photo updated'
          : context.read<AuthProvider>().errorMessage!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to select image: $e')),
      );
    }
  }

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Display name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a display name')),
                );
                return;
              }

              await context.read<AuthProvider>().updateProfile(
                    displayName: newName,
                  );

              if (!mounted) {
                return;
              }

              dialogContext.pop();
              final message = context.read<AuthProvider>().errorMessage == null
                  ? 'Display name updated'
                  : context.read<AuthProvider>().errorMessage!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemePicker({
    required AuthProvider authProvider,
    required ThemeProvider themeProvider,
  }) async {
    final originalThemeId = themeProvider.themeId;
    var lastConfirmedThemeId = originalThemeId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Theme',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your selection is saved to your profile and restored every time you sign in.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.of(context).textMuted,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.68,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: AppTheme.themes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final theme = AppTheme.themes[index];
                          final isSelected = themeProvider.themeId == theme.id;

                          return InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: authProvider.isLoading
                                ? null
                                : () async {
                                    themeProvider.setTheme(theme.id);
                                    setModalState(() {});

                                    final didSave = await authProvider.updateProfile(
                                      themeId: theme.id,
                                    );

                                    if (!mounted) {
                                      return;
                                    }

                                    if (!didSave) {
                                      themeProvider.setTheme(lastConfirmedThemeId);
                                      setModalState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            authProvider.errorMessage ??
                                                'Unable to save theme selection',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${theme.name} applied',
                                        ),
                                      ),
                                    );
                                    lastConfirmedThemeId = theme.id;
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.surface.withOpacity(
                                  theme.isDark ? 0.96 : 0.86,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.primary
                                      : theme.outline.withOpacity(0.8),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme.heading,
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              theme.name,
                                              style: TextStyle(
                                                color: theme.textPrimary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              theme.description,
                                              style: TextStyle(
                                                color: theme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: theme.primary,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      for (final color in [
                                        theme.primary,
                                        theme.secondary,
                                        theme.accent,
                                        theme.surfaceAlt,
                                      ])
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: theme.outline.withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBack(context),
        ),
        title: const UserAppBarTitle(title: 'Settings'),
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final themeProvider = context.read<ThemeProvider>();
          final palette = AppTheme.of(context);
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.surface.withOpacity(palette.isDark ? 0.9 : 0.78),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.outline.withOpacity(0.6)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ProfileAvatar(
                              photoUrl: user.photoUrl,
                              radius: 40,
                              iconSize: 40,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: authProvider.isLoading
                                    ? null
                                    : _pickProfilePhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user.role == 'admin'
                                      ? palette.badgeAdmin
                                      : palette.badgeMember,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _buildCompactActionButton(
                                    context: context,
                                    label: 'Change Name',
                                    icon: Icons.edit_outlined,
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : () => _showEditNameDialog(
                                              user.displayName,
                                            ),
                                  ),
                                  _buildCompactActionButton(
                                    context: context,
                                    label: 'Add Photo',
                                    icon: Icons.image_outlined,
                                    onPressed: authProvider.isLoading
                                        ? null
                                        : _pickProfilePhoto,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),

                // General Settings
                ListTile(
                  leading: const Icon(Icons.people_outlined),
                  title: const Text('Family Members'),
                  onTap: () => context.go('/family/members'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Categories'),
                  onTap: () => context.go('/settings/categories'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
                const Divider(),

                // App Settings
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'App Settings',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(themeProvider.activeTheme.name),
                  onTap: () => _showThemePicker(
                    authProvider: authProvider,
                    themeProvider: themeProvider,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Notification settings coming soon')),
                    );
                  },
                ),
                const Divider(),

                // Account
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Account',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('About'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About Family Calendar'),
                        content: const Text(
                          'Family Calendar v1.0.0\n\n'
                          'A colorful family calendar that makes planning easy for everyone. '
                          'Share events, reminders, and activities in one fun place.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: const Text('Sign Out'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _clearLoadedData();
                              authProvider.signOut();
                              context.go('/login');
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
