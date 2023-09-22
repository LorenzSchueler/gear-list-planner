import 'dart:math';

import 'package:collection/collection.dart';
import 'package:gear_list_planner/data_provider.dart';
import 'package:gear_list_planner/model.dart';
import 'package:gear_list_planner/write_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;

class PdfTable {
  PdfTable(List<GearCategoryWithItems> categoriesWithItems)
      : categoriesWithItems = categoriesWithItems
            .where((c) => c.selectedItems.isNotEmpty)
            .toList();

  List<GearCategoryWithItems> categoriesWithItems;

  final pdf.Widget _spacer = pdf.SizedBox(width: 10);

  pdf.Widget _category(String name) {
    return pdf.Row(
      children: [
        _spacer,
        pdf.Text(
          name,
          style: pdf.TextStyle(fontWeight: pdf.FontWeight.bold),
        ),
      ],
    );
  }

  pdf.Widget _weight(List<(GearListItem, GearItem)> items) {
    final weight = items.map((item) => item.$1.count * item.$2.weight).sum;
    return pdf.Row(
      mainAxisAlignment: pdf.MainAxisAlignment.end,
      children: [
        _spacer,
        pdf.Text(
          "${weight.inKg} kg",
          style: pdf.TextStyle(fontWeight: pdf.FontWeight.bold),
        ),
      ],
    );
  }

  pdf.Widget _item((GearListItem, GearItem) combinedItem) {
    final (listItem, item) = combinedItem;
    return pdf.Row(
      children: [
        _spacer,
        pdf.Checkbox(value: false, name: "_"),
        _spacer,
        pdf.Text(listItem.count.toString()),
        _spacer,
        pdf.Expanded(
          child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text(item.type),
              pdf.Text(
                item.name,
                style: const pdf.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        _spacer,
        pdf.Text(item.weight.toString()),
      ],
    );
  }

  pdf.Document _toPdfDocument() {
    const columnsPerPage = 5;
    final pages = (categoriesWithItems.length / columnsPerPage).ceil();
    final rows = categoriesWithItems
            .map((categoryWithItems) => categoryWithItems.selectedItems.length)
            .maxOrNull ??
        0;

    final document = pdf.Document();
    for (var page = 0; page < pages; page++) {
      final filteredCategoriesWithItems = categoriesWithItems.getRange(
        page * columnsPerPage,
        min((page + 1) * columnsPerPage, categoriesWithItems.length),
      );
      final columns = filteredCategoriesWithItems.length;
      document.addPage(
        pdf.Page(
          theme: pdf.ThemeData(
            softWrap: false,
            overflow: pdf.TextOverflow.clip,
          ),
          pageFormat: PdfPageFormat.a4,
          orientation: pdf.PageOrientation.landscape,
          margin: const pdf.EdgeInsets.fromLTRB(5, 15, 15, 15),
          build: (context) => pdf.Table(
            defaultColumnWidth: const pdf.FlexColumnWidth(),
            children: [
              pdf.TableRow(
                children: [
                  for (final categoryWithItems in filteredCategoriesWithItems)
                    _category(categoryWithItems.gearCategory.name),
                  for (var ph = 0; ph < columnsPerPage - columns; ph++)
                    pdf.Container(),
                ],
              ),
              for (var row = 0; row < rows; row++)
                pdf.TableRow(
                  children: [
                    for (final categoryWithItems in filteredCategoriesWithItems)
                      row < categoryWithItems.selectedItems.length
                          ? _item(categoryWithItems.selectedItems[row])
                          : pdf.Container(),
                  ],
                ),
              pdf.TableRow(
                children: [
                  for (final categoryWithItems in filteredCategoriesWithItems)
                    _weight(categoryWithItems.selectedItems),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return document;
  }

  Future<void> exportAsPdf() async {
    final pdf = _toPdfDocument();
    await writeFileBytes(await pdf.save(), "gear_list.pdf");
  }
}
