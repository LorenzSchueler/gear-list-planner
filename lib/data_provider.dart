// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' show AnchorElement;

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:gear_list_planner/database.dart';
import 'package:gear_list_planner/model.dart';
import 'package:gear_list_planner/result.dart';
import 'package:gear_list_planner/table_accessors.dart';

abstract class EntityDataProvider<I extends Id, E extends Entity<I>>
    extends ChangeNotifier {
  TableAccessor<I, E> get tableAccessor;

  Future<Result<int>> create(
    E object, {
    required bool autoId,
    bool notify = true,
  }) async {
    final result = await tableAccessor.create(object, autoId);
    if (result.isSuccess && notify) {
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> update(E object, {bool notify = true}) async {
    final result = await tableAccessor.update(object);
    if (result.isSuccess && notify) {
      notifyListeners();
    }
    return result;
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
  final GearListAccessor tableAccessor = GearListAccessor();

  Future<Result<void>> cloneList(
    String name,
    GearListId cloneId,
  ) async {
    final result = await create(
      GearList(
        id: GearListId(0),
        name: name,
        notes: "",
        readOnly: false,
      ),
      autoId: true,
    );
    if (result.isError) {
      return result;
    }
    final id = result.success;
    await TableAccessor.database.execute(
      """
      insert into ${Tables.gearListItem}(${Columns.gearItemId}, ${Columns.gearListId}, ${Columns.count}, ${Columns.packed}) 
      select ${Columns.gearItemId}, $id, ${Columns.count}, ${Columns.packed}
      from ${Tables.gearListItem} 
      where ${Columns.gearListId} = ${cloneId.id};
      """,
    );
    return Result.success(null);
  }
}

class GearListItemDataProvider
    extends EntityDataProvider<GearListItemId, GearListItem> {
  factory GearListItemDataProvider() => _instance;

  GearListItemDataProvider._();

  static final _instance = GearListItemDataProvider._();

  @override
  final GearListItemAccessor tableAccessor = GearListItemAccessor();

  Future<List<(GearListItem, GearItem)>> getWithItemByListAndCategory(
    GearListId gearListId,
    GearCategoryId gearCategoryId,
  ) =>
      tableAccessor.getWithItemByListAndCategory(
        gearListId,
        gearCategoryId,
      );

  Future<List<((GearListItem?, GearListItem?), GearItem)>>
      getWithItemByListsAndCategory(
    (GearListId, GearListId) gearListIds,
    GearCategoryId gearCategoryId,
  ) =>
          tableAccessor.getWithItemByListsAndCategory(
            gearListIds,
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
  Future<Result<int>> create(
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

  Future<Result<void>> loadModel() async {
    await AppDatabase.clearDatabase();
    final data = await _readFile();
    if (data == null) {
      return Result.success(null);
    }

    final GearModel model;
    try {
      model = GearModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } on TypeError catch (e) {
      return Result.error(ErrorType.invalidJson, e.toString());
    }
    await _createModel(model);
    notifyListeners();
    return Result.success(null);
  }

  Future<void> storeModel() async {
    final model = GearModel(
      gearLists: await _gearListDataProvider.getAll(),
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

  List<GearList> _gearLists = [];
  List<GearList> get gearLists => _gearLists;

  void setState() => notifyListeners();

  Future<void> _onUpdate() async {
    _gearLists = await gearListDataProvider.getAll();
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
    final all = await gearItemDataProvider.getByGearCategoryId(gearCategoryId);

    if (oldIndex < newIndex - 1) {
      final item = all.removeAt(oldIndex);
      all.insert(newIndex - 1, item);
    } else if (oldIndex > newIndex) {
      all.insert(newIndex, all.removeAt(oldIndex));
    }

    all.forEachIndexed((index, item) => item..sortIndex = index);

    await gearItemDataProvider.updateMultiple(all);
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
  GearListDataProvider get gearListDataProvider =>
      _dataProvider._gearListDataProvider;
  GearListItemDataProvider get gearListItemDataProvider =>
      _dataProvider._gearListItemDataProvider;
  GearItemDataProvider get gearItemDataProvider =>
      _dataProvider._gearItemDataProvider;

  Map<GearCategoryId, List<GearItem>> _gearItems = {};
  Map<GearCategoryId, List<GearItem>> get gearItems => _gearItems;
  GearListId? _gearListId;

  (
    GearList,
    List<(GearCategory, List<(GearListItem, GearItem)>)>
  )? _gearItemsForList;
  (GearList, List<(GearCategory, List<(GearListItem, GearItem)>)>)?
      gearItemsForList(GearListId gearListId) {
    if (_gearListId == gearListId) {
      return _gearItemsForList;
    } else {
      _gearListId = gearListId;
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
    if (_gearListId == null) {
      notifyListeners();
      return;
    }
    final gearList =
        await _dataProvider._gearListDataProvider.getById(_gearListId!);
    final gearListCategories =
        await _dataProvider._gearCategoryDataProvider.getAll();
    final categoriesWithItems =
        <(GearCategory, List<(GearListItem, GearItem)>)>[];
    for (final gearCategory in gearListCategories) {
      final gearListItemsWithItems = await _dataProvider
          ._gearListItemDataProvider
          .getWithItemByListAndCategory(
        _gearListId!,
        gearCategory.id,
      );
      categoriesWithItems.add((gearCategory, gearListItemsWithItems));
    }

    _gearItemsForList = (gearList, categoriesWithItems);

    notifyListeners();
  }
}

class GearListCompareDataProvider extends ChangeNotifier {
  factory GearListCompareDataProvider() {
    if (_instance == null) {
      final instance = GearListCompareDataProvider._();
      instance._dataProvider.addListener(instance._onUpdate);
      instance._onUpdate();
      _instance = instance;
    }
    return _instance!;
  }

  GearListCompareDataProvider._();

  static GearListCompareDataProvider? _instance;

  final _dataProvider = ModelDataProvider();
  GearListDataProvider get gearListDataProvider =>
      _dataProvider._gearListDataProvider;
  GearListItemDataProvider get gearListItemDataProvider =>
      _dataProvider._gearListItemDataProvider;
  GearItemDataProvider get gearItemDataProvider =>
      _dataProvider._gearItemDataProvider;

  Map<GearCategoryId, List<GearItem>> _gearItems = {};
  Map<GearCategoryId, List<GearItem>> get gearItems => _gearItems;
  (GearListId, GearListId)? _gearListIds;

  (
    (GearList, GearList),
    List<(GearCategory, List<((GearListItem?, GearListItem?), GearItem)>)>
  )? _gearItemsForList;
  (
    (GearList, GearList),
    List<(GearCategory, List<((GearListItem?, GearListItem?), GearItem)>)>
  )? gearItemsForList(
    (GearListId, GearListId) gearListIds,
  ) {
    if (_gearListIds == gearListIds) {
      return _gearItemsForList;
    } else {
      _gearListIds = gearListIds;
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
    if (_gearListIds == null) {
      notifyListeners();
      return;
    }
    final gearList1 =
        await _dataProvider._gearListDataProvider.getById(_gearListIds!.$1);
    final gearList2 =
        await _dataProvider._gearListDataProvider.getById(_gearListIds!.$2);
    final gearListCategories =
        await _dataProvider._gearCategoryDataProvider.getAll();
    final categoriesWithItems =
        <(GearCategory, List<((GearListItem?, GearListItem?), GearItem)>)>[];
    for (final gearCategory in gearListCategories) {
      final gearListItemsWithItems = await _dataProvider
          ._gearListItemDataProvider
          .getWithItemByListsAndCategory(
        _gearListIds!,
        gearCategory.id,
      );
      categoriesWithItems.add((gearCategory, gearListItemsWithItems));
    }

    _gearItemsForList = ((gearList1, gearList2), categoriesWithItems);

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

extension ListItemWithItemX on ((GearListItem?, GearListItem?), GearItem) {
  int get weight1 => ($1.$1?.count ?? 0) * $2.weight;
  int get weight2 => ($1.$2?.count ?? 0) * $2.weight;
}

extension ListItemsWithItemsX
    on List<((GearListItem?, GearListItem?), GearItem)> {
  int get weight1 => map((i) => i.weight1).sum;
  int get weight2 => map((i) => i.weight2).sum;
}

extension CategoriesWithItemsX
    on List<(GearCategory, List<((GearListItem?, GearListItem?), GearItem)>)> {
  int get weight1 => map((c) => c.$2.weight1).sum;
  int get weight2 => map((c) => c.$2.weight2).sum;
}
