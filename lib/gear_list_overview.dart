import 'package:flutter/material.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/hover_scrolling_text.dart';
import 'package:gear_list_planner/main.dart';
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

  static Widget fab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _createList(context, GearListOverviewDataProvider()),
      child: const Icon(Icons.add_rounded),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GearListOverviewDataProvider>(
      builder: (context, dataProvider, _) {
        final gearLists = dataProvider.gearLists;
        return isMobile(context)
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: ListView.builder(
                  itemCount: gearLists.length,
                  itemBuilder: (context, index) {
                    final gearList = gearLists[index];
                    return ListItem(
                      gearList: gearList,
                      onSelectGearList: onSelectGearList,
                      onToggleCompareGearList: onToggleCompareGearList,
                      selectedCompare: selectedCompare,
                      dataProvider: dataProvider.gearListDataProvider,
                    );
                  },
                ),
              )
            : Card(
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      FilledButton.icon(
                        onPressed: () => _createList(
                          context,
                          dataProvider,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("Add List"),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: gearLists.length,
                          itemBuilder: (context, index) {
                            final gearList = gearLists[index];
                            return ListItem(
                              gearList: gearList,
                              onSelectGearList: onSelectGearList,
                              onToggleCompareGearList: onToggleCompareGearList,
                              selectedCompare: selectedCompare,
                              dataProvider: dataProvider.gearListDataProvider,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
      },
    );
  }

  static Future<void> _createList(
    BuildContext context,
    GearListOverviewDataProvider dataProvider,
  ) async {
    final newList = await showCloneDialog(context, dataProvider.gearLists);
    if (newList != null) {
      final (name, cloneListId) = newList;
      final Result<void> result;
      if (cloneListId != null) {
        result = await dataProvider.gearListDataProvider
            .cloneList(name, cloneListId);
      } else {
        final gearList = GearList(
          id: GearListId(0),
          name: name,
          notes: "",
          readOnly: false,
        );
        result = await dataProvider.gearListDataProvider
            .create(gearList, autoId: true);
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
  }
}

class ListItem extends StatelessWidget {
  const ListItem({
    super.key,
    required this.gearList,
    required this.onSelectGearList,
    required this.onToggleCompareGearList,
    required this.selectedCompare,
    required this.dataProvider,
  });

  final GearList gearList;
  final void Function(GearList p1) onSelectGearList;
  final void Function(GearList p1) onToggleCompareGearList;
  final (GearList?, GearList?) selectedCompare;
  final GearListDataProvider dataProvider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: HoverScrollingText(
            gearList.name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        IconButton(
          onPressed: () => onSelectGearList(gearList),
          icon: const Icon(Icons.open_in_new),
        ),
        IconButton(
          onPressed: () => _editList(
            context,
            gearList,
          ),
          icon: const Icon(Icons.edit_rounded),
        ),
        IconButton(
          onPressed: () => _deleteList(
            context,
            gearList,
          ),
          icon: const Icon(Icons.delete_rounded),
        ),
        IconButton(
          onPressed: () => onToggleCompareGearList(gearList),
          icon: Icon(
            gearList == selectedCompare.$1 || gearList == selectedCompare.$2
                ? Icons.check_circle_outline_rounded
                : Icons.compare_rounded,
          ),
        ),
      ],
    );
  }

  Future<void> _editList(BuildContext context, GearList gearList) async {
    final name = await showNameDialog(context, gearList.name);
    if (name != null) {
      final result = await dataProvider.update(gearList..name = name);
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
  }

  Future<void> _deleteList(BuildContext context, GearList gearList) async {
    final delete = await showDeleteWarningDialog(context, gearList.name, null);
    if (delete) {
      await dataProvider.delete(gearList);
    }
  }
}
