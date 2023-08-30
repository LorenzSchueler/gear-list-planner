import 'package:flutter/material.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/model.dart';
import 'package:provider/provider.dart';

class GearListOverview extends StatelessWidget {
  const GearListOverview({
    super.key,
    required this.onSelectGearListVersion,
    required this.onToggleCompareGearListVersion,
    required this.selectedCompare,
  });

  final void Function(GearListVersion) onSelectGearListVersion;
  final void Function(GearListVersion) onToggleCompareGearListVersion;
  final (GearListVersion?, GearListVersion?) selectedCompare;

  @override
  Widget build(BuildContext context) {
    return Consumer<GearListOverviewDataProvider>(
      builder: (context, dataProvider, _) => CustomScrollView(
        scrollDirection: Axis.horizontal,
        slivers: [
          SliverList.builder(
            itemCount: dataProvider.gearListsWithVersions.length,
            itemBuilder: (context, index) {
              final (gearList, gearListVersions) =
                  dataProvider.gearListsWithVersions[index];
              return Card(
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            gearList.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              final name =
                                  await showNameDialog(context, gearList.name);
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
                                "All Gear List Versions of '${gearList.name}' will be deleted too.",
                              );
                              if (delete) {
                                await dataProvider.gearListDataProvider
                                    .delete(gearList);
                              }
                            },
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          final newVersion = await showCloneVersionDialog(
                            context,
                            gearListVersions,
                          );
                          if (newVersion != null) {
                            final (name, cloneVersionId) = newVersion;
                            if (cloneVersionId != null) {
                              await dataProvider.gearListVersionDataProvider
                                  .cloneVersion(
                                name,
                                gearList.id,
                                cloneVersionId,
                              );
                            } else {
                              final result = await dataProvider
                                  .gearListVersionDataProvider
                                  .create(
                                GearListVersion(
                                  id: GearListVersionId(0),
                                  gearListId: gearList.id,
                                  name: name,
                                  readOnly: false,
                                ),
                                autoId: true,
                              );
                              if (result.isError && context.mounted) {
                                await showMessageDialog(
                                  context,
                                  "An Error Occurred",
                                  result.error!.isUniqueViolation
                                      ? "A version with the same name already exists."
                                      : result.errorMessage!,
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("Add Version"),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: gearListVersions.length,
                          itemBuilder: (context, index) {
                            final gearListVersion = gearListVersions[index];
                            return Row(
                              children: [
                                Text(
                                  gearListVersion.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => onSelectGearListVersion(
                                    gearListVersion,
                                  ),
                                  icon: const Icon(Icons.open_in_new),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final name = await showNameDialog(
                                      context,
                                      gearListVersion.name,
                                    );
                                    if (name != null) {
                                      final result = await dataProvider
                                          .gearListVersionDataProvider
                                          .update(gearListVersion..name = name);
                                      if (result.isError && context.mounted) {
                                        await showMessageDialog(
                                          context,
                                          "An Error Occurred",
                                          result.error!.isUniqueViolation
                                              ? "A version with the same name already exists."
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
                                      gearListVersion.name,
                                      null,
                                    );
                                    if (delete) {
                                      await dataProvider
                                          .gearListVersionDataProvider
                                          .delete(gearListVersion);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_rounded),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      onToggleCompareGearListVersion(
                                    gearListVersion,
                                  ),
                                  icon: Icon(
                                    gearListVersion == selectedCompare.$1 ||
                                            gearListVersion ==
                                                selectedCompare.$2
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
              );
            },
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
                        final gearList =
                            GearList(id: GearListId(0), name: name);
                        final result = await dataProvider.gearListDataProvider
                            .create(gearList, autoId: true);
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
                    child: const Text("Add List"),
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
