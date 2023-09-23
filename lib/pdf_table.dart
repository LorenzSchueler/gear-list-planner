import 'package:collection/collection.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/model.dart';
import 'package:gear_list_planner/write_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;

const _space = 5.0;
const _columnsPerPage = 6;
const _maxRowsPerColumn = 26;

abstract class _PdfWidget {
  pdf.Widget get widget;
  pdf.Widget get sizedWidget =>
      pdf.SizedBox(child: widget, height: 21); // _Item has height of 20.808

  final pdf.Widget _spacer = pdf.SizedBox(width: _space);
  final pdf.Widget _startSpacer = pdf.SizedBox(width: 2 * _space);
}

class Category extends _PdfWidget {
  Category(this.name);

  final String name;

  @override
  pdf.Widget get widget => pdf.Row(
        children: [
          _startSpacer,
          pdf.Text(
            name,
            style: pdf.TextStyle(fontWeight: pdf.FontWeight.bold),
          ),
        ],
      );
}

class _Weight extends _PdfWidget {
  _Weight(this.items) : total = false;
  _Weight.total(List<GearCategoryWithItems> categoriesWithItems)
      : items =
            categoriesWithItems.map((c) => c.selectedItems).flattened.toList(),
        total = true;

  List<(GearListItem, GearItem)> items;
  bool total;
  late final weight = items.map((item) => item.$1.count * item.$2.weight).sum;

  @override
  pdf.Widget get widget => pdf.Row(
        mainAxisAlignment: pdf.MainAxisAlignment.end,
        children: [
          pdf.Text(
            total ? "Total: ${weight.inKg} kg" : "${weight.inKg} kg",
            style: pdf.TextStyle(fontWeight: pdf.FontWeight.bold),
          ),
        ],
      );
}

class _Item extends _PdfWidget {
  _Item(this.combinedItem);

  (GearListItem, GearItem) combinedItem;

  @override
  pdf.Widget get widget => pdf.Row(
        children: [
          _startSpacer,
          pdf.Checkbox(value: false, name: "_", height: 10, width: 10),
          _spacer,
          pdf.Text(combinedItem.$1.count.toString()),
          _spacer,
          pdf.Expanded(
            child: pdf.Column(
              crossAxisAlignment: pdf.CrossAxisAlignment.start,
              children: [
                pdf.Text(combinedItem.$2.type),
                pdf.Text(
                  combinedItem.$2.name,
                  style: const pdf.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
          _spacer,
          pdf.Text(combinedItem.$2.weight.toString()),
        ],
      );
}

class _Placeholder extends _PdfWidget {
  _Placeholder();

  @override
  pdf.Widget get widget => pdf.Container();
}

extension on List<GearCategoryWithItems> {
  List<List<_PdfWidget>> toColumnTable(bool compact) {
    final maxItems = map((e) => e.selectedItems.length).maxOrNull ?? 0;
    final columnTable = <List<_PdfWidget>>[];
    for (final categoryWithItems in this) {
      final widgets = categoryWithItems.toWidgets(compact, maxItems);
      if (compact &&
          columnTable.isNotEmpty &&
          widgets.length + 1 <= _maxRowsPerColumn - columnTable.last.length) {
        columnTable.last.add(_Placeholder());
        columnTable.last.addAll(widgets);
      } else {
        columnTable.add(widgets);
      }
    }
    if (compact &&
        columnTable.isNotEmpty &&
        2 <= _maxRowsPerColumn - columnTable.last.length) {
      columnTable.last.add(_Placeholder());
      columnTable.last.add(_Weight.total(this));
    } else {
      columnTable.add([_Weight.total(this)]);
    }
    return columnTable;
  }

  List<List<List<_PdfWidget>>> toWidgetTables(bool compact) =>
      toColumnTable(compact).toRowMajor().splitIntoTables();
}

extension on GearCategoryWithItems {
  List<_PdfWidget> toWidgets(bool compact, int maxItems) => [
        Category(gearCategory.name),
        ...selectedItems.map(_Item.new),
        if (!compact) ...[
          for (var i = selectedItems.length; i < maxItems; i++) _Placeholder(),
        ],
        _Weight(selectedItems),
      ];
}

extension on List<List<_PdfWidget>> {
  List<List<_PdfWidget>> toRowMajor() {
    final rowTable = <List<_PdfWidget>>[];
    final rowCount = map((column) => column.length).maxOrNull ?? 0;
    for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      final row = <_PdfWidget>[];
      for (final column in this) {
        final item =
            rowIndex < column.length ? column[rowIndex] : _Placeholder();
        row.add(item);
      }
      for (var itemCount = row.length % _columnsPerPage;
          itemCount < _columnsPerPage;
          itemCount++) {
        row.add(_Placeholder());
      }
      rowTable.add(row);
    }
    return rowTable;
  }

  List<List<List<_PdfWidget>>> splitIntoTables() {
    final columns = map((row) => row.length).maxOrNull ?? 0;
    assert(columns % _columnsPerPage == 0);
    final pageCount = columns ~/ _columnsPerPage;
    final pages = <List<List<_PdfWidget>>>[];
    for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      final startColumnIndex = pageIndex * _columnsPerPage;
      final endColumnIndex = (pageIndex + 1) * _columnsPerPage;

      final page = <List<_PdfWidget>>[];
      for (final row in this) {
        page.add(row.getRange(startColumnIndex, endColumnIndex).toList());
      }
      pages.add(page);
    }
    return pages;
  }
}

class PdfTable {
  PdfTable(this.categoriesWithItems);

  List<GearCategoryWithItems> categoriesWithItems;

  pdf.Document _toPdfDocument(bool compact) {
    final tables = categoriesWithItems
        .where((c) => c.selectedItems.isNotEmpty)
        .toList()
        .toWidgetTables(compact);

    final document = pdf.Document();
    for (final table in tables) {
      document.addPage(
        pdf.Page(
          theme: pdf.ThemeData(
            softWrap: false,
            overflow: pdf.TextOverflow.clip,
            defaultTextStyle: const pdf.TextStyle(fontSize: 10),
          ),
          pageFormat: PdfPageFormat.a4,
          orientation: pdf.PageOrientation.landscape,
          margin: const pdf.EdgeInsets.fromLTRB(15 - 2 * _space, 15, 15, 15),
          build: (context) => pdf.Table(
            defaultColumnWidth: const pdf.FlexColumnWidth(),
            children: [
              for (final row in table)
                pdf.TableRow(children: row.map((w) => w.sizedWidget).toList()),
            ],
          ),
        ),
      );
    }
    return document;
  }

  Future<void> exportAsPdf({required bool compact}) async {
    final pdf = _toPdfDocument(compact);
    await writeFileBytes(await pdf.save(), "gear_list.pdf");
  }
}
