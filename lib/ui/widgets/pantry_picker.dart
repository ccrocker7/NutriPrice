import 'package:flutter/material.dart';
import '../../domain/models/food_item.dart';
import '../screens/add_food_screen.dart';

/// Shows a searchable dialog to pick a food item from the pantry
Future<FoodItem?> showPantryPicker(
  BuildContext context,
  List<FoodItem> pantry,
) async {
  return showDialog<FoodItem>(
    context: context,
    builder: (context) => _SearchablePantryPicker(pantry: pantry),
  );
}

class _SearchablePantryPicker extends StatefulWidget {
  final List<FoodItem> pantry;

  const _SearchablePantryPicker({required this.pantry});

  @override
  State<_SearchablePantryPicker> createState() =>
      _SearchablePantryPickerState();
}

class _SearchablePantryPickerState extends State<_SearchablePantryPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _filteredPantry = [];

  @override
  void initState() {
    super.initState();
    _filteredPantry = widget.pantry;
    _searchController.addListener(_filterPantry);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPantry() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPantry = widget.pantry
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search Pantry',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Search Field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type to search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surface.withAlpha(128),
                ),
              ),
            ),

            // Results List
            Expanded(
              child: _filteredPantry.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      itemCount: _filteredPantry.length,
                      itemBuilder: (context, index) {
                        final item = _filteredPantry[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.restaurant,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${item.calories.toStringAsFixed(0)} kcal • ${item.servingSize.toStringAsFixed(0)} ${item.servingUnit.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(179),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(128),
                          ),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Your pantry is empty'
                  : 'No items match "${_searchController.text}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context); // Close search dialog
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const AddFoodScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Food'),
            ),
          ],
        ),
      ),
    );
  }
}
