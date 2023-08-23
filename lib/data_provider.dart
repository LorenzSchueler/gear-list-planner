// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' show AnchorElement;

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:gear_list_planner/database.dart';
import 'package:gear_list_planner/model.dart';

abstract class EntityDataProvider<I extends Id, E extends Entity<I>>
    extends ChangeNotifier {
  TableAccessor<I, E> get tableAccessor;

  Future<int> create(
    E object, {
    required bool autoId,
    bool notify = true,
  }) async {
    final id = await tableAccessor.create(object, autoId);
    if (notify) {
      notifyListeners();
    }
    return id;
  }

  Future<void> update(E object, {bool notify = true}) async {
    await tableAccessor.update(object);
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> updateMultiple(List<E> objects, {bool notify = true}) async {
    for (final object in objects) {
      await tableAccessor.update(object);
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> delete(E object, {bool notify = true}) async {
    await tableAccessor.delete(object);
    if (notify) {
      notifyListeners();
    }
  }

  Future<E> getById(I id) => tableAccessor.getById(id);

  Future<List<E>> getAll() => tableAccessor.getAll();
}

class GearListDataProvider extends EntityDataProvider<GearListId, GearList> {
  factory GearListDataProvider() => _instance;

  GearListDataProvider._();

  static final _instance = GearListDataProvider._();

  @override
  final tableAccessor = GearListAccessor();
}

class GearListVersionDataProvider
    extends EntityDataProvider<GearListVersionId, GearListVersion> {
  factory GearListVersionDataProvider() => _instance;

  GearListVersionDataProvider._();

  static final _instance = GearListVersionDataProvider._();

  @override
  final GearListVersionAccessor tableAccessor = GearListVersionAccessor();

  Future<List<GearListVersion>> getByGearListId(GearListId gearListId) =>
      tableAccessor.getByGearListId(gearListId);

  Future<void> cloneVersion(
    String name,
    GearListId gearListId,
    GearListVersionId cloneId,
  ) async {
    final id = await create(
      GearListVersion(
        id: GearListVersionId(0),
        gearListId: gearListId,
        name: name,
        readOnly: false,
      ),
      autoId: true,
    );
    await TableAccessor.database.execute(
      """
      insert into ${Tables.gearListItem}(${Columns.gearItemId}, ${Columns.gearListVersionId}, ${Columns.count}, ${Columns.packed}) 
      select ${Columns.gearItemId}, $id, ${Columns.count}, ${Columns.packed}
      from ${Tables.gearListItem} 
      where ${Columns.gearListVersionId} = ${cloneId.id};
      """,
    );
  }
}

class GearListItemDataProvider
    extends EntityDataProvider<GearListItemId, GearListItem> {
  factory GearListItemDataProvider() => _instance;

  GearListItemDataProvider._();

  static final _instance = GearListItemDataProvider._();

  @override
  final GearListItemAccessor tableAccessor = GearListItemAccessor();

  Future<List<(GearListItem, GearItem)>> getWithItemByVersionAndCategory(
    GearListVersionId gearListVersionId,
    GearCategoryId gearCategoryId,
  ) =>
      tableAccessor.getWithItemByVersionAndCategory(
        gearListVersionId,
        gearCategoryId,
      );
}

class GearItemDataProvider extends EntityDataProvider<GearItemId, GearItem> {
  factory GearItemDataProvider() => _instance;

  GearItemDataProvider._();

  static final _instance = GearItemDataProvider._();

  @override
  final GearItemAccessor tableAccessor = GearItemAccessor();

  @override
  Future<int> create(
    GearItem object, {
    required bool autoId,
    bool autoSortIndex = false,
    bool notify = true,
  }) async {
    final maxSortIndex =
        await tableAccessor.getMaxSortIndexForCategory(object.gearCategoryId);
    object.sortIndex = maxSortIndex + 1;
    return super.create(object, autoId: autoId, notify: notify);
  }

  Future<List<GearItem>> getByGearCategoryId(
    GearCategoryId gearCategoryId,
  ) =>
      tableAccessor.getByGearCategoryId(gearCategoryId);
}

class GearCategoryDataProvider
    extends EntityDataProvider<GearCategoryId, GearCategory> {
  factory GearCategoryDataProvider() => _instance;

  GearCategoryDataProvider._();

  static final _instance = GearCategoryDataProvider._();

  @override
  final tableAccessor = GearCategoryAccessor();
}

class ModelDataProvider extends ChangeNotifier {
  factory ModelDataProvider() {
    if (_instance == null) {
      final instance = ModelDataProvider._();
      instance._gearListDataProvider.addListener(instance.notifyListeners);
      instance._gearListVersionDataProvider
          .addListener(instance.notifyListeners);
      instance._gearListItemDataProvider.addListener(instance.notifyListeners);
      instance._gearItemDataProvider.addListener(instance.notifyListeners);
      instance._gearCategoryDataProvider.addListener(instance.notifyListeners);
      _instance = instance;
    }
    return _instance!;
  }

  ModelDataProvider._();

  static ModelDataProvider? _instance;

  final _gearListDataProvider = GearListDataProvider();
  final _gearListVersionDataProvider = GearListVersionDataProvider();
  final _gearListItemDataProvider = GearListItemDataProvider();
  final _gearItemDataProvider = GearItemDataProvider();
  final _gearCategoryDataProvider = GearCategoryDataProvider();

  Future<String?> _readFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      final bytes = result.files.single.bytes!;
      final data = String.fromCharCodes(bytes);
      return data;
    }
    return null;
  }

  Future<void> _writeFile(String data, String filename) async {
    AnchorElement()
      ..href = Uri.dataFromString(data, mimeType: "application/json").toString()
      ..style.display = "none"
      ..download = filename
      ..click();
  }

  Future<void> _createModel(GearModel model) async {
    for (final gearList in model.gearLists) {
      await _gearListDataProvider.create(
        gearList,
        autoId: false,
        notify: false,
      );
    }
    for (final gearListVersion in model.gearListVersions) {
      await _gearListVersionDataProvider.create(
        gearListVersion,
        autoId: false,
        notify: false,
      );
    }
    for (final gearCategory in model.gearCategories) {
      await _gearCategoryDataProvider.create(
        gearCategory,
        autoId: false,
        notify: false,
      );
    }
    for (final gearItem in model.gearItems) {
      await _gearItemDataProvider.create(
        gearItem,
        autoId: false,
        notify: false,
      );
    }
    for (final gearListItem in model.gearListItems) {
      await _gearListItemDataProvider.create(
        gearListItem,
        autoId: false,
        notify: false,
      );
    }
    notifyListeners();
  }

  Future<void> loadModel() async {
    await AppDatabase.clearDatabase();
    final data = await _readFile();
    if (data == null) {
      return;
    }

    final model = GearModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
    await _createModel(model);
    notifyListeners();
  }

  Future<void> storeModel() async {
    final model = GearModel(
      gearLists: await _gearListDataProvider.getAll(),
      gearListVersions: await _gearListVersionDataProvider.getAll(),
      gearListItems: await _gearListItemDataProvider.getAll(),
      gearItems: await _gearItemDataProvider.getAll(),
      gearCategories: await _gearCategoryDataProvider.getAll(),
    );
    final data = jsonEncode(model.toJson());
    await _writeFile(data, "gear_list.json");
  }
}

class GearListOverviewDataProvider extends ChangeNotifier {
  factory GearListOverviewDataProvider() {
    if (_instance == null) {
      final instance = GearListOverviewDataProvider._();
      instance._dataProvider.addListener(instance._onUpdate);
      instance._onUpdate();
      _instance = instance;
    }
    return _instance!;
  }

  GearListOverviewDataProvider._();

  static GearListOverviewDataProvider? _instance;

  final _dataProvider = ModelDataProvider();
  GearListDataProvider get gearListDataProvider =>
      _dataProvider._gearListDataProvider;
  GearListVersionDataProvider get gearListVersionDataProvider =>
      _dataProvider._gearListVersionDataProvider;

  List<(GearList, List<GearListVersion>)> _gearListsWithVersions = [];
  List<(GearList, List<GearListVersion>)> get gearListsWithVersions =>
      _gearListsWithVersions;

  void setState() => notifyListeners();

  Future<void> _onUpdate() async {
    final gearLists = await _dataProvider._gearListDataProvider.getAll();
    final gearListsWithVersions = <(GearList, List<GearListVersion>)>[];
    for (final gearList in gearLists) {
      gearListsWithVersions.add(
        (
          gearList,
          await _dataProvider._gearListVersionDataProvider
              .getByGearListId(gearList.id)
        ),
      );
    }
    _gearListsWithVersions = gearListsWithVersions;
    notifyListeners();
  }
}

class GearItemOverviewDataProvider extends ChangeNotifier {
  factory GearItemOverviewDataProvider() {
    if (_instance == null) {
      final instance = GearItemOverviewDataProvider._();
      instance._dataProvider.addListener(instance._onUpdate);
      instance._onUpdate();
      _instance = instance;
    }
    return _instance!;
  }

  GearItemOverviewDataProvider._();

  static GearItemOverviewDataProvider? _instance;

  final _dataProvider = ModelDataProvider();
  GearCategoryDataProvider get gearCategoryDataProvider =>
      _dataProvider._gearCategoryDataProvider;
  GearItemDataProvider get gearItemDataProvider =>
      _dataProvider._gearItemDataProvider;

  List<(GearCategory, List<GearItem>)> _gearCategoriesWithItems = [];
  List<(GearCategory, List<GearItem>)> get gearCategoriesWithItems =>
      _gearCategoriesWithItems;

  Future<void> _onUpdate() async {
    final gearCategories =
        await _dataProvider._gearCategoryDataProvider.getAll();
    final gearCategoriesWithItems = <(GearCategory, List<GearItem>)>[];
    for (final gearCategory in gearCategories) {
      gearCategoriesWithItems.add(
        (
          gearCategory,
          await _dataProvider._gearItemDataProvider
              .getByGearCategoryId(gearCategory.id)
        ),
      );
    }
    _gearCategoriesWithItems = gearCategoriesWithItems;
    notifyListeners();
  }

  Future<void> reorderGearItem(
    GearCategoryId gearCategoryId,
    int oldIndex,
    int newIndex,
  ) async {
    // TODO
  }
}

class GearListDetailsDataProvider extends ChangeNotifier {
  factory GearListDetailsDataProvider() {
    if (_instance == null) {
      final instance = GearListDetailsDataProvider._();
      instance._dataProvider.addListener(instance._onUpdate);
      instance._onUpdate();
      _instance = instance;
    }
    return _instance!;
  }

  GearListDetailsDataProvider._();

  static GearListDetailsDataProvider? _instance;

  final _dataProvider = ModelDataProvider();
  GearListVersionDataProvider get gearListVersionDataProvider =>
      _dataProvider._gearListVersionDataProvider;
  GearListItemDataProvider get gearListItemDataProvider =>
      _dataProvider._gearListItemDataProvider;
  GearItemDataProvider get gearItemDataProvider =>
      _dataProvider._gearItemDataProvider;

  Map<GearCategoryId, List<GearItem>> _gearItems = {};
  Map<GearCategoryId, List<GearItem>> get gearItems => _gearItems;
  GearListVersionId? _gearListVersionId;

  (
    GearListVersion,
    List<(GearCategory, List<(GearListItem, GearItem)>)>
  )? _gearItemsForListVersion;
  (GearListVersion, List<(GearCategory, List<(GearListItem, GearItem)>)>)?
      gearItemsForListVersion(GearListVersionId gearListVersionId) {
    if (_gearListVersionId == gearListVersionId) {
      return _gearItemsForListVersion;
    } else {
      _gearListVersionId = gearListVersionId;
      _onUpdate();
      return null;
    }
  }

  Future<void> _onUpdate() async {
    final gearItems = await gearItemDataProvider.getAll();
    final gearItemMap = <GearCategoryId, List<GearItem>>{};
    for (final gearItem in gearItems) {
      if (gearItemMap.containsKey(gearItem.gearCategoryId)) {
        gearItemMap[gearItem.gearCategoryId]!.add(gearItem);
      } else {
        gearItemMap[gearItem.gearCategoryId] = [gearItem];
      }
    }
    _gearItems = gearItemMap;
    if (_gearListVersionId == null) {
      notifyListeners();
      return;
    }
    final gearListVersion = await _dataProvider._gearListVersionDataProvider
        .getById(_gearListVersionId!);
    final gearListCategories =
        await _dataProvider._gearCategoryDataProvider.getAll();
    final categoriesWithItems =
        <(GearCategory, List<(GearListItem, GearItem)>)>[];
    for (final gearCategory in gearListCategories) {
      final gearListItemsWithItems = await _dataProvider
          ._gearListItemDataProvider
          .getWithItemByVersionAndCategory(
        gearListVersion.id,
        gearCategory.id,
      );
      categoriesWithItems.add((gearCategory, gearListItemsWithItems));
    }

    _gearItemsForListVersion = (gearListVersion, categoriesWithItems);

    notifyListeners();
  }
}

extension ListItemWithItem on (GearListItem, GearItem) {
  int get weight => $1.count * $2.weight;
}

extension ListItemsWithItems on List<(GearListItem, GearItem)> {
  int get weight => map((i) => i.weight).sum;

  List<GearListItem> get listItems => map((e) => e.$1).toList();
}

extension CategoriesWithItems
    on List<(GearCategory, List<(GearListItem, GearItem)>)> {
  int get weight => map((c) => c.$2.weight).sum;

  List<GearListItem> get listItems =>
      map((e) => e.$2.listItems).flattened.toList();
}
