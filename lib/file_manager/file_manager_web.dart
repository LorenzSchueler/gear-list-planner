import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

import 'package:gear_list_planner/file_manager/file_manager_interface.dart';

class FileManagerWeb implements FileManager {
  @override
  Future<String?> writeFile(String data, String? file) async {
    final filename = file ?? "gear_list.json";
    AnchorElement()
      ..href = Uri.dataFromString(
        data,
        mimeType: "application/json",
        encoding: Encoding.getByName("utf-8"),
      ).toString()
      ..style.display = "none"
      ..download = filename
      ..click();
    return filename;
  }

  @override
  Future<String?> writeFileBytes(Uint8List data, String? file) async {
    final filename = file ?? "gear_list.pdf";
    AnchorElement()
      ..href = Uri.dataFromBytes(
        data,
        mimeType: "application/pdf",
      ).toString()
      ..style.display = "none"
      ..download = filename
      ..click();
    return filename;
  }
}

final fileManagerImpl = FileManagerWeb();
