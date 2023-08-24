import 'package:gear_list_planner/model.dart';
import 'package:sqflite/sqflite.dart';

abstract final class AppDatabase {
  static late final Database database;

  static const _databasePath = "gear_list_planner.sqlite";

  static Future<void> init() async {
    database = await openDatabase(
      _databasePath,
      version: 1,
      onCreate: (db, version) async {
        const integer = "integer not null";
        const string = "text not null";

        String intColumn(String column) => "$column $integer";
        String boolColumn(String column) =>
            "${intColumn(column)} check($column in (0, 1))";
        String fkColumn(String column, String table) =>
            "${intColumn(column)} references $table on delete cascade";
        String stringColumn(String column) => "$column $string";

        final idColumn = "${intColumn(Columns.id)} primary key autoincrement";
        final nameColumn = stringColumn(Columns.name);

        String unique(List<String> columns) => "unique(${columns.join(', ')})";

        String table(String table, List<String> columns) =>
            "create table $table(\n${columns.join(',\n')}\n) strict;";

        final gearListTable = table(Tables.gearList, [
          idColumn,
          nameColumn,
          unique([Columns.name]),
        ]);

        final gearListVersionTable = table(Tables.gearListVersion, [
          idColumn,
          fkColumn(Columns.gearListId, Tables.gearList),
          nameColumn,
          boolColumn(Columns.readOnly),
          unique([Columns.gearListId, Columns.name]),
        ]);

        final gearListItemTable = table(Tables.gearListItem, [
          idColumn,
          fkColumn(Columns.gearItemId, Tables.gearItem),
          fkColumn(Columns.gearListVersionId, Tables.gearListVersion),
          intColumn(Columns.count),
          boolColumn(Columns.packed),
          unique([Columns.gearItemId, Columns.gearListVersionId]),
        ]);

        final gearItemTable = table(Tables.gearItem, [
          idColumn,
          fkColumn(Columns.gearCategoryId, Tables.gearCategory),
          nameColumn,
          intColumn(Columns.weight),
          intColumn(Columns.sortIndex),
          unique([Columns.name]),
        ]);

        final gearCategoryTable = table(Tables.gearCategory, [
          idColumn,
          nameColumn,
          unique([Columns.name]),
        ]);

        await db.execute(gearListTable);
        await db.execute(gearListVersionTable);
        await db.execute(gearCategoryTable);
        await db.execute(gearItemTable);
        await db.execute(gearListItemTable);
      },
      onOpen: (db) async {
        await db.execute("pragma foreign_keys = on;");
      },
    );
  }

  static Future<void> clearDatabase() async {
    await database.delete(Tables.gearList, where: "1=?", whereArgs: [1]);
    await database.delete(Tables.gearCategory, where: "1=?", whereArgs: [1]);
    // other tables deleted by cascading delete
  }
}

abstract final class Tables {
  static const gearList = "gear_list";
  static const gearListVersion = "gear_list_version";
  static const gearListItem = "gear_list_item";
  static const gearItem = "gear_item";
  static const gearCategory = "gear_category";
}

abstract final class Columns {
  static const count = "count";
  static const id = "id";
  static const sortIndex = "sort_index";
  static const gearListId = "gear_list_id";
  static const gearListVersionId = "gear_list_version_id";
  static const gearListItemId = "gear_list_item_id";
  static const gearItemId = "gear_item_id";
  static const gearCategoryId = "gear_category_id";
  static const name = "name";
  static const packed = "packed";
  static const readOnly = "read_only";
  static const weight = "weight";
}

abstract class TableAccessor<I extends Id, E extends Entity<I>> {
  static Database get database => AppDatabase.database;

  E fromDbRecord(Map<String, dynamic> dbRecord);
  Map<String, dynamic> toDbRecord(E object) => object.toJson();

  String get tableName;

  Future<int> create(E object, bool autoId) async {
    final record = toDbRecord(object);
    if (autoId) {
      record.remove(Columns.id);
    }
    return database.insert(tableName, record);
  }

  Future<void> update(E object) async {
    await database.update(
      tableName,
      toDbRecord(object),
      where: "${Columns.id} = ?",
      whereArgs: [object.id.id],
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

  Future<List<E>> getAll() async {
    final data = await database.query(tableName);
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
  GearList fromDbRecord(Map<String, dynamic> dbRecord) =>
      GearList.fromJson(dbRecord);

  @override
  String tableName = Tables.gearList;
}

class GearListVersionAccessor
    extends TableAccessor<GearListVersionId, GearListVersion> {
  @override
  GearListVersion fromDbRecord(Map<String, dynamic> dbRecord) {
    final map = Map.of(dbRecord);
    map[Columns.readOnly] = map[Columns.readOnly] as int == 0 ? false : true;
    return GearListVersion.fromJson(map);
  }

  @override
  Map<String, dynamic> toDbRecord(GearListVersion object) {
    final json = object.toJson();
    json[Columns.readOnly] = json[Columns.readOnly] as bool ? 1 : 0;
    return json;
  }

  @override
  String tableName = Tables.gearListVersion;

  Future<List<GearListVersion>> getByGearListId(GearListId gearListId) async {
    final data = await TableAccessor.database.query(
      tableName,
      where: "${Columns.gearListId} = ?",
      whereArgs: [gearListId.id],
    );
    return data.map(fromDbRecord).toList();
  }
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

  Future<List<(GearListItem, GearItem)>> getWithItemByVersionAndCategory(
    GearListVersionId gearListVersionId,
    GearCategoryId gearCategoryId,
  ) async {
    final data = await TableAccessor.database.rawQuery(
      """
      select 
        ${_fullyQualifiedNames(Tables.gearListItem, [
            Columns.id,
            Columns.gearItemId,
            Columns.gearListVersionId,
            Columns.count,
            Columns.packed,
          ])},
        ${_fullyQualifiedNames(Tables.gearItem, [
            Columns.id,
            Columns.gearCategoryId,
            Columns.name,
            Columns.weight,
            Columns.sortIndex,
          ])}
      from ${Tables.gearListItem}
      inner join ${Tables.gearItem}
      on ${Tables.gearListItem}.${Columns.gearItemId} = ${Tables.gearItem}.${Columns.id}
      where ${Tables.gearListItem}.${Columns.gearListVersionId} = ${gearListVersionId.id}
      and ${Tables.gearItem}.${Columns.gearCategoryId} = ${gearCategoryId.id}
      order by ${Tables.gearItem}.${Columns.sortIndex};
      """,
    );
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
}

class GearItemAccessor extends TableAccessor<GearItemId, GearItem> {
  @override
  GearItem fromDbRecord(Map<String, dynamic> dbRecord) =>
      GearItem.fromJson(dbRecord);

  @override
  String tableName = Tables.gearItem;

  Future<int> getMaxSortIndexForCategory(
    GearCategoryId gearCategoryId,
  ) async {
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
}

class GearCategoryAccessor extends TableAccessor<GearCategoryId, GearCategory> {
  @override
  GearCategory fromDbRecord(Map<String, dynamic> dbRecord) =>
      GearCategory.fromJson(dbRecord);

  @override
  String tableName = Tables.gearCategory;
}
