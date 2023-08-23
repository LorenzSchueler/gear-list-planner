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
          SliverList.builder(
            itemCount: dataProvider.gearCategoriesWithItems.length,
            itemBuilder: (context, index) {
              final (gearCategory, gearItems) =
                  dataProvider.gearCategoriesWithItems[index];
              return Card(
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            gearCategory.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              final name = await showNameDialog(
                                context,
                                gearCategory.name,
                              );
                              if (name != null) {
                                await dataProvider.gearCategoryDataProvider
                                    .update(gearCategory..name = name);
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
                        onAdd: (name, weight) {
                          dataProvider.gearItemDataProvider.create(
                            GearItem(
                              id: GearItemId(0),
                              gearCategoryId: gearCategory.id,
                              name: name,
                              weight: weight,
                              sortIndex: 0,
                            ),
                            autoId: true,
                            autoSortIndex: true,
                          );
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
                                Text(
                                  gearItem.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                Text(
                                  gearItem.weight.toString(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final x = await showNameWeightDialog(
                                      context,
                                      gearItem.name,
                                      gearItem.weight,
                                    );
                                    if (x != null) {
                                      final (name, weight) = x;
                                      await dataProvider.gearItemDataProvider
                                          .update(
                                        gearItem
                                          ..name = name
                                          ..weight = weight,
                                      );
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
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topLeft,
              child: UnconstrainedBox(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: FilledButton(
                    onPressed: () async {
                      final name = await showNameDialog(context, null);
                      if (name != null) {
                        final gearCategory =
                            GearCategory(id: GearCategoryId(0), name: name);
                        await dataProvider.gearCategoryDataProvider
                            .create(gearCategory, autoId: true);
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

  final void Function(String, int) onAdd;

  @override
  State<_ItemInput> createState() => _ItemInputState();
}

class _ItemInputState extends State<_ItemInput> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final weightController = TextEditingController();
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
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (name) => setState(() => _name = name),
              validator: (name) {
                if (name == null || name.isEmpty) {
                  return 'please enter a name';
                }
                return null;
              },
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
              validator: (weight) {
                if (weight == null || weight.isEmpty) {
                  return 'please enter a weight';
                } else if (int.tryParse(weight) == null) {
                  return "not a valid weight";
                }
                return null;
              },
            ),
          ),
          IconButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                widget.onAdd(_name, _weight);
                nameController.text = "";
                weightController.text = "";
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
