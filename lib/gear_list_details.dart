import 'package:flutter/material.dart';
import 'package:gear_list_planner/bool_toggle.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/hover_scrolling_text.dart';
import 'package:gear_list_planner/model.dart';
import 'package:provider/provider.dart';

class GearListDetailsLoadWrapper extends StatelessWidget {
  const GearListDetailsLoadWrapper({
    super.key,
    required this.gearListId,
  });

  final GearListId gearListId;

  @override
  Widget build(BuildContext context) {
    return Consumer<GearListDetailsDataProvider>(
      builder: (context, dataProvider, _) {
        final gearItemsForList = dataProvider.gearItemsForList(gearListId);
        return gearItemsForList == null
            ? const Center(child: CircularProgressIndicator())
            : _GearListDetails(
                dataProvider: dataProvider,
                gearList: gearItemsForList.$1,
                categoriesWithItems: gearItemsForList.$2,
              );
      },
    );
  }
}

class _GearListDetails extends StatelessWidget {
  const _GearListDetails({
    required this.dataProvider,
    required this.gearList,
    required this.categoriesWithItems,
  });

  final GearListDetailsDataProvider dataProvider;
  final GearList gearList;
  final List<GearCategoryWithItems> categoriesWithItems;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BoolToggle.off(),
      builder: (context, _) => Consumer<BoolToggle>(
        builder: (context, unpackedOnly, _) => CustomScrollView(
          scrollDirection: Axis.horizontal,
          slivers: [
            SliverList.builder(
              itemCount: categoriesWithItems.length,
              itemBuilder: (context, index) {
                final gearCategoryWithItems = categoriesWithItems[index];
                final gearCategory = gearCategoryWithItems.gearCategory;
                final selectedItems = gearCategoryWithItems.selectedItems;
                final nonSelectedItems = gearCategoryWithItems.nonSelectedItems;
                final filteredSelectedItems = unpackedOnly.isOn
                    ? selectedItems
                        .where(
                          (listItemsAndItem) => !listItemsAndItem.$1.packed,
                        )
                        .toList()
                    : selectedItems;
                return _CategoryCard(
                  gearList: gearList,
                  gearCategory: gearCategory,
                  nonSelectedItems: nonSelectedItems,
                  selectedItems: selectedItems,
                  filteredSelectedItems: filteredSelectedItems,
                  dataProvider: dataProvider.gearListItemDataProvider,
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: gearList.readOnly,
                            onChanged: (readOnly) {
                              if (readOnly != null) {
                                _updateList(
                                  context,
                                  gearList..readOnly = readOnly,
                                );
                              }
                            },
                          ),
                          const Text("Read Only"),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: unpackedOnly.isOn,
                            onChanged: unpackedOnly.setState,
                          ),
                          const Text("Show Unpacked Only"),
                        ],
                      ),
                      if (!gearList.readOnly)
                        FilledButton(
                          onPressed: () => _markAllAsUnpacked(context),
                          child: const Text("Mark All As Unpacked"),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: TextFormField(
                            initialValue: gearList.notes,
                            onChanged: (value) =>
                                _updateList(context, gearList..notes = value),
                            maxLines: null,
                            decoration: const InputDecoration.collapsed(
                              hintText: "Notes",
                            ),
                            enabled: !gearList.readOnly,
                          ),
                        ),
                      ),
                      Text(
                        "Total: ${categoriesWithItems.weight.inKg} kg",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateList(BuildContext context, GearList gearList) async {
    final result = await dataProvider.gearListDataProvider.update(gearList);
    if (result.isError && context.mounted) {
      await showMessageDialog(
        context,
        "An Error Occurred",
        result.errorMessage!,
      );
    }
  }

  Future<void> _markAllAsUnpacked(BuildContext context) async {
    final mark = await showWarningDialog(
      context,
      "Mark All As Unpacked?",
      null,
      "Mark As Unpacked",
    );
    if (mark) {
      await dataProvider.gearListItemDataProvider.updateMultiple(
        categoriesWithItems.listItems.map((e) => e..packed = false).toList(),
      );
    }
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.gearList,
    required this.gearCategory,
    required this.nonSelectedItems,
    required this.selectedItems,
    required this.filteredSelectedItems,
    required this.dataProvider,
  });

  final GearList gearList;
  final GearCategory gearCategory;
  final List<GearItem> nonSelectedItems;
  final List<(GearListItem, GearItem)> selectedItems;
  final List<(GearListItem, GearItem)> filteredSelectedItems;
  final GearListItemDataProvider dataProvider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            HoverScrollingText(
              gearCategory.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (!gearList.readOnly) ...[
              _ListItemInput(
                onAdd: (gearItemId) => _createListItem(context, gearItemId),
                gearItems: nonSelectedItems,
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: filteredSelectedItems.length,
                itemBuilder: (context, index) {
                  final gearListItemsAndItem = filteredSelectedItems[index];
                  final (gearListItem, gearItem) = gearListItemsAndItem;
                  return Row(
                    key: ValueKey(index),
                    children: [
                      Checkbox(
                        value: gearListItem.packed,
                        onChanged: gearList.readOnly
                            ? null
                            : (packed) {
                                if (packed != null) {
                                  _updateListItem(
                                    context,
                                    gearListItem..packed = packed,
                                  );
                                }
                              },
                      ),
                      IconButton(
                        onPressed: gearList.readOnly || gearListItem.count <= 1
                            ? null
                            : () => _updateListItem(
                                  context,
                                  gearListItem..count -= 1,
                                ),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        gearListItem.count.toString(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      IconButton(
                        onPressed: gearList.readOnly
                            ? null
                            : () => _updateListItem(
                                  context,
                                  gearListItem..count += 1,
                                ),
                        icon: const Icon(Icons.add),
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
                        gearListItemsAndItem.weight.inKg,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      IconButton(
                        onPressed: gearList.readOnly
                            ? null
                            : () => dataProvider.delete(gearListItem),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Text(
                "${selectedItems.weight.inKg} kg",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createListItem(
    BuildContext context,
    GearItemId gearItemId,
  ) async {
    final gearListItem = GearListItem(
      id: GearListItemId(0),
      gearItemId: gearItemId,
      gearListId: gearList.id,
      count: 1,
      packed: false,
    );
    final result = await dataProvider.create(gearListItem, autoId: true);
    if (result.isError && context.mounted) {
      await showMessageDialog(
        context,
        "An Error Occurred",
        result.error!.isUniqueViolation
            ? "This item is already in this list."
            : result.errorMessage!,
      );
    }
  }

  Future<void> _updateListItem(
    BuildContext context,
    GearListItem gearListItem,
  ) async {
    final result = await dataProvider.update(gearListItem);
    if (result.isError && context.mounted) {
      await showMessageDialog(
        context,
        "An Error Occurred",
        result.errorMessage!,
      );
    }
  }
}

class _ListItemInput extends StatefulWidget {
  const _ListItemInput({required this.onAdd, required this.gearItems});

  final void Function(GearItemId) onAdd;
  final List<GearItem> gearItems;

  @override
  State<_ListItemInput> createState() => _ListItemInputState();
}

class _ListItemInputState extends State<_ListItemInput> {
  GearItemId? _gearItemId;

  final focusNode = FocusNode();
  final dropdownTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TODO workaround because DropdownMenu has no FocusNode
        SizedBox(
          width: 1,
          child: TextFormField(focusNode: focusNode),
        ),
        Expanded(
          child: DropdownMenu(
            controller: dropdownTextController,
            dropdownMenuEntries: widget.gearItems
                .map(
                  (i) => DropdownMenuEntry(
                    // TODO user labelWidget: HoverScrollingText when implemented
                    value: i,
                    label: "${i.type} - ${i.name}",
                  ),
                )
                .toList(),
            inputDecorationTheme:
                const InputDecorationTheme(contentPadding: EdgeInsets.zero),
            enableFilter: true,
            label: const Text("Name"),
            onSelected: (gearItem) {
              if (gearItem != null) {
                setState(() => _gearItemId = gearItem.id);
              }
            },
          ),
        ),
        IconButton(
          onPressed: () {
            if (_gearItemId != null) {
              widget.onAdd(_gearItemId!);
            }
            dropdownTextController.text = "";
            focusNode
              ..requestFocus()
              ..nextFocus(); // TODO workaround because DropdownMenu has no FocusNode
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
