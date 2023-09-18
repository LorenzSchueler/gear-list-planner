import 'package:flutter/material.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/model.dart';
import 'package:provider/provider.dart';

class GearItemOverview extends StatelessWidget {
  const GearItemOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GearItemOverviewDataProvider>(
      builder: (context, dataProvider, _) => CustomScrollView(
        scrollDirection: Axis.horizontal,
        slivers: [
          SliverReorderableList(
            itemCount: dataProvider.gearCategoriesWithItems.length,
            itemBuilder: (context, index) {
              final (gearCategory, gearItems) =
                  dataProvider.gearCategoriesWithItems[index];
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
                          Text(
                            gearCategory.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              final name = await showNameDialog(
                                context,
                                gearCategory.name,
                              );
                              if (name != null) {
                                final result = await dataProvider
                                    .gearCategoryDataProvider
                                    .update(gearCategory..name = name);
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
                            },
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            onPressed: () async {
                              final delete = await showDeleteWarningDialog(
                                context,
                                gearCategory.name,
                                "All Gear Items of '${gearCategory.name}' will be deleted too.",
                              );
                              if (delete) {
                                await dataProvider.gearCategoryDataProvider
                                    .delete(gearCategory);
                              }
                            },
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ],
                      ),
                      _ItemInput(
                        onAdd: (type, name, weight) async {
                          final gearItem = GearItem(
                            id: GearItemId(0),
                            gearCategoryId: gearCategory.id,
                            name: name,
                            type: type,
                            weight: weight,
                            sortIndex: 0,
                          );
                          final result =
                              await dataProvider.gearItemDataProvider.create(
                            gearItem,
                            autoId: true,
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
                        },
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
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      gearItem.type,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    Text(gearItem.name),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  gearItem.weight.toString(),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final typeNameWeight =
                                        await showTypeNameWeightDialog(
                                      context,
                                      gearItem.type,
                                      gearItem.name,
                                      gearItem.weight,
                                    );
                                    if (typeNameWeight != null) {
                                      final (type, name, weight) =
                                          typeNameWeight;
                                      final result = await dataProvider
                                          .gearItemDataProvider
                                          .update(
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
                                  },
                                  icon: const Icon(Icons.edit_rounded),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final delete =
                                        await showDeleteWarningDialog(
                                      context,
                                      gearItem.name,
                                      null,
                                    );
                                    if (delete) {
                                      await dataProvider.gearItemDataProvider
                                          .delete(gearItem);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_rounded),
                                ),
                              ],
                            );
                          },
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) =>
                              dataProvider.reorderGearItem(
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
            },
            onReorder: dataProvider.reorderGearCategory,
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topLeft,
              child: UnconstrainedBox(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: FilledButton(
                    onPressed: () async {
                      final name = await showNameDialog(context, null);
                      if (name != null) {
                        final gearCategory = GearCategory(
                          id: GearCategoryId(0),
                          name: name,
                          sortIndex: 0,
                        );
                        final result =
                            await dataProvider.gearCategoryDataProvider.create(
                          gearCategory,
                          autoId: true,
                        );
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
                    },
                    child: const Text("Add Category"),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
  final typeController = TextEditingController();
  final nameController = TextEditingController();
  final weightController = TextEditingController();
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
            child: TextFormField(
              controller: typeController,
              focusNode: typeFocus,
              decoration: const InputDecoration(labelText: "Type"),
              onChanged: (type) => setState(() => _type = type),
              validator: (type) =>
                  type == null || type.isEmpty ? 'please enter a type' : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (name) => setState(() => _name = name),
              validator: (name) =>
                  name == null || name.isEmpty ? 'please enter a name' : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: weightController,
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
                typeController.text = "";
                nameController.text = "";
                weightController.text = "";
                typeFocus.requestFocus();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
