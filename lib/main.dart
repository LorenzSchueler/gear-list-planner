import 'package:flutter/material.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/database.dart' hide Column;
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/gear_item_overview.dart';
import 'package:gear_list_planner/gear_list_compare.dart';
import 'package:gear_list_planner/gear_list_details.dart';
import 'package:gear_list_planner/gear_list_overview.dart';
import 'package:gear_list_planner/init/initializer.dart';
import 'package:gear_list_planner/model.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const InitAppWrapper());
}

class InitAppWrapper extends StatefulWidget {
  const InitAppWrapper({super.key});

  @override
  State<InitAppWrapper> createState() => _InitAppWrapperState();
}

class _InitAppWrapperState extends State<InitAppWrapper> {
  double? _progress = 0;

  Future<void> initialize() async {
    initializer.enableWarnOnClose();
    setState(() => _progress = 0.1);
    initializer.setSqfliteFactory();
    await AppDatabase.init();
    setState(() => _progress = null);
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  static const _surface = Color.fromARGB(255, 220, 220, 220);
  final ThemeData _theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      errorContainer: Colors.green,
    ),
    appBarTheme: const AppBarTheme(color: _surface),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surface,
      selectedItemColor: Colors.black,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.white,
    ),
    cardTheme: const CardThemeData(
      margin: EdgeInsets.all(10),
      color: _surface,
      surfaceTintColor: Colors.transparent,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gear List Planner",
      theme: _theme,
      home: _progress != null
          ? Center(child: LinearProgressIndicator(value: _progress))
          : ChangeNotifierProvider(
              create: (_) => GearListOverviewDataProvider(),
              child: ChangeNotifierProvider(
                create: (_) => GearItemOverviewDataProvider(),
                child: ChangeNotifierProvider(
                  create: (_) => GearListDetailsDataProvider(),
                  child: ChangeNotifierProvider(
                    create: (_) => GearListCompareDataProvider(),
                    child: const App(),
                  ),
                ),
              ),
            ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

enum Tab { listOverview, itemOverview, listDetails, listCompare, openSave }

bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;

class _AppState extends State<App> with TickerProviderStateMixin {
  late Tab _navigationTab = mobile ? Tab.openSave : Tab.listOverview;

  bool get mobile => isMobile(context);

  bool get detailsChosen => _gearList != null;
  bool get compareChosen => _gearListCompare.$2 != null;

  GearList? _gearList;
  void _setGearList(GearList? gearList) {
    setState(() {
      _gearList = gearList;
      _navigationTab = gearList != null ? Tab.listDetails : Tab.listOverview;
    });
  }

  (GearList?, GearList?) _gearListCompare = (null, null);
  (GearList?, GearList?) get gearListCompare => _gearListCompare;
  void _toggleCompareGearList(GearList gearList) {
    final (GearList?, GearList?) gearListCompare;
    if (gearList == _gearListCompare.$2) {
      gearListCompare = (_gearListCompare.$1, null);
    } else if (gearList == _gearListCompare.$1) {
      gearListCompare = (_gearListCompare.$2, null);
    } else if (_gearListCompare.$1 == null) {
      gearListCompare = (gearList, null);
    } else {
      gearListCompare = (_gearListCompare.$1, gearList);
    }
    setState(() {
      _gearListCompare = gearListCompare;
      _navigationTab = gearListCompare.$2 != null
          ? Tab.listCompare
          : Tab.listOverview;
    });
  }

  bool _isOpening = false;

  Future<void> _openFile() async {
    final dataProvider = ModelDataProvider();
    final empty = await dataProvider.isEmpty();
    final open =
        empty ||
        mounted &&
            await showWarningDialog(
              context,
              "Open File?",
              "By opening another file all current data will be lost unless you saved it before.",
              "Open",
            );
    if (open) {
      setState(() {
        _isOpening = true;
        _navigationTab = Tab.listOverview;
        _gearList = null;
        _gearListCompare = (null, null);
      });
      final result = await dataProvider.loadModel();
      if (result.isError && mounted) {
        await showMessageDialog(context, "Invalid Data", result.errorMessage!);
      }
      setState(() => _isOpening = false);
    }
  }

  Future<void> _clearDb() async {
    final clear = await showWarningDialog(
      context,
      "Clear All Data?",
      "All data will be lost unless you saved it before.",
      "Clear",
    );
    if (clear) {
      setState(() {
        _navigationTab = Tab.listOverview;
        _gearList = null;
        _gearListCompare = (null, null);
      });
      await ModelDataProvider().clearDatabase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mobile
          ? null
          : AppBar(
              title: Row(
                children: [
                  Text(
                    "Gear List Planner",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _openFile,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text("Open"),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _clearDb,
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text("Clear"),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => ModelDataProvider().storeModel(),
                    icon: const Icon(Icons.file_download_rounded),
                    label: const Text("Save"),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size(double.infinity, 65),
                child: NavigationBar(
                  selectedIndex: _navigationTab.index,
                  onDestinationSelected: (index) =>
                      setState(() => _navigationTab = Tab.values[index]),
                  destinations: <Widget>[
                    const NavigationDestination(
                      label: "Lists",
                      icon: Icon(Icons.list_alt_rounded),
                    ),
                    const NavigationDestination(
                      label: "Items",
                      icon: Icon(Icons.business_center_rounded),
                    ),
                    NavigationDestination(
                      label: detailsChosen ? _gearList!.name : "Details",
                      icon: const Icon(Icons.check_box_rounded),
                    ),
                    NavigationDestination(
                      label: compareChosen
                          ? "${_gearListCompare.$1!.name} - ${_gearListCompare.$2!.name}"
                          : "Compare",
                      icon: const Icon(Icons.compare_rounded),
                    ),
                  ],
                ),
              ),
            ),
      body: _isOpening
          ? const Center(child: CircularProgressIndicator())
          : switch (_navigationTab) {
              Tab.listOverview => GearListOverview(
                onSelectGearList: _setGearList,
                onToggleCompareGearList: _toggleCompareGearList,
                selectedCompare: _gearListCompare,
              ),
              Tab.itemOverview => const GearItemOverview(),
              Tab.listDetails =>
                detailsChosen
                    ? GearListDetailsLoadWrapper(gearListId: _gearList!.id)
                    : Center(
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "Select a list in the list overview by clicking on ",
                              ),
                              WidgetSpan(
                                child: Icon(Icons.open_in_new, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
              Tab.listCompare =>
                compareChosen
                    ? GearListCompareLoadWrapper(
                        gearListIds: (
                          _gearListCompare.$1!.id,
                          _gearListCompare.$2!.id,
                        ),
                      )
                    : Center(
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "Select two lists for comparison in the list overview by clicking on ",
                              ),
                              WidgetSpan(
                                child: Icon(Icons.compare_rounded, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
              Tab.openSave => Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _openFile,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text("Open"),
                    ),
                    FilledButton.icon(
                      onPressed: _clearDb,
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text("Clear"),
                    ),
                    FilledButton.icon(
                      onPressed: () => ModelDataProvider().storeModel(),
                      icon: const Icon(Icons.file_download_rounded),
                      label: const Text("Save"),
                    ),
                  ],
                ),
              ),
            },
      floatingActionButton: mobile
          ? switch (_navigationTab) {
              Tab.listOverview => GearListOverview.fab(context),
              Tab.itemOverview => GearItemOverview.fab(context),
              Tab.listDetails => null,
              Tab.listCompare => null,
              Tab.openSave => null,
            }
          : null,
      bottomNavigationBar: mobile
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _navigationTab.index,
              onTap: (index) =>
                  setState(() => _navigationTab = Tab.values[index]),
              items: [
                const BottomNavigationBarItem(
                  label: "Lists",
                  icon: Icon(Icons.list_alt_rounded),
                ),
                const BottomNavigationBarItem(
                  label: "Items",
                  icon: Icon(Icons.business_center_rounded),
                ),
                BottomNavigationBarItem(
                  label: detailsChosen ? _gearList!.name : "Details",
                  icon: const Icon(Icons.check_box_rounded),
                ),
                BottomNavigationBarItem(
                  label: compareChosen
                      ? "${_gearListCompare.$1!.name} - ${_gearListCompare.$2!.name}"
                      : "Compare",
                  icon: const Icon(Icons.compare_rounded),
                ),
                const BottomNavigationBarItem(
                  label: "Open / Save",
                  icon: Icon(Icons.import_export_outlined),
                ),
              ],
            )
          : null,
    );
  }
}
