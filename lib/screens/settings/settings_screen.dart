import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart' as app_user;
import '../../services/notification_service.dart';
import 'manage_grocery_list_dialog.dart';
import '../../theme/app_theme.dart';
import '../../utils/asset_catalog.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/user_app_bar_title.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isResettingGroceryCatalog = false;

  String _formatNotificationTime(app_user.NotificationPreferences prefs) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      prefs.dailySummaryHour,
      prefs.dailySummaryMinute,
    );
    return DateFormat.jm().format(dateTime);
  }

  String _notificationSubtitle(app_user.NotificationPreferences prefs) {
    final enabledCount = [
      prefs.notifyOnNewFamilyList,
      prefs.notifyOnNewFamilyTask,
      prefs.notifyOnTaskAssignedToMe,
      prefs.notifyDailyMorningSummary,
    ].where((value) => value).length;

    if (enabledCount == 0) {
      return 'All notifications are off';
    }

    if (prefs.notifyDailyMorningSummary) {
      return '$enabledCount enabled, daily summary at ${_formatNotificationTime(prefs)}';
    }

    return '$enabledCount enabled';
  }

  Future<void> _showNotificationSettings(AuthProvider authProvider) async {
    final currentPrefs = authProvider.currentUser?.notificationPreferences ??
        const app_user.NotificationPreferences();
    final palette = AppTheme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var draft = currentPrefs;

        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose which updates you want to receive.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: draft.notifyOnNewFamilyList,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Notify me when a new family list is created',
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        draft = draft.copyWith(
                          notifyOnNewFamilyList: value ?? false,
                        );
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: draft.notifyOnNewFamilyTask,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Notify me when a new family list task is created',
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        draft = draft.copyWith(
                          notifyOnNewFamilyTask: value ?? false,
                        );
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: draft.notifyOnTaskAssignedToMe,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Notify me when a task is assigned to me'),
                    onChanged: (value) {
                      setSheetState(() {
                        draft = draft.copyWith(
                          notifyOnTaskAssignedToMe: value ?? false,
                        );
                      });
                    },
                  ),
                  CheckboxListTile(
                    value: draft.notifyDailyMorningSummary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Daily morning summary for events and tasks due today',
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        draft = draft.copyWith(
                          notifyDailyMorningSummary: value ?? false,
                        );
                      });
                    },
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: draft.notifyDailyMorningSummary
                        ? Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Summary time: ${_formatNotificationTime(draft)}',
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final selectedTime = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: draft.dailySummaryHour,
                                        minute: draft.dailySummaryMinute,
                                      ),
                                    );
                                    if (selectedTime == null) {
                                      return;
                                    }
                                    setSheetState(() {
                                      draft = draft.copyWith(
                                        dailySummaryHour: selectedTime.hour,
                                        dailySummaryMinute:
                                            selectedTime.minute,
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.schedule_outlined),
                                  label: const Text('Set time'),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () async {
                        await authProvider.updateProfile(
                          notificationPreferences: draft,
                        );
                        final notificationsEnabled = draft.notifyOnNewFamilyList ||
                            draft.notifyOnNewFamilyTask ||
                            draft.notifyOnTaskAssignedToMe ||
                            draft.notifyDailyMorningSummary;
                        var confirmationMessage =
                            'Notification settings updated';
                        if (notificationsEnabled) {
                          final didSendTest = await context
                              .read<NotificationService>()
                              .sendTestNotification();
                          if (!didSendTest) {
                            confirmationMessage =
                                'Settings saved, but notification permission is still unavailable on this device';
                          }
                        }
                        if (!mounted) {
                          return;
                        }
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(confirmationMessage),
                          ),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showShoppingPlacesDialog(FamilyProvider familyProvider) async {
    final family = familyProvider.currentFamily;
    final familyId = family?.id;
    if (familyId == null) {
      return;
    }

    final places = List<String>.from(family?.shoppingPlaces ?? const []);
    final controller = TextEditingController();
    final palette = AppTheme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shopping Places',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Add place',
                          hintText: 'Walmart, Costco, Target...',
                        ),
                        onSubmitted: (_) {
                          final value = controller.text.trim();
                          if (value.isEmpty || places.contains(value)) {
                            return;
                          }
                          setSheetState(() {
                            places.add(value);
                            controller.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty || places.contains(value)) {
                          return;
                        }
                        setSheetState(() {
                          places.add(value);
                          controller.clear();
                        });
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (places.isEmpty)
                  Text(
                    'No shopping places added yet.',
                    style: TextStyle(color: palette.textMuted),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: places
                        .map(
                          (place) => InputChip(
                            label: Text(place),
                            onDeleted: () {
                              setSheetState(() => places.remove(place));
                            },
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () async {
                      await familyProvider.updateShoppingPlaces(
                        familyId: familyId,
                        shoppingPlaces: places,
                      );
                      if (!mounted) return;
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearLoadedData() {
    context.read<FamilyProvider>().clear();
    context.read<CategoryProvider>().clear();
    context.read<EventProvider>().clear();
  }

  Future<void> _resetGroceryCatalog(
    HouseholdProvider householdProvider,
    bool hasFamily,
  ) async {
    if (!hasFamily || _isResettingGroceryCatalog) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Reset Grocery Catalog'),
            content: const Text(
              'This will clear the current grocery master list for your family and repopulate it from the bundled import data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Reset'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() {
      _isResettingGroceryCatalog = true;
    });

    try {
      await householdProvider.resetImportedGroceryCatalog();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grocery catalog reset and re-imported'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to reset grocery catalog: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResettingGroceryCatalog = false;
        });
      }
    }
  }

  Future<void> _showBundledAvatarPicker() async {
    final strings = AppStrings.read(context);
    final assets = await AssetCatalog.listAssets('img/_Profile Images/');
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.selectProfileImage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
              const SizedBox(height: 8),
              Text(strings.chooseFromApp),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: GridView.builder(
                  itemCount: assets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.84,
                  ),
                  itemBuilder: (context, index) {
                    final assetPath = assets[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final didUpdate = await context
                            .read<AuthProvider>()
                            .setBundledProfilePhoto(assetPath);
                        if (!mounted) return;
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              didUpdate
                                  ? strings.profilePhotoUpdated
                                  : (context
                                          .read<AuthProvider>()
                                          .errorMessage ??
                                      strings.unableToSelectImage),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.of(context).surface.withOpacity(0.84),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                AppTheme.of(context).outline.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                                child: Image.asset(assetPath,
                                    fit: BoxFit.contain)),
                            const SizedBox(height: 6),
                            Text(
                              AssetCatalog.labelFromAssetPath(assetPath),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium,
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
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(
    AuthProvider authProvider,
    LocaleProvider localeProvider,
  ) async {
    final strings = AppStrings.read(context);
    final options = {
      'en': strings.english,
      'es': strings.spanish,
      'hi': strings.hindi,
    };
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries
              .map(
                (entry) => RadioListTile<String>(
                  value: entry.key,
                  groupValue: localeProvider.languageCode,
                  title: Text(entry.value),
                  onChanged: (value) async {
                    if (value == null) return;
                    localeProvider.setLanguageCode(value);
                    await authProvider.updateProfile(languageCode: value);
                    if (!mounted) return;
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.languageUpdated)),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _showThemePicker(
    AuthProvider authProvider,
    ThemeProvider themeProvider,
  ) async {
    final strings = AppStrings.read(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.chooseTheme,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(strings.themeSaved),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.separated(
                  itemCount: AppTheme.themes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final theme = AppTheme.themes[index];
                    final isSelected = themeProvider.themeId == theme.id;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: isSelected
                              ? theme.primary
                              : theme.outline.withOpacity(0.4),
                        ),
                      ),
                      tileColor:
                          theme.surface.withOpacity(theme.isDark ? 0.95 : 0.88),
                      leading: CircleAvatar(
                        backgroundColor: theme.primary.withOpacity(0.18),
                        child:
                            Icon(Icons.palette_outlined, color: theme.primary),
                      ),
                      title: Text(
                        theme.name,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        theme.description,
                        style: TextStyle(color: theme.textMuted),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: theme.primary)
                          : null,
                      onTap: () async {
                        themeProvider.setTheme(theme.id);
                        await authProvider.updateProfile(themeId: theme.id);
                        if (!mounted) return;
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Consumer5<AuthProvider, ThemeProvider, LocaleProvider,
        FamilyProvider, HouseholdProvider>(
      builder: (context, authProvider, themeProvider, localeProvider,
          familyProvider, householdProvider, _) {
        final user = authProvider.currentUser;
        final palette = AppTheme.of(context);
        final notificationPrefs =
            user?.notificationPreferences ??
            const app_user.NotificationPreferences();
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
            title: UserAppBarTitle(title: strings.configuration),
          ),
          body: user == null
              ? Center(child: Text(strings.notLoggedIn))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: palette.surface.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: palette.outline.withOpacity(0.6)),
                      ),
                      child: Row(
                        children: [
                          ProfileAvatar(
                              photoUrl: user.photoUrl,
                              radius: 54,
                              iconSize: 52),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text(user.email,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _actionButton(
                                        strings.showBundledAvatars,
                                        Icons.auto_awesome_outlined,
                                        _showBundledAvatarPicker),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.translate_outlined),
                      title: Text(strings.language),
                      subtitle: Text(
                        switch (localeProvider.languageCode) {
                          'es' => strings.spanish,
                          'hi' => strings.hindi,
                          _ => strings.english,
                        },
                      ),
                      onTap: () =>
                          _showLanguagePicker(authProvider, localeProvider),
                    ),
                    ListTile(
                      leading: const Icon(Icons.brightness_6_outlined),
                      title: Text(strings.theme),
                      subtitle: Text(themeProvider.activeTheme.name),
                      onTap: () =>
                          _showThemePicker(authProvider, themeProvider),
                    ),
                    ListTile(
                      leading: const Icon(Icons.people_outlined),
                      title: Text(strings.familyMembers),
                      onTap: () => context.go('/family/members'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(strings.categories),
                      onTap: () => context.go('/settings/categories'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: const Text('Shopping Places'),
                      subtitle: Text(
                        familyProvider.currentFamily?.shoppingPlaces.isEmpty ??
                                true
                            ? 'Add pickup/store locations'
                            : familyProvider.currentFamily!.shoppingPlaces
                                .join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: user.familyId == null
                          ? null
                          : () => _showShoppingPlacesDialog(familyProvider),
                    ),
                    ListTile(
                      leading: const Icon(Icons.local_grocery_store_outlined),
                      title: const Text('Manage Grocery List'),
                      subtitle: const Text(
                        'Edit grocery search items and icon matching',
                      ),
                      onTap: () => showManageGroceryListDialog(
                        context,
                        householdProvider,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.refresh_outlined),
                      title: const Text('Reset Grocery Catalog'),
                      subtitle: Text(
                        _isResettingGroceryCatalog
                            ? 'Re-importing grocery master list...'
                            : 'Clear and repopulate the grocery master list now',
                      ),
                      enabled: user.familyId != null && !_isResettingGroceryCatalog,
                      onTap: user.familyId == null || _isResettingGroceryCatalog
                          ? null
                          : () => _resetGroceryCatalog(
                                householdProvider,
                                user.familyId != null,
                              ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: Text(_notificationSubtitle(notificationPrefs)),
                      onTap: () => _showNotificationSettings(authProvider),
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text(strings.about),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(strings.aboutTitle),
                          content: Text(strings.aboutBody),
                          actions: [
                            TextButton(
                              onPressed: () => context.pop(),
                              child: Text(strings.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout_outlined),
                      title: Text(strings.signOut),
                      onTap: () {
                        _clearLoadedData();
                        authProvider.signOut();
                        context.go('/login');
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _actionButton(
      String label, IconData icon, Future<void> Function() onPressed) {
    return Builder(
      builder: (context) => OutlinedButton.icon(
        onPressed: () {
          onPressed();
        },
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        ),
      ),
    );
  }
}
