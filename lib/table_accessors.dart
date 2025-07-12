import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/database.dart';
import 'package:gear_list_planner/model.dart';
import 'package:gear_list_planner/result.dart';
import 'package:sqflite/sqflite.dart';

abstract class TableAccessor<I extends Id, E extends Entity<I>> {
  static Database get database => AppDatabase.database;

  E fromDbRecord(Map<String, dynamic> dbRecord);
  Map<String, dynamic> toDbRecord(E object) => object.toJson();

  String get tableName;

  Future<Result<int>> create(E object, bool autoId) async {
    final record = toDbRecord(object);
    if (autoId) {
      record.remove(Columns.id);
    }
    return Result.from(() => database.insert(tableName, record));
  }

  Future<Result<void>> update(E object) async {
    return Result.from(
      () => database.update(
        tableName,
        toDbRecord(object),
        where: "${Columns.id} = ?",
        whereArgs: [object.id.id],
      ),
    );
  }

  Future<void> delete(E object) async {
    await database.delete(
      tableName,
      where: "${Columns.id} = ?",
      whereArgs: [object.id.id],
    );
  }

  Future<E> getById(I id) async {
    final data = await database.query(
      tableName,
      where: "${Columns.id} = ?",
      whereArgs: [id.id],
    );
    return fromDbRecord(data.first);
  }

  Future<List<E>> getAll(bool orderById) async {
    final data = await database.query(
      tableName,
      orderBy: orderById ? Columns.id : null,
    );
    return data.map(fromDbRecord).toList();
  }

  String _fullyQualifiedNames(String table, List<String> columns) {
    return columns
        .map((column) => "$table.$column as '$table.$column'")
        .join(",\n");
  }
}

class GearListAccessor extends TableAccessor<GearListId, GearList> {
  @override
  GearList fromDbRecord(Map<String, dynamic> dbRecord) {
    final map = Map.of(dbRecord);
    map[Columns.readOnly] = map[Columns.readOnly] as int == 0 ? false : true;
    return GearList.fromJson(map);
  }

  @override
  Map<String, dynamic> toDbRecord(GearList object) {
    final json = object.toJson();
    json[Columns.readOnly] = json[Columns.readOnly] as bool ? 1 : 0;
    return json;
  }

  @override
  String tableName = Tables.gearList;
}

class GearListItemAccessor extends TableAccessor<GearListItemId, GearListItem> {
  @override
  GearListItem fromDbRecord(Map<String, dynamic> dbRecord) {
    final map = Map.of(dbRecord);
    map[Columns.packed] = map[Columns.packed] as int == 0 ? false : true;
    return GearListItem.fromJson(map);
  }

  @override
  Map<String, dynamic> toDbRecord(GearListItem object) {
    final json = object.toJson();
    json[Columns.packed] = json[Columns.packed] as bool ? 1 : 0;
    return json;
  }

  @override
  String tableName = Tables.gearListItem;

  Future<List<(GearListItem, GearItem)>> getWithItemByListAndCategory(
    GearListId gearListId,
    GearCategoryId gearCategoryId,
  ) async {
    final data = await TableAccessor.database.rawQuery("""
      select 
        ${_fullyQualifiedNames(Tables.gearListItem, [Columns.id, Columns.gearItemId, Columns.gearListId, Columns.count, Columns.packed])},
        ${_fullyQualifiedNames(Tables.gearItem, [Columns.id, Columns.gearCategoryId, Columns.type, Columns.name, Columns.weight, Columns.sortIndex])}
      from ${Tables.gearListItem}
      inner join ${Tables.gearItem}
      on ${Tables.gearListItem}.${Columns.gearItemId} = ${Tables.gearItem}.${Columns.id}
      where ${Tables.gearListItem}.${Columns.gearListId} = ${gearListId.id}
      and ${Tables.gearItem}.${Columns.gearCategoryId} = ${gearCategoryId.id}
      order by ${Tables.gearItem}.${Columns.sortIndex};
      """);
    return data.map((joined) {
      final gearListItem = fromDbRecord(
        Map.fromEntries(
          joined.entries
              .where((element) => element.key.startsWith(Tables.gearListItem))
              .map(
                (e) => MapEntry(
                  e.key.replaceFirst("${Tables.gearListItem}.", ""),
                  e.value,
                ),
              ),
        ),
      );
      final gearItem = GearItemAccessor().fromDbRecord(
        Map.fromEntries(
          joined.entries
              .where((element) => element.key.startsWith(Tables.gearItem))
              .map(
                (e) => MapEntry(
                  e.key.replaceFirst("${Tables.gearItem}.", ""),
                  e.value,
                ),
              ),
        ),
      );
      return (gearListItem, gearItem);
    }).toList();
  }

