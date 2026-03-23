import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/user_app_bar_title.dart';

class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({Key? key}) : super(key: key);

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  final _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFF5C6BC0);

  static const List<Color> _colorOptions = [
    Color(0xFFB71C1C),
    Color(0xFFD84315),
    Color(0xFFEF6C00),
    Color(0xFFF9A825),
    Color(0xFF9E9D24),
    Color(0xFF558B2F),
    Color(0xFF2E7D32),
    Color(0xFF00897B),
    Color(0xFF00695C),
    Color(0xFF00838F),
    Color(0xFF0277BD),
    Color(0xFF1565C0),
    Color(0xFF283593),
    Color(0xFF3949AB),
    Color(0xFF5E35B1),
    Color(0xFF7B1FA2),
    Color(0xFFAD1457),
    Color(0xFFC2185B),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
    Color(0xFF455A64),
    Color(0xFF607D8B),
    Color(0xFF78909C),
    Color(0xFF8D6E63),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/settings');
  }

  void _showAddCategoryDialog() {
    _nameController.clear();
    _selectedColor = const Color(0xFF5C6BC0);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Category name',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose a color',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _colorOptions.map((color) {
                    final isSelected = _selectedColor.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => _selectedColor = color);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.white,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.28),
                              blurRadius: isSelected ? 10 : 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a category name'),
                    ),
                  );
                  return;
                }

                final familyId = context.read<AuthProvider>().currentUser?.familyId;
                if (familyId != null) {
                  context.read<CategoryProvider>().addCategory(
                        familyId: familyId,
                        name: _nameController.text.trim(),
                        color: _selectedColor,
                      );
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
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
        title: const UserAppBarTitle(title: 'Categories'),
        elevation: 0,
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, _) {
          if (categoryProvider.categories.isEmpty) {
            return const Center(
              child: Text('No categories yet'),
            );
          }

          return ListView.builder(
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];

              return Dismissible(
                key: Key(category.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  categoryProvider.deleteCategory(category.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${category.name} deleted')),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.color,
                  ),
                  title: Text(category.name),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit feature coming soon'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
