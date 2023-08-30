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
    final length = 2 +
        (_gearListVersion != null ? 1 : 0) +
        (_gearListVersionCompare.$2 != null ? 1 : 0);
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

  GearListVersion? _gearListVersion;
  void _setGearListVersion(GearListVersion? gearListVersion) {
    setState(() => _gearListVersion = gearListVersion);
    _updateTabController(true);
  }

  (GearListVersion?, GearListVersion?) _gearListVersionCompare = (null, null);
  (GearListVersion?, GearListVersion?) get gearListVersionCompare =>
      _gearListVersionCompare;
  void _toggleCompareGearListVersion(GearListVersion gearListVersion) {
    final (GearListVersion?, GearListVersion?) gearListVersionCompare;
    if (gearListVersion == _gearListVersionCompare.$2) {
      gearListVersionCompare = (_gearListVersionCompare.$1, null);
    } else if (gearListVersion == _gearListVersionCompare.$1) {
      gearListVersionCompare = (_gearListVersionCompare.$2, null);
    } else if (_gearListVersionCompare.$1 == null) {
      gearListVersionCompare = (gearListVersion, null);
    } else {
      gearListVersionCompare = (_gearListVersionCompare.$1, gearListVersion);
    }
    setState(() => _gearListVersionCompare = gearListVersionCompare);
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
            const Text("Gear List Planner"),
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
            if (_gearListVersion != null)
              Tab(
                text: _gearListVersion!.name,
                icon: const Icon(Icons.check_box_rounded),
              ),
            if (_gearListVersionCompare.$2 != null)
              Tab(
                text:
                    "${_gearListVersionCompare.$1!.name} - ${_gearListVersionCompare.$2!.name}",
                icon: const Icon(Icons.check_box_rounded),
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GearListOverview(
            onSelectGearListVersion: _setGearListVersion,
            onToggleCompareGearListVersion: _toggleCompareGearListVersion,
            selectedCompare: _gearListVersionCompare,
          ),
          const GearItemOverview(),
          if (_gearListVersion != null)
            GearListDetailsLoadWrapper(
              gearListVersionId: _gearListVersion!.id,
            ),
          if (_gearListVersionCompare.$2 != null)
            GearListCompareLoadWrapper(
              gearListVersionIds: (
                _gearListVersionCompare.$1!.id,
                _gearListVersionCompare.$2!.id
              ),
            ),
        ],
      ),
    );
  }
}
