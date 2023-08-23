import 'package:flutter/material.dart';
import 'package:gear_list_planner/bool_toggle.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/model.dart';
import 'package:provider/provider.dart';

class GearListDetailsLoadWrapper extends StatelessWidget {
  const GearListDetailsLoadWrapper({
    super.key,
    required this.gearListVersionId,
  });

  final GearListVersionId gearListVersionId;

  @override
  Widget build(BuildContext context) {
    return Consumer<GearListDetailsDataProvider>(
      builder: (context, dataProvider, _) {
        final gearItemsForListVersion =
            dataProvider.gearItemsForListVersion(gearListVersionId);
        return gearItemsForListVersion == null
            ? const Center(child: CircularProgressIndicator())
            : _GearListDetails(
                dataProvider: dataProvider,
                gearListVersion: gearItemsForListVersion.$1,
                categoriesWithItems: gearItemsForListVersion.$2,
              );
      },
    );
  }
}

class _GearListDetails extends StatelessWidget {
  const _GearListDetails({
    required this.dataProvider,
    required this.gearListVersion,
    required this.categoriesWithItems,
  });

  final GearListDetailsDataProvider dataProvider;
  final GearListVersion gearListVersion;
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
                          gearListVersion.name,
                        ),
                        Text(
                          gearCategory.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (!gearListVersion.readOnly)
                          _ListItemInput(
                            onAdd: (gearItemId) {
                              dataProvider.gearListItemDataProvider.create(
                                GearListItem(
                                  id: GearListItemId(0),
                                  gearItemId: gearItemId,
                                  gearListVersionId: gearListVersion.id,
                                  count: 1,
                                  packed: false,
                                ),
                                autoId: true,
                              );
                            },
                            gearItems:
                                dataProvider.gearItems[gearCategory.id] ?? [],
                          ),
                        const SizedBox(height: 20),
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
                                    onChanged: gearListVersion.readOnly
                                        ? null
                                        : (packed) {
                                            if (packed != null) {
                                              dataProvider
                                                  .gearListItemDataProvider
                                                  .update(
                                                gearListItem..packed = packed,
                                              );
                                            }
                                          },
                                  ),
                                  IconButton(
                                    onPressed: gearListVersion.readOnly
                                        ? null
                                        : () => dataProvider
                                            .gearListItemDataProvider
                                            .update(gearListItem..count -= 1),
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text(
                                    gearListItem.count.toString(),
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  IconButton(
                                    onPressed: gearListVersion.readOnly
                                        ? null
                                        : () => dataProvider
                                            .gearListItemDataProvider
                                            .update(gearListItem..count += 1),
                                    icon: const Icon(Icons.add),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    gearItem.name,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const Spacer(),
                                  Text(
                                    (gearListItemsAndItem.weight / 1000)
                                        .toStringAsFixed(3),
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  IconButton(
                                    onPressed: gearListVersion.readOnly
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
                            style: Theme.of(context).textTheme.headlineMedium,
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
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: gearListVersion.readOnly,
                          onChanged: (readOnly) async {
                            if (readOnly != null) {
                              await dataProvider.gearListVersionDataProvider
                                  .update(gearListVersion..readOnly = readOnly);
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
                    if (!gearListVersion.readOnly)
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
                    const Spacer(),
                    Text(
                      "Total: ${(categoriesWithItems.weight / 1000).toStringAsFixed(3)} kg",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownMenu(
          dropdownMenuEntries: widget.gearItems
              .map(
                (i) => DropdownMenuEntry<GearItem>(value: i, label: i.name),
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
        const Spacer(),
        IconButton(
          onPressed: () {
            if (_gearItemId != null) {
              widget.onAdd(_gearItemId!);
            }
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}