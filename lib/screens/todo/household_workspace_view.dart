import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/shopping_item_model.dart';
import '../../models/shopping_list_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/asset_catalog.dart';

Future<void> showShoppingListEditor(
  BuildContext context, {
  ShoppingList? existing,
}) async {
  final strings = AppStrings.read(context);
  final controller = TextEditingController(text: existing?.title ?? '');
  final provider = context.read<HouseholdProvider>();
  var isShared = existing?.isShared ?? true;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(existing == null ? strings.newList : strings.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: strings.chooseListName),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.shareWithFamily),
              value: existing?.isStatic == true ? true : isShared,
              onChanged: existing?.isStatic == true
                  ? null
                  : (value) => setDialogState(() => isShared = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(existing == null ? strings.create : strings.save),
          ),
        ],
      ),
    ),
  );

  if (result != true || !context.mounted || controller.text.trim().isEmpty) {
    return;
  }

  if (existing == null) {
    await provider.createShoppingList(
      title: controller.text.trim(),
      isShared: isShared,
    );
  } else {
    await provider.updateShoppingList(
      list: existing,
      title: controller.text.trim(),
      isShared: isShared,
    );
  }
}

class ShoppingWorkspaceView extends StatefulWidget {
  final bool hasFamily;

  const ShoppingWorkspaceView({
    super.key,
    required this.hasFamily,
  });

  @override
  State<ShoppingWorkspaceView> createState() => _ShoppingWorkspaceViewState();
}

class _ShoppingWorkspaceViewState extends State<ShoppingWorkspaceView> {
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Consumer2<HouseholdProvider, AuthProvider>(
      builder: (context, householdProvider, authProvider, _) {
        if (widget.hasFamily && !_seeded) {
          _seeded = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<HouseholdProvider>().ensureDefaultShoppingLists();
          });
        }

        if (!widget.hasFamily) {
          return _EmptyWorkspaceMessage(
            icon: Icons.groups_outlined,
            title: strings.joinFamilyShopping,
            subtitle: strings.shoppingNeedsFamily,
          );
        }

        final currentUserId = authProvider.currentUser?.uid;
        final shoppingLists = householdProvider.shoppingLists.where((list) {
          return list.isShared || list.createdBy == currentUserId;
        }).toList();

