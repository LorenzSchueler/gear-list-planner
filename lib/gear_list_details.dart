import 'package:flutter/material.dart';
import 'package:gear_list_planner/bool_toggle.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/dialog.dart';
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
  final List<(GearCategory, List<(GearListItem, GearItem)>)>
      categoriesWithItems;

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
                final (gearCategory, gearListItemsAndItems) =
                    categoriesWithItems[index];
                final filteredGearListItemsAndItems = unpackedOnly.isOn
                    ? gearListItemsAndItems
                        .where(
                          (gearListItemsAndItem) =>
                              !gearListItemsAndItem.$1.packed,
                        )
                        .toList()
                    : gearListItemsAndItems;
                return Card(
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          gearCategory.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!gearList.readOnly) ...[
                          _ListItemInput(
                            onAdd: (gearItemId) async {
                              final gearListItem = GearListItem(
                                id: GearListItemId(0),
                                gearItemId: gearItemId,
                                gearListId: gearList.id,
                                count: 1,
                                packed: false,
                              );
                              final result = await dataProvider
                                  .gearListItemDataProvider
                                  .create(gearListItem, autoId: true);
                              if (result.isError && context.mounted) {
                                await showMessageDialog(
                                  context,
                                  "An Error Occurred",
                                  result.error!.isUniqueViolation
                                      ? "This item is already in this list."
                                      : result.errorMessage!,
                                );
                              }
                            },
                            gearItems:
                                dataProvider.gearItems[gearCategory.id] ?? [],
                          ),
                          const SizedBox(height: 10),
                        ],
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredGearListItemsAndItems.length,
                            itemBuilder: (context, index) {
                              final gearListItemsAndItem =
                                  filteredGearListItemsAndItems[index];
                              final (gearListItem, gearItem) =
                                  gearListItemsAndItem;
                              return Row(
                                key: ValueKey(index),
                                children: [
                                  Checkbox(
                                    value: gearListItem.packed,
                                    onChanged: gearList.readOnly
                                        ? null
                                        : (packed) async {
                                            if (packed != null) {
                                              final result = await dataProvider
                                                  .gearListItemDataProvider
                                                  .update(
                                                gearListItem..packed = packed,
                                              );
                                              if (result.isError &&
                                                  context.mounted) {
                                                await showMessageDialog(
                                                  context,
                                                  "An Error Occurred",
                                                  result.errorMessage!,
                                                );
                                              }
                                            }
                                          },
                                  ),
                                  IconButton(
                                    onPressed: gearList.readOnly ||
                                            gearListItem.count <= 1
                                        ? null
                                        : () async {
                                            final result = await dataProvider
                                                .gearListItemDataProvider
                                                .update(
                                              gearListItem..count -= 1,
                                            );
                                            if (result.isError &&
                                                context.mounted) {
                                              await showMessageDialog(
                                                context,
                                                "An Error Occurred",
                                                result.errorMessage!,
                                              );
                                            }
                                          },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text(
                                    gearListItem.count.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  IconButton(
                                    onPressed: gearList.readOnly
                                        ? null
                                        : () async {
                                            final result = await dataProvider
                                                .gearListItemDataProvider
                                                .update(
                                              gearListItem..count += 1,
                                            );
                                            if (result.isError &&
                                                context.mounted) {
                                              await showMessageDialog(
                                                context,
                                                "An Error Occurred",
                                                result.errorMessage!,
                                              );
                                            }
                                          },
                                    icon: const Icon(Icons.add),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gearItem.type,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          gearItem.name,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    (gearListItemsAndItem.weight / 1000)
                                        .toStringAsFixed(3),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  IconButton(
                                    onPressed: gearList.readOnly
                                        ? null
                                        : () => dataProvider
                                            .gearListItemDataProvider
                                            .delete(gearListItem),
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
                            "${(gearListItemsAndItems.weight / 1000).toStringAsFixed(3)} kg",
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            onChanged: (readOnly) async {
                              if (readOnly != null) {
                                final result = await dataProvider
                                    .gearListDataProvider
                                    .update(
                                  gearList..readOnly = readOnly,
                                );
                                if (result.isError && context.mounted) {
                                  await showMessageDialog(
                                    context,
                                    "An Error Occurred",
                                    result.errorMessage!,
                                  );
                                }
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
                          onPressed: () async {
                            final mark = await showWarningDialog(
                              context,
                              "Mark All As Unpacked?",
                              null,
                              "Set As Unpacked",
                            );
                            if (mark) {
                              await dataProvider.gearListItemDataProvider
                                  .updateMultiple(
                                categoriesWithItems.listItems
                                    .map((e) => e..packed = false)
                                    .toList(),
                              );
                            }
                          },
                          child: const Text("Mark All As Unpacked"),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: TextFormField(
                            initialValue: gearList.notes,
                            onChanged: (value) {
                              dataProvider.gearListDataProvider
                                  .update(gearList..notes = value);
                            },
                            maxLines: null,
                            decoration: const InputDecoration.collapsed(
                              hintText: "Notes",
                            ),
                            enabled: !gearList.readOnly,
                          ),
                        ),
                      ),
                      Text(
                        "Total: ${(categoriesWithItems.weight / 1000).toStringAsFixed(3)} kg",
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
            dropdownMenuEntries: widget.gearItems
                .map(
                  (i) => DropdownMenuEntry(
                    // TODO user labelWidget when implemented
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
