import 'package:flutter/material.dart';
import 'package:gear_list_planner/bool_toggle.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/model.dart';
import 'package:provider/provider.dart';

class GearListCompareLoadWrapper extends StatelessWidget {
  const GearListCompareLoadWrapper({
    super.key,
    required this.gearListIds,
  });

  final (GearListId, GearListId) gearListIds;

  @override
  Widget build(BuildContext context) {
    return Consumer<GearListCompareDataProvider>(
      builder: (context, dataProvider, _) {
        final gearItemsForLists = dataProvider.gearItemsForList(gearListIds);
        return gearItemsForLists == null
            ? const Center(child: CircularProgressIndicator())
            : _GearListCompare(
                dataProvider: dataProvider,
                gearLists: gearItemsForLists.$1,
                categoriesWithItems: gearItemsForLists.$2,
              );
      },
    );
  }
}

class _GearListCompare extends StatelessWidget {
  const _GearListCompare({
    required this.dataProvider,
    required this.gearLists,
    required this.categoriesWithItems,
  });

  final GearListCompareDataProvider dataProvider;
  final (GearList, GearList) gearLists;
  final List<(GearCategory, List<((GearListItem?, GearListItem?), GearItem)>)>
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
                return Card(
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          gearCategory.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: gearListItemsAndItems.length,
                            itemBuilder: (context, index) {
                              final gearListItemsAndItem =
                                  gearListItemsAndItems[index];
                              final (gearListItem, gearItem) =
                                  gearListItemsAndItem;
                              return Row(
                                key: ValueKey(index),
                                children: [
                                  Text(
                                    "${gearListItem.$1?.count ?? 0} - ${gearListItem.$2?.count ?? 0}",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gearItem.type,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      Text(gearItem.name),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    "${(gearListItemsAndItem.weight1 / 1000).toStringAsFixed(3)} - ${(gearListItemsAndItem.weight2 / 1000).toStringAsFixed(3)}",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            "${(gearListItemsAndItems.weight1 / 1000).toStringAsFixed(3)} - ${(gearListItemsAndItems.weight2 / 1000).toStringAsFixed(3)} kg",
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Total: ${(categoriesWithItems.weight1 / 1000).toStringAsFixed(3)} - ${(categoriesWithItems.weight2 / 1000).toStringAsFixed(3)} kg",
                      style: Theme.of(context).textTheme.titleLarge,
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
