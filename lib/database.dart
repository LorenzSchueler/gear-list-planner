import 'package:sqflite/sqflite.dart';

abstract final class AppDatabase {
  static Database? _database;
  static Database? get database => _database;

  static Future<void> init() async {
    _database = await openDatabase(
      "gear_list_planner.sqlite",
      version: 1,
      onCreate: (db, version) async {
        const integer = "integer not null";
        const real = "real not null";
        const string = "string not null";

        String intColumn(String column) => "$column $integer";
        String boolColumn(String column) =>
            "${intColumn(column)} check($column in (0, 1))";
        String fkColumn(String column, String table) =>
            "${intColumn(column)} references $table on delete cascade";
        String realColumn(String column) => "$column $real";
        String stringColumn(String column) => "$column $string";

        final idColumn = "${intColumn(Columns.id)} primary key";
        final nameColumn = stringColumn(Columns.name);

        String table(String table, List<String> columns) =>
            "create table $table(\n${columns.join(',\n')}\n);";

        final gearListTable = table(Tables.gearList, [idColumn, nameColumn]);

        final gearListVersionTable = table(Tables.gearListVersion, [
          idColumn,
          fkColumn(Columns.gearListId, Tables.gearList),
          nameColumn,
          boolColumn(Columns.readOnly)
        ]);

        final gearListItemTable = table(Tables.gearListItem, [
          idColumn,
          fkColumn(Columns.gearItemId, Tables.gearItem),
          fkColumn(Columns.gearListVersionId, Tables.gearListVersion),
          intColumn(Columns.count),
          boolColumn(Columns.packed),
        ]);

        final gearItemTable = table(Tables.gearItem, [
          idColumn,
          fkColumn(Columns.gearCategoryId, Tables.gearCategory),
          nameColumn,
          realColumn(Columns.weight),
          intColumn(Columns.sortIndex)
        ]);

        final gearCategoryTable =
            table(Tables.gearCategory, [idColumn, nameColumn]);

        await db.execute(gearListTable);
        await db.execute(gearListVersionTable);
        await db.execute(gearCategoryTable);
        await db.execute(gearItemTable);
        await db.execute(gearListItemTable);
      },
      onOpen: (db) async {
        await db.execute("pragma foreign_key = on;");
      },
    );
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