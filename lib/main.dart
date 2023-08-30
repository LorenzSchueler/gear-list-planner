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

class _AppState extends State<App> with TickerProviderStateMixin {
  void _updateTabController(bool addDetails) {
    final currentIndex = _tabController.index;
    final oldLength = _tabController.length;
    final length =
        2 + (_gearList != null ? 1 : 0) + (_gearListCompare.$2 != null ? 1 : 0);
    _tabController.dispose();
    _tabController = TabController(
      length: length,
      initialIndex: addDetails
          ? 2
          : oldLength == length
              ? currentIndex
              : oldLength > length
                  ? 0
                  : length - 1,
      vsync: this,
    );
  }

  GearList? _gearList;
  void _setGearList(GearList? gearList) {
    setState(() => _gearList = gearList);
    _updateTabController(true);
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
    setState(() => _gearListCompare = gearListCompare);
    _updateTabController(false);
  }

  late TabController _tabController = TabController(length: 2, vsync: this);

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
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            const Tab(
              text: "Lists",
              icon: Icon(Icons.list_alt_rounded),
            ),
            const Tab(
              text: "Items",
              icon: Icon(Icons.business_center_rounded),
            ),
            if (_gearList != null)
              Tab(
                text: _gearList!.name,
                icon: const Icon(Icons.check_box_rounded),
              ),
            if (_gearListCompare.$2 != null)
              Tab(
                text:
                    "${_gearListCompare.$1!.name} - ${_gearListCompare.$2!.name}",
                icon: const Icon(Icons.check_box_rounded),
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GearListOverview(
            onSelectGearList: _setGearList,
            onToggleCompareGearList: _toggleCompareGearList,
            selectedCompare: _gearListCompare,
          ),
          const GearItemOverview(),
          if (_gearList != null)
            GearListDetailsLoadWrapper(
              gearListId: _gearList!.id,
            ),
          if (_gearListCompare.$2 != null)
            GearListCompareLoadWrapper(
              gearListIds: (_gearListCompare.$1!.id, _gearListCompare.$2!.id),
            ),
        ],
      ),
    );
  }
}
