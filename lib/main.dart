// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/database.dart';
import 'package:gear_list_planner/dialog.dart';
import 'package:gear_list_planner/gear_item_overview.dart';
import 'package:gear_list_planner/gear_list_compare.dart';
import 'package:gear_list_planner/gear_list_details.dart';
import 'package:gear_list_planner/gear_list_overview.dart';
import 'package:gear_list_planner/model.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

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
    html.window.onBeforeUnload.listen((event) {
      if (event is html.BeforeUnloadEvent) {
        event
          ..preventDefault()
          ..returnValue = "do not close";
      }
    });
    setState(() => _progress = 0.1);
    databaseFactory = databaseFactoryFfiWeb;
    await AppDatabase.init();
    setState(() => _progress = null);
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gear List Planner',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)
            .copyWith(errorContainer: Colors.green),
        cardTheme: const CardTheme(margin: EdgeInsets.all(10)),
      ),
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

enum Tab { listOverview, itemOverview, listDetails, listCompare }

class _AppState extends State<App> with TickerProviderStateMixin {
  Tab _navigationTab = Tab.listOverview;

  bool get showDetails => _gearList != null;
  bool get showCompare => _gearListCompare.$2 != null;

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
      _navigationTab =
          gearListCompare.$2 != null ? Tab.listCompare : Tab.listOverview;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        title: Row(
          children: [
            Text(
              "Gear List Planner",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () async {
                final result = await ModelDataProvider().loadModel();
                if (result.isError && mounted) {
                  await showMessageDialog(
                    context,
                    "Invalid Data",
                    result.errorMessage!,
                  );
                }
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text("Open"),
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
            onDestinationSelected: (index) => setState(
              () => _navigationTab = Tab.values[index],
            ),
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
                label: showDetails ? _gearList!.name : "Details",
                icon: const Icon(Icons.check_box_rounded),
              ),
              NavigationDestination(
                label: showCompare
                    ? "${_gearListCompare.$1!.name} - ${_gearListCompare.$2!.name}"
                    : "Compare",
                icon: const Icon(Icons.compare_rounded),
              ),
            ],
          ),
        ),
      ),
      body: switch (_navigationTab) {
        Tab.listOverview => GearListOverview(
            onSelectGearList: _setGearList,
            onToggleCompareGearList: _toggleCompareGearList,
            selectedCompare: _gearListCompare,
          ),
        Tab.itemOverview => const GearItemOverview(),
        Tab.listDetails => showDetails
            ? GearListDetailsLoadWrapper(
                gearListId: _gearList!.id,
              )
            : const Center(
                child: Text(
                  "No list selected. Select a list in the list overview.",
                ),
              ),
        Tab.listCompare => showCompare
            ? GearListCompareLoadWrapper(
                gearListIds: (_gearListCompare.$1!.id, _gearListCompare.$2!.id),
              )
            : const Center(
                child: Text(
                  "No lists selected for comparison. Select two lists in the list overview.",
                ),
              ),
      },
    );
  }
}
