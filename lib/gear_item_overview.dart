import 'package:flutter/material.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/hover_scrolling_text.dart';
import 'package:gear_list_planner/model.dart';
import 'package:provider/provider.dart';

class GearItemOverview extends StatelessWidget {
  const GearItemOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GearItemOverviewDataProvider>(
      builder: (context, dataProvider, _) {
        final gearCategoriesWithItems = dataProvider.gearCategoriesWithItems;
        return CustomScrollView(
          scrollDirection: Axis.horizontal,
          slivers: [
            SliverReorderableList(
              itemCount: gearCategoriesWithItems.length,
              itemBuilder: (context, index) {
                final (gearCategory, gearItems) =
                    gearCategoriesWithItems[index];
                return _CategoryCard(
                  index: index,
                  gearCategory: gearCategory,
                  gearItems: gearItems,
                  gearCategoryDataProvider:
                      dataProvider.gearCategoryDataProvider,
                  gearItemDataProvider: dataProvider.gearItemDataProvider,
                );
              },
              onReorder: dataProvider.gearCategoryDataProvider.reorder,
            ),
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topLeft,
                child: UnconstrainedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: FilledButton(
                      onPressed: () => _createCategory(
                        context,
                        dataProvider.gearCategoryDataProvider,
                      ),
                      child: const Text("Add Category"),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCategory(
    BuildContext context,
    GearCategoryDataProvider dataProvider,
  ) async {
    final name = await showNameDialog(context, null);
    if (name != null) {
      final gearCategory = GearCategory(
        id: GearCategoryId(0),
        name: name,
        sortIndex: 0,
      );
      final result = await dataProvider.create(gearCategory, autoId: true);
      if (result.isError && context.mounted) {
        await showMessageDialog(
          context,
          "An Error Occurred",
          result.error!.isUniqueViolation
              ? "A category with the same name already exists."
              : result.errorMessage!,
        );
      }
    }
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.index,
    required this.gearCategory,
    required this.gearItems,
    required this.gearCategoryDataProvider,
    required this.gearItemDataProvider,
  });

  final int index;
  final GearCategory gearCategory;
  final List<GearItem> gearItems;
  final GearItemDataProvider gearItemDataProvider;
  final GearCategoryDataProvider gearCategoryDataProvider;
  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(index),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HoverScrollingText(
                    gearCategory.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => _editCategory(
                    context,
                    gearCategory,
                  ),
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  onPressed: () => _deleteCategory(
                    context,
                    gearCategory,
                  ),
                  icon: const Icon(Icons.delete_rounded),
                ),
              ],
            ),
            _ItemInput(
              onAdd: (type, name, weight) => _createItem(
                context,
                gearCategory,
                type,
                name,
                weight,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: gearItems.length,
                itemBuilder: (context, index) {
                  final gearItem = gearItems[index];
                  return Row(
                    key: ValueKey(index),
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HoverScrollingText(
                              gearItem.type,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            HoverScrollingText(
                              gearItem.name,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        gearItem.weight.toString(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      IconButton(
                        onPressed: () => _editItem(
                          context,
                          gearItem,
                        ),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        onPressed: () => _deleteItem(
                          context,
                          gearItem,
                        ),
                        icon: const Icon(Icons.delete_rounded),
                      ),
                    ],
                  );
                },
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) => gearItemDataProvider.reorder(
                  gearCategory.id,
                  oldIndex,
                  newIndex,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    GearCategory gearCategory,
  ) async {
    final name = await showNameDialog(context, gearCategory.name);
    if (name != null) {
      final result =
          await gearCategoryDataProvider.update(gearCategory..name = name);
      if (result.isError && context.mounted) {
        await showMessageDialog(
          context,
          "An Error Occurred",
          result.error!.isUniqueViolation
              ? "A category with the same name already exists."
              : result.errorMessage!,
        );
      }
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    GearCategory gearCategory,
  ) async {
    final delete = await showDeleteWarningDialog(
      context,
      gearCategory.name,
      "All Gear Items of '${gearCategory.name}' will be deleted too.",
    );
    if (delete) {
      await gearCategoryDataProvider.delete(gearCategory);
    }
  }

  Future<void> _createItem(
    BuildContext context,
    GearCategory gearCategory,
    String type,
    String name,
    int weight,
  ) async {
    final gearItem = GearItem(
      id: GearItemId(0),
      gearCategoryId: gearCategory.id,
      name: name,
      type: type,
      weight: weight,
      sortIndex: 0,
    );
    final result = await gearItemDataProvider.create(gearItem, autoId: true);
    if (result.isError && context.mounted) {
      await showMessageDialog(
        context,
        "An Error Occurred",
        result.error!.isUniqueViolation
            ? "An item with the same name already exists."
            : result.errorMessage!,
      );
    }
  }

  Future<void> _editItem(BuildContext context, GearItem gearItem) async {
    final typeNameWeight = await showTypeNameWeightDialog(
      context,
      gearItem.type,
      gearItem.name,
      gearItem.weight,
    );
    if (typeNameWeight != null) {
      final (type, name, weight) = typeNameWeight;
      final result = await gearItemDataProvider.update(
        gearItem
          ..type = type
          ..name = name
          ..weight = weight,
      );
      if (result.isError && context.mounted) {
        await showMessageDialog(
          context,
          "An Error Occurred",
          result.error!.isUniqueViolation
              ? "An item with the same name already exists."
              : result.errorMessage!,
        );
      }
    }
  }

  Future<void> _deleteItem(BuildContext context, GearItem gearItem) async {
    final delete = await showDeleteWarningDialog(context, gearItem.name, null);
    if (delete) {
      await gearItemDataProvider.delete(gearItem);
    }
  }
}

class _ItemInput extends StatefulWidget {
  const _ItemInput({required this.onAdd});

  final void Function(String, String, int) onAdd;

  @override
  State<_ItemInput> createState() => _ItemInputState();
}

class _ItemInputState extends State<_ItemInput> {
  final _formKey = GlobalKey<FormState>();

  final typeFocus = FocusNode();
  String _type = "";
  String _name = "";
  int _weight = 0;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              focusNode: typeFocus,
              decoration: const InputDecoration(labelText: "Type"),
              onChanged: (type) => setState(() => _type = type),
              validator: (type) =>
                  type == null || type.isEmpty ? 'please enter a type' : null,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: TextFormField(
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (name) => setState(() => _name = name),
              validator: (name) =>
                  name == null || name.isEmpty ? 'please enter a name' : null,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(labelText: "Weight"),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final weight = int.tryParse(value);
                if (weight != null) {
                  setState(() => _weight = weight);
                }
              },
              validator: (weight) => weight == null || weight.isEmpty
                  ? 'please enter a weight'
                  : int.tryParse(weight) == null
                      ? "not a valid weight"
                      : null,
            ),
          ),
          IconButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                widget.onAdd(_type, _name, _weight);
              }
              _formKey.currentState?.reset();
              typeFocus.requestFocus();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
