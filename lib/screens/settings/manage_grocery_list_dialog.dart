import 'package:flutter/material.dart';

import '../../models/grocery_search_item_model.dart';
import '../../providers/household_provider.dart';
import '../../theme/app_theme.dart';

Future<void> showManageGroceryListDialog(
  BuildContext context,
  HouseholdProvider provider,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ManageGroceryListDialog(provider: provider),
  );
}

class _ManageGroceryListDialog extends StatefulWidget {
  final HouseholdProvider provider;

  const _ManageGroceryListDialog({required this.provider});

  @override
  State<_ManageGroceryListDialog> createState() =>
      _ManageGroceryListDialogState();
}

class _ManageGroceryListDialogState extends State<_ManageGroceryListDialog> {
  final List<_GrocerySearchEditorRow> _rows = [];
  int _nextLocalId = 0;
  String _selectedCategoryFilter = 'All';
  String _selectedTypeFilter = 'All';

  @override
  void initState() {
    super.initState();
    for (final item in widget.provider.grocerySearchItems) {
      _rows.add(
        _GrocerySearchEditorRow(
          localId: _nextLocalId++,
          item: item,
        ),
      );
    }
  }

  List<String> _distinctCategories() {
    final values = _rows
        .map((row) => row.item.category.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  List<String> _distinctTypes() {
    final values = _rows
        .map((row) => row.item.itemType.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  List<String> _distinctTypesForSelectedCategory() {
    final sourceRows = _selectedCategoryFilter == 'All'
        ? _rows
        : _rows.where(
            (row) => row.item.category.trim() == _selectedCategoryFilter,
          );
    final values = sourceRows
        .map((row) => row.item.itemType.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  List<_GrocerySearchEditorRow> _filteredRows() {
    return _rows.where((row) {
      final matchesCategory = _selectedCategoryFilter == 'All' ||
          row.item.category.trim() == _selectedCategoryFilter;
      final matchesType = _selectedTypeFilter == 'All' ||
          row.item.itemType.trim() == _selectedTypeFilter;
      return matchesCategory && matchesType;
    }).toList();
  }

  Future<void> _showAddItemDialog() async {
    final draft = await showDialog<_GroceryItemDraft>(
      context: context,
      builder: (context) => _AddGroceryItemDialog(
        categoryOptions: _distinctCategories(),
        typeOptions: _distinctTypes(),
      ),
    );
    if (draft == null) {
      return;
    }

    setState(() {
      _rows.add(
        _GrocerySearchEditorRow(
          localId: _nextLocalId++,
          item: GrocerySearchItem(
            id: '',
            familyId: '',
            category: draft.category,
            itemType: draft.itemType,
            itemName: draft.itemName,
            iconName: '',
            createdBy: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  Future<void> _showEditItemDialog(int index) async {
    final existing = _rows[index].item;
    final draft = await showDialog<_GroceryItemDraft>(
      context: context,
      builder: (context) => _AddGroceryItemDialog(
        categoryOptions: _distinctCategories(),
        typeOptions: _distinctTypes(),
        existing: existing,
      ),
    );
    if (draft == null) {
      return;
    }

    setState(() {
      final current = _rows[index];
      _rows[index] = current.copyWith(
        item: current.item.copyWith(
          category: draft.category,
          itemType: draft.itemType,
          itemName: draft.itemName,
        ),
      );
    });
  }

  void _clearSelection() {
    setState(() {
      for (var i = 0; i < _rows.length; i++) {
        _rows[i] = _rows[i].copyWith(selected: false);
      }
    });
  }

  void _sortRows() {
    setState(() {
      _rows.sort((a, b) {
        final categoryCompare = a.item.category
            .toLowerCase()
            .compareTo(b.item.category.toLowerCase());
        if (categoryCompare != 0) {
          return categoryCompare;
        }
        final typeCompare = a.item.itemType
            .toLowerCase()
            .compareTo(b.item.itemType.toLowerCase());
        if (typeCompare != 0) {
          return typeCompare;
        }
        return a.item.itemName
            .toLowerCase()
            .compareTo(b.item.itemName.toLowerCase());
      });
    });
  }

  void _deleteSelected() {
    setState(() {
      _rows.removeWhere((row) => row.selected);
    });
  }

  Future<void> _save() async {
    final items = _rows
        .map((row) => row.item)
        .where(
          (item) =>
              item.itemName.trim().isNotEmpty ||
              item.category.trim().isNotEmpty ||
              item.itemType.trim().isNotEmpty,
        )
        .toList();
    await widget.provider.replaceGrocerySearchItems(items);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filteredRows = _filteredRows();
    final categoryFilterOptions = ['All', ..._distinctCategories()];
    final distinctTypesForSelectedCategory = _distinctTypesForSelectedCategory();
    final typeFilterOptions = ['All', ...distinctTypesForSelectedCategory];
    final effectiveSelectedTypeFilter =
        _selectedTypeFilter != 'All' &&
                !distinctTypesForSelectedCategory.contains(_selectedTypeFilter)
            ? 'All'
            : _selectedTypeFilter;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 1080,
        height: 760,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.of(context).surfaceAlt.withOpacity(
                            AppTheme.of(context).isDark ? 0.32 : 0.9,
                          ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Image.asset(
                        'img/_Grocery List/list-view.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Manage Grocery Catalog',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Item'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity:
                          const VisualDensity(horizontal: -2, vertical: -2),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    onPressed: _rows.any((row) => row.selected)
                        ? _clearSelection
                        : null,
                    tooltip: 'Clear selection',
                    visualDensity:
                        const VisualDensity(horizontal: -4, vertical: -4),
                    icon: const Icon(Icons.deselect_outlined, size: 16),
                  ),
                  TextButton(
                    onPressed:
                        _rows.any((row) => row.selected) ? _deleteSelected : null,
                    style: TextButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity:
                          const VisualDensity(horizontal: -2, vertical: -2),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Delete selected'),
                  ),
                  OutlinedButton(
                    onPressed: _sortRows,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity:
                          const VisualDensity(horizontal: -2, vertical: -2),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Sort'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _FilterDropdown(
                      label: 'Category',
                      value: _selectedCategoryFilter,
                      items: categoryFilterOptions,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedCategoryFilter = value;
                          final availableTypes =
                              _distinctTypesForSelectedCategory();
                          if (_selectedTypeFilter != 'All' &&
                              !availableTypes.contains(_selectedTypeFilter)) {
                            _selectedTypeFilter = 'All';
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FilterDropdown(
                      label: 'Item Type',
                      value: effectiveSelectedTypeFilter,
                      items: typeFilterOptions,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedTypeFilter = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Add/Update/Delete Grocery items:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.of(context).textMuted,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${filteredRows.length} row${filteredRows.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.of(context).textMuted,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.of(context).surfaceAlt.withOpacity(
                        AppTheme.of(context).isDark ? 0.28 : 0.8,
                      ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('', style: _gridHeaderStyle(context)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text('Cat', style: _gridHeaderStyle(context)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text('Type', style: _gridHeaderStyle(context)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text('Item', style: _gridHeaderStyle(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredRows.length,
                  itemBuilder: (context, index) {
                    final row = filteredRows[index];
                    final rowIndex = _rows.indexWhere(
                      (candidate) => candidate.localId == row.localId,
                    );
                    return InkWell(
                      key: ValueKey(row.localId),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showEditItemDialog(rowIndex),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.of(context)
                                .vibrantOutline
                                .withOpacity(0.18),
                          ),
                          color: Colors.white.withOpacity(
                            AppTheme.of(context).isDark ? 0.04 : 0.92,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Transform.scale(
                                scale: 0.82,
                                child: Checkbox(
                                  value: row.selected,
                                  visualDensity: const VisualDensity(
                                    horizontal: -4,
                                    vertical: -4,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _rows[rowIndex] = row.copyWith(
                                        selected: value ?? false,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Text(
                                row.item.category,
                                style: _gridCellStyle(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Text(
                                row.item.itemType,
                                style: _gridCellStyle(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                row.item.itemName,
                                style: _gridCellStyle(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.of(context).textMuted,
                ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          isDense: true,
          isExpanded: true,
          menuMaxHeight: 280,
          decoration: _filterDecoration(),
          style: _filterTextStyle(context),
          iconSize: 18,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _GrocerySearchEditorRow {
  final int localId;
  final GrocerySearchItem item;
  final bool selected;

  const _GrocerySearchEditorRow({
    required this.localId,
    required this.item,
    this.selected = false,
  });

  _GrocerySearchEditorRow copyWith({
    GrocerySearchItem? item,
    bool? selected,
  }) {
    return _GrocerySearchEditorRow(
      localId: localId,
      item: item ?? this.item,
      selected: selected ?? this.selected,
    );
  }
}

class _GroceryItemDraft {
  final String category;
  final String itemType;
  final String itemName;

  const _GroceryItemDraft({
    required this.category,
    required this.itemType,
    required this.itemName,
  });
}

class _AddGroceryItemDialog extends StatefulWidget {
  final List<String> categoryOptions;
  final List<String> typeOptions;
  final GrocerySearchItem? existing;

  const _AddGroceryItemDialog({
    required this.categoryOptions,
    required this.typeOptions,
    this.existing,
  });

  @override
  State<_AddGroceryItemDialog> createState() => _AddGroceryItemDialogState();
}

class _AddGroceryItemDialogState extends State<_AddGroceryItemDialog> {
  late final TextEditingController _categoryController;
  late final TextEditingController _typeController;
  late final TextEditingController _itemController;

  @override
  void initState() {
    super.initState();
    _categoryController =
        TextEditingController(text: widget.existing?.category ?? '');
    _typeController =
        TextEditingController(text: widget.existing?.itemType ?? '');
    _itemController =
        TextEditingController(text: widget.existing?.itemName ?? '');
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _typeController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _submit() {
    final itemName = _itemController.text.trim();
    if (itemName.isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      _GroceryItemDraft(
        category: _categoryController.text.trim(),
        itemType: _typeController.text.trim(),
        itemName: itemName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add New Item' : 'Edit Item'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AutocompleteEditorField(
              label: 'Category',
              controller: _categoryController,
              options: widget.categoryOptions,
            ),
            const SizedBox(height: 12),
            _AutocompleteEditorField(
              label: 'Item Type',
              controller: _typeController,
              options: widget.typeOptions,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.existing == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

class _AutocompleteEditorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> options;

  const _AutocompleteEditorField({
    required this.label,
    required this.controller,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final menuOptions = options.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Autocomplete<String>(
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return menuOptions.take(8);
        }
        return menuOptions
            .where((option) => option.toLowerCase().contains(query))
            .take(8);
      },
      onSelected: (value) => controller.text = value,
      fieldViewBuilder: (context, textEditingController, focusNode, _) {
        if (controller.text.isNotEmpty &&
            textEditingController.text != controller.text) {
          textEditingController.value = TextEditingValue(
            text: controller.text,
            selection: TextSelection.collapsed(offset: controller.text.length),
          );
        }

        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: menuOptions.isEmpty
                ? null
                : PopupMenuButton<String>(
                    tooltip: 'Show $label options',
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (value) {
                      controller.text = value;
                      textEditingController.value = TextEditingValue(
                        text: value,
                        selection: TextSelection.collapsed(
                          offset: value.length,
                        ),
                      );
                    },
                    itemBuilder: (context) => menuOptions
                        .map(
                          (option) => PopupMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                  ),
          ),
          onChanged: (value) => controller.text = value,
        );
      },
    );
  }
}

InputDecoration _filterDecoration() {
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: const OutlineInputBorder(),
  );
}

TextStyle _filterTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 12,
      ) ??
      const TextStyle(fontSize: 12);
}

TextStyle _gridHeaderStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ) ??
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
}

TextStyle _gridCellStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 12,
      ) ??
      const TextStyle(fontSize: 12);
}
