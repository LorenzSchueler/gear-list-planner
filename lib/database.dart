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
          stringColumn(Columns.notes),
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
  static const notes = "notes";
  static const packed = "packed";
  static const readOnly = "read_only";
  static const weight = "weight";
}
