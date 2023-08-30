import 'package:flutter/material.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/model.dart';
import 'package:gear_list_planner/result.dart';
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
                    final newVersion = await showCloneVersionDialog(
                      context,
                      dataProvider.gearListVersions,
                    );
                    if (newVersion != null) {
                      final (name, cloneVersionId) = newVersion;
                      final Result<void> result;
                      if (cloneVersionId != null) {
                        result = await dataProvider.gearListVersionDataProvider
                            .cloneVersion(
                          name,
                          cloneVersionId,
                        );
                      } else {
                        result = await dataProvider.gearListVersionDataProvider
                            .create(
                          GearListVersion(
                            id: GearListVersionId(0),
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
                              ? "A version with the same name already exists."
                              : result.errorMessage!,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Add Version"),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: dataProvider.gearListVersions.length,
                    itemBuilder: (context, index) {
                      final gearListVersion =
                          dataProvider.gearListVersions[index];
                      return Row(
                        children: [
                          Text(
                            gearListVersion.name,
                            style: Theme.of(context).textTheme.bodyLarge,
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
                              final delete = await showDeleteWarningDialog(
                                context,
                                gearListVersion.name,
                                null,
                              );
                              if (delete) {
                                await dataProvider.gearListVersionDataProvider
                                    .delete(gearListVersion);
                              }
                            },
                            icon: const Icon(Icons.delete_rounded),
                          ),
                          IconButton(
                            onPressed: () => onToggleCompareGearListVersion(
                              gearListVersion,
                            ),
                            icon: Icon(
                              gearListVersion == selectedCompare.$1 ||
                                      gearListVersion == selectedCompare.$2
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