  Future<List<CompareItem>> getWithItemByListsAndCategory(
    (GearListId, GearListId) gearListIds,
    GearCategoryId gearCategoryId,
  ) async {
    const tableGearListItem2 = "gear_list_item_2";
    final data = await TableAccessor.database.rawQuery("""
      select 
        ${_fullyQualifiedNames(Tables.gearListItem, [Columns.id, Columns.gearItemId, Columns.gearListId, Columns.count, Columns.packed])},
        ${_fullyQualifiedNames(tableGearListItem2, [Columns.id, Columns.gearItemId, Columns.gearListId, Columns.count, Columns.packed])},
        ${_fullyQualifiedNames(Tables.gearItem, [Columns.id, Columns.gearCategoryId, Columns.type, Columns.name, Columns.weight, Columns.sortIndex])}
      from ${Tables.gearItem}
      left outer join (
        select * from ${Tables.gearListItem}
        where ${Tables.gearListItem}.${Columns.gearListId} = ${gearListIds.$1.id}
      ) as ${Tables.gearListItem}
      on ${Tables.gearListItem}.${Columns.gearItemId} = ${Tables.gearItem}.${Columns.id}
      left outer join (
        select * from ${Tables.gearListItem}
        where ${Tables.gearListItem}.${Columns.gearListId} = ${gearListIds.$2.id}
      ) as $tableGearListItem2
      on $tableGearListItem2.${Columns.gearItemId} = ${Tables.gearItem}.${Columns.id}
      where ${Tables.gearItem}.${Columns.gearCategoryId} = ${gearCategoryId.id}
      order by ${Tables.gearItem}.${Columns.sortIndex};
      """);
    return data
        .map((joined) {
          final gearListItem1 =
              joined["${Tables.gearListItem}.${Columns.id}"] != null
              ? fromDbRecord(
                  Map.fromEntries(
                    joined.entries
                        .where(
                          (element) =>
                              element.key.startsWith(Tables.gearListItem),
                        )
                        .map(
                          (e) => MapEntry(
                            e.key.replaceFirst("${Tables.gearListItem}.", ""),
                            e.value,
                          ),
                        ),
                  ),
                )
              : null;
          final gearListItem2 =
              joined["$tableGearListItem2.${Columns.id}"] != null
              ? fromDbRecord(
                  Map.fromEntries(
                    joined.entries
                        .where(
                          (element) =>
                              element.key.startsWith(tableGearListItem2),
                        )
                        .map(
                          (e) => MapEntry(
                            e.key.replaceFirst("$tableGearListItem2.", ""),
                            e.value,
                          ),
                        ),
                  ),
                )
              : null;
          final gearItem = GearItemAccessor().fromDbRecord(
            Map.fromEntries(
              joined.entries
                  .where((element) => element.key.startsWith(Tables.gearItem))
                  .map(
                    (e) => MapEntry(
                      e.key.replaceFirst("${Tables.gearItem}.", ""),
                      e.value,
                    ),
                  ),
            ),
          );
          return CompareItem(gearItem, gearListItem1, gearListItem2);
        })
        .where(
          (item) => item.gearListItem1 != null || item.gearListItem2 != null,
        )
        .toList();
  }
}

class GearItemAccessor extends TableAccessor<GearItemId, GearItem> {
  @override
  GearItem fromDbRecord(Map<String, dynamic> dbRecord) =>
      GearItem.fromJson(dbRecord);

  @override
  String tableName = Tables.gearItem;

  Future<int> getMaxSortIndexForCategory(GearCategoryId gearCategoryId) async {
    final id = await TableAccessor.database.query(
      Tables.gearItem,
      columns: ["max(${Columns.sortIndex}) as max_sort_index"],
      where: "${Columns.gearCategoryId} = ?",
      whereArgs: [gearCategoryId.id],
    );
    return id.single["max_sort_index"] as int? ?? -1;
  }

  Future<List<GearItem>> getByGearCategoryId(
    GearCategoryId gearCategoryId,
  ) async {
    final data = await TableAccessor.database.query(
      tableName,
      where: "${Columns.gearCategoryId} = ?",
      whereArgs: [gearCategoryId.id],
      orderBy: Columns.sortIndex,
    );
    return data.map(fromDbRecord).toList();
  }

  Future<List<GearItem>> getNonSelectedByGearCategoryIdAndListId(
    GearCategoryId gearCategoryId,
    GearListId gearListId,
  ) async {
    final data = await TableAccessor.database.query(
      tableName,
      where:
          "${Columns.gearCategoryId} = ? and "
          "not exists (select * from ${Tables.gearListItem} where ${Columns.gearItemId} = ${Tables.gearItem}.${Columns.id} and ${Columns.gearListId} = ?)",
      whereArgs: [gearCategoryId.id, gearListId.id],
      orderBy: Columns.sortIndex,
    );
    return data.map(fromDbRecord).toList();
  }
}

class GearCategoryAccessor extends TableAccessor<GearCategoryId, GearCategory> {
  @override
  GearCategory fromDbRecord(Map<String, dynamic> dbRecord) =>
      GearCategory.fromJson(dbRecord);

  @override
  String tableName = Tables.gearCategory;

  @override
  Future<List<GearCategory>> getAll(bool orderById) async {
    final data = await TableAccessor.database.query(
      tableName,
      orderBy: orderById ? Columns.id : Columns.sortIndex,
    );
    return data.map(fromDbRecord).toList();
  }

  Future<int> getMaxSortIndex() async {
    final id = await TableAccessor.database.query(
      Tables.gearCategory,
      columns: ["max(${Columns.sortIndex}) as max_sort_index"],
    );
    return id.single["max_sort_index"] as int? ?? -1;
  }
}
