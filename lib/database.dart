import 'package:sqflite/sqflite.dart';

abstract final class AppDatabase {
  static late final Database database;

  static const _databasePath = "gear_list_planner.sqlite";

  static Future<void> init() async {
    database = await openDatabase(
      _databasePath,
      version: 1,
      onCreate: (db, version) async {
        final gearListTable = Table(
          Tables.gearList,
          [
            Column.idColumn(),
            Column.stringColumn(Columns.name),
          ],
          [Columns.name],
        );

        final gearListVersionTable = Table(
          Tables.gearListVersion,
          [
            Column.idColumn(),
            Column.fkColumn(Columns.gearListId, Tables.gearList),
            Column.stringColumn(Columns.name),
            Column.stringColumn(Columns.notes),
            Column.boolColumn(Columns.readOnly),
          ],
          [Columns.gearListId, Columns.name],
        );

        final gearListItemTable = Table(
          Tables.gearListItem,
          [
            Column.idColumn(),
            Column.fkColumn(Columns.gearItemId, Tables.gearItem),
            Column.fkColumn(Columns.gearListVersionId, Tables.gearListVersion),
            Column.intColumn(Columns.count),
            Column.boolColumn(Columns.packed),
          ],
          [Columns.gearItemId, Columns.gearListVersionId],
        );

        final gearItemTable = Table(
          Tables.gearItem,
          [
            Column.idColumn(),
            Column.fkColumn(Columns.gearCategoryId, Tables.gearCategory),
            Column.stringColumn(Columns.name),
            Column.intColumn(Columns.weight),
            Column.intColumn(Columns.sortIndex),
          ],
          [Columns.name],
        );

        final gearCategoryTable = Table(
          Tables.gearCategory,
          [
            Column.idColumn(),
            Column.stringColumn(Columns.name),
          ],
          [Columns.name],
        );

        await db.execute(gearListTable.setupSql);
        await db.execute(gearListVersionTable.setupSql);
        await db.execute(gearCategoryTable.setupSql);
        await db.execute(gearItemTable.setupSql);
        await db.execute(gearListItemTable.setupSql);
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

class Table {
  Table(this.name, this.columns, this.uniqueColumns);

  String name;
  List<Column> columns;
  List<String> uniqueColumns;

  String get setupSql => """
    create table $name(
      ${columns.map((c) => c.setupSql).join(',\n')},
      unique(${uniqueColumns.join(', ')})
    ) strict;""";
}

class Column {
  Column.intColumn(String column) : setupSql = "$column $_integer";
  Column.boolColumn(String column)
      : setupSql = "$column $_integer check($column in (0, 1))";
  Column.fkColumn(String column, String table)
      : setupSql = "$column $_integer references $table on delete cascade";
  Column.stringColumn(String column) : setupSql = "$column $_string";
  Column.idColumn()
      : setupSql = "${Columns.id} $_integer primary key autoincrement";

  static const _integer = "integer not null";
  static const _string = "text not null";

  String setupSql;
}