        if (shoppingLists.isEmpty) {
          return _EmptyWorkspaceMessage(
            icon: Icons.shopping_bag_outlined,
            title: strings.noItemsYet,
            subtitle: strings.defaultShoppingLists,
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          itemCount: shoppingLists.length,
          buildDefaultDragHandles: false,
          proxyDecorator: (child, _, __) => Material(
            color: Colors.transparent,
            child: child,
          ),
          onReorder: (oldIndex, newIndex) async {
            final ordered = [...shoppingLists];
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final moved = ordered.removeAt(oldIndex);
            ordered.insert(newIndex, moved);
            await householdProvider.reorderShoppingLists(ordered);
          },
          itemBuilder: (context, index) {
            final list = shoppingLists[index];
            final items = householdProvider.itemsForList(
              list.id,
              includeChecked: true,
            );
            final config = _ShoppingListConfig.forTitle(list.title, strings);
            final localizedTitle = _localizedShoppingListTitle(list.title, strings);
            return Padding(
              key: ValueKey(list.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ShoppingListDetailScreen(list: list),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        AppTheme.of(context).isDark ? 0.08 : 0.95,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.of(context).vibrantOutline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Tooltip(
                              message: strings.reorderHint,
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                color: AppTheme.of(context).textMuted,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          child: Icon(config.icon, color: config.color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizedTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${strings.shoppingItemsCount(items.length)} • ${list.isShared ? strings.sharedList : strings.privateList}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.of(context).textMuted,
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (value) async {
                            if (value == 'create_event') {
                              _openShoppingListEvent(context, list, items);
                            } else if (value == 'edit') {
                              await showShoppingListEditor(context, existing: list);
                            } else if (value == 'share') {
                              await context.read<HouseholdProvider>().updateShoppingList(
                                    list: list,
                                    title: list.title,
                                    isShared: !list.isShared,
                                  );
                            } else if (value == 'delete') {
                              await householdProvider.deleteShoppingList(list);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'create_event',
                              child: Text(strings.createEvent),
                            ),
                            if (!list.isStatic)
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(strings.edit),
                            ),
                            if (!list.isStatic)
                            PopupMenuItem(
                              value: 'share',
                              child: Text(
                                list.isShared
                                    ? strings.makePrivate
                                    : strings.shareWithFamily,
                              ),
                            ),
                            if (!list.isStatic)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(strings.deleteList),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ShoppingListDetailScreen extends StatelessWidget {
  final ShoppingList list;

  const _ShoppingListDetailScreen({required this.list});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_localizedShoppingListTitle(list.title, strings))),
      body: _ShoppingListDetailBody(list: list),
    );
  }
}

class _ShoppingListDetailBody extends StatelessWidget {
  final ShoppingList list;

  const _ShoppingListDetailBody({required this.list});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Consumer<HouseholdProvider>(
      builder: (context, provider, _) {
        final items = provider.itemsForList(list.id, includeChecked: true);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showShoppingItemDialog(context, provider),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(strings.addItem),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _EmptyWorkspaceMessage(
                      icon: Icons.receipt_long_outlined,
                      title: strings.noItemsYet,
                      subtitle: strings.addFirstItem,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _ShoppingItemTile(
                          list: list,
                          item: item,
                          onEdit: () => _showShoppingItemDialog(
                            context,
                            provider,
                            existing: item,
                          ),
                          onDelete: () => provider.deleteShoppingItem(item),
                          onCreateEvent: () => _openShoppingItemEvent(context, item),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showShoppingItemDialog(
    BuildContext context,
    HouseholdProvider provider, {
    ShoppingItem? existing,
  }) async {
    final result = await showDialog<_ShoppingItemDraft>(
      context: context,
      builder: (_) => _ShoppingItemDialog(
        list: list,
        existing: existing,
      ),
    );
    if (result == null || !context.mounted) {
      return;
    }

    if (existing == null) {
      await provider.addShoppingItem(
        list: list,
        name: result.name,
        quantity: result.quantity,
        category: result.category,
        aisle: result.aisle,
        note: result.note,
      );
    } else {
      await provider.updateShoppingItem(
        item: existing,
        name: result.name,
        quantity: result.quantity,
        category: result.category,
        aisle: result.aisle,
        note: result.note,
      );
    }
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingList list;
  final ShoppingItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCreateEvent;

  const _ShoppingItemTile({
    required this.list,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _assetForItem(list.title, item.name),
      builder: (context, snapshot) {
        final provider = context.read<HouseholdProvider>();
        final strings = AppStrings.read(context);
        final assetPath = snapshot.data;
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            minLeadingWidth: 0,
            leading: Checkbox(
              value: item.checked,
              onChanged: (value) => provider.updateShoppingItem(
                item: item,
                checked: value ?? false,
              ),
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${item.category} • ${item.aisle} • Qty ${item.quantity}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (assetPath != null)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                else
                  const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.shopping_basket_outlined, size: 16),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'create_event') {
                      onCreateEvent();
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'create_event',
                      child: Text(strings.createEvent),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(strings.edit),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(strings.delete),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShoppingItemDialog extends StatefulWidget {
  final ShoppingList list;
  final ShoppingItem? existing;

  const _ShoppingItemDialog({
    required this.list,
    this.existing,
  });

  @override
  State<_ShoppingItemDialog> createState() => _ShoppingItemDialogState();
}

class _ShoppingItemDialogState extends State<_ShoppingItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _categoryController;
  late final TextEditingController _aisleController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _quantityController =
        TextEditingController(text: '${widget.existing?.quantity ?? 1}');
    _categoryController =
        TextEditingController(text: widget.existing?.category ?? '');
    _aisleController = TextEditingController(text: widget.existing?.aisle ?? '');
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _aisleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final assetPrefix = assetPrefixForStaticList(widget.list.title);
    return AlertDialog(
      title: Text(widget.existing == null ? strings.addItemTitle : strings.editItem),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (assetPrefix != null)
                FutureBuilder<List<String>>(
                  future: AssetCatalog.listAssets(assetPrefix),
                  builder: (context, snapshot) {
                    final options = (snapshot.data ?? const <String>[])
                        .map(AssetCatalog.labelFromAssetPath)
                        .toList();
                    return Autocomplete<String>(
                      optionsBuilder: (value) {
                        final query = AssetCatalog.normalizedLookup(value.text);
                        if (query.isEmpty) {
                          return options.take(8);
                        }
                        return options.where(
                          (option) =>
                              AssetCatalog.normalizedLookup(option).contains(query),
                        ).take(8);
                      },
                      onSelected: (value) => _nameController.text = value,
                      fieldViewBuilder: (context, controller, focusNode, _) {
                        controller.text = _nameController.text;
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                        controller.addListener(() {
                          _nameController.text = controller.text;
                        });
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: strings.itemName,
                            helperText: strings.typeCustomItem,
                          ),
                        );
                      },
                    );
                  },
                )
              else
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: strings.itemName),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: strings.quantity),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: strings.category),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _aisleController,
                decoration: InputDecoration(labelText: strings.aisle),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(labelText: strings.note),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              _ShoppingItemDraft(
                name: _nameController.text.trim(),
                quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
                category: _categoryController.text.trim(),
                aisle: _aisleController.text.trim(),
                note: _noteController.text.trim(),
              ),
            );
          },
          child: Text(widget.existing == null ? strings.add : strings.save),
        ),
      ],
    );
  }
}

class _ShoppingItemDraft {
  final String name;
  final int quantity;
  final String category;
  final String aisle;
  final String note;

  const _ShoppingItemDraft({
    required this.name,
    required this.quantity,
    required this.category,
    required this.aisle,
    required this.note,
  });
}

class _ShoppingListConfig {
  final IconData icon;
  final Color color;

  const _ShoppingListConfig(this.icon, this.color);

  static _ShoppingListConfig forTitle(String title, AppStrings strings) {
    final key = title.toLowerCase();
    if (key.contains('grocery') || key == strings.groceryList.toLowerCase()) {
      return const _ShoppingListConfig(Icons.local_grocery_store_outlined, Color(0xFF1E9B62));
    }
    if (key.contains('packing')) {
      return const _ShoppingListConfig(Icons.luggage_outlined, Color(0xFF2E7DDB));
    }
    if (key.contains('gift')) {
      return const _ShoppingListConfig(Icons.card_giftcard_outlined, Color(0xFFD97706));
    }
    if (key.contains('house')) {
      return const _ShoppingListConfig(Icons.home_repair_service_outlined, Color(0xFF8B5CF6));
    }
    if (key.contains('movie')) {
      return const _ShoppingListConfig(Icons.movie_outlined, Color(0xFFDC2626));
    }
    if (key.contains('trip')) {
      return const _ShoppingListConfig(Icons.map_outlined, Color(0xFF0EA5E9));
    }
    return const _ShoppingListConfig(Icons.list_alt_outlined, Color(0xFF6B7280));
  }
}

class _EmptyWorkspaceMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyWorkspaceMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 62, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

void _openShoppingItemEvent(BuildContext context, ShoppingItem item) {
  context.push(
    '/event/add',
    extra: {
      'title': item.name,
      'notes': item.note,
      'preferredCategoryName': 'Shopping',
    },
  );
}

void _openShoppingListEvent(
  BuildContext context,
  ShoppingList list,
  List<ShoppingItem> items,
) {
  final itemNames = items
      .map((item) => item.name.trim())
      .where((name) => name.isNotEmpty)
      .toList();
  context.push(
    '/event/add',
    extra: {
      'title': list.title,
      'notes': itemNames.isEmpty ? null : itemNames.join(', '),
      'preferredCategoryName': 'Shopping',
    },
  );
}

String _localizedShoppingListTitle(String title, AppStrings strings) {
  switch (title.trim().toLowerCase()) {
    case 'grocery list':
      return strings.groceryList;
    case 'packing list':
      return strings.packingList;
    case 'gift ideas':
      return strings.giftIdeas;
    case 'house project':
    case 'house projects':
      return strings.houseProjects;
    case 'movies to watch':
      return strings.moviesToWatch;
    case 'trip ideas':
      return strings.tripIdeas;
    case 'others':
      return strings.others;
    default:
      return title;
  }
}

String? assetPrefixForStaticList(String listTitle) {
  switch (listTitle.trim().toLowerCase()) {
    case 'grocery list':
      return 'img/_Grocery List/';
    case 'house project':
    case 'house projects':
      return 'img/_House Project/';
    case 'packing list':
      return 'img/_Packaging List/';
    case 'gift ideas':
      return 'img/_Gift Ideas/';
    case 'trip ideas':
      return 'img/_Trip Ideas/';
    case 'movies to watch':
      return 'img/_Movies to Watch/';
    case 'others':
      return 'img/_Others/';
    default:
      return null;
  }
}

Future<String?> _assetForItem(String listTitle, String itemName) async {
  final assetPrefix = assetPrefixForStaticList(listTitle);
  if (assetPrefix == null) {
    return null;
  }

  final assets = await AssetCatalog.listAssets(assetPrefix);
  final lookup = AssetCatalog.normalizedLookup(itemName);
  for (final asset in assets) {
    final assetLabel = AssetCatalog.labelFromAssetPath(asset);
    if (AssetCatalog.normalizedLookup(assetLabel) == lookup) {
      return asset;
    }
  }
  return assets.isNotEmpty ? assets.first : null;
}
