import 'package:flutter/material.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/model.dart';
import 'package:gear_list_planner/result.dart';
import 'package:provider/provider.dart';

class GearListOverview extends StatelessWidget {
  const GearListOverview({
    super.key,
    required this.onSelectGearList,
    required this.onToggleCompareGearList,
    required this.selectedCompare,
  });

  final void Function(GearList) onSelectGearList;
  final void Function(GearList) onToggleCompareGearList;
  final (GearList?, GearList?) selectedCompare;

  @override
  Widget build(BuildContext context) {
    return Consumer<GearListOverviewDataProvider>(
      builder: (context, dataProvider, _) => Card(
        child: SizedBox(
          width: 300,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final newList = await showCloneDialog(
                      context,
                      dataProvider.gearLists,
                    );
                    if (newList != null) {
                      final (name, cloneListId) = newList;
                      final Result<void> result;
                      if (cloneListId != null) {
                        result =
                            await dataProvider.gearListDataProvider.cloneList(
                          name,
                          cloneListId,
                        );
                      } else {
                        result = await dataProvider.gearListDataProvider.create(
                          GearList(
                            id: GearListId(0),
                            name: name,
                            notes: "",
                            readOnly: false,
                          ),
                          autoId: true,
                        );
                      }
                      if (result.isError && context.mounted) {
                        await showMessageDialog(
                          context,
                          "An Error Occurred",
                          result.error!.isUniqueViolation
                              ? "A list with the same name already exists."
                              : result.errorMessage!,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Add List"),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: dataProvider.gearLists.length,
                    itemBuilder: (context, index) {
                      final gearList = dataProvider.gearLists[index];
                      return Row(
                        children: [
                          Text(
                            gearList.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => onSelectGearList(
                              gearList,
                            ),
                            icon: const Icon(Icons.open_in_new),
                          ),
                          IconButton(
                            onPressed: () async {
                              final name = await showNameDialog(
                                context,
                                gearList.name,
                              );
                              if (name != null) {
                                final result = await dataProvider
                                    .gearListDataProvider
                                    .update(gearList..name = name);
                                if (result.isError && context.mounted) {
                                  await showMessageDialog(
                                    context,
                                    "An Error Occurred",
                                    result.error!.isUniqueViolation
                                        ? "A list with the same name already exists."
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
                                gearList.name,
                                null,
                              );
                              if (delete) {
                                await dataProvider.gearListDataProvider
                                    .delete(gearList);
                              }
                            },
                            icon: const Icon(Icons.delete_rounded),
                          ),
                          IconButton(
                            onPressed: () => onToggleCompareGearList(
                              gearList,
                            ),
                            icon: Icon(
                              gearList == selectedCompare.$1 ||
                                      gearList == selectedCompare.$2
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.compare_rounded,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
