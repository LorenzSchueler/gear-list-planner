import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:gear_list_planner/file_manager/file_manager_interface.dart';

class FileManagerLinux implements FileManager {
  @override
  Future<String?> writeFile(String data, String? file) async {
    final path =
        file ?? await FilePicker.platform.saveFile(fileName: "gear_list.json");
    if (path != null) {
      await File(path).writeAsString(data, flush: true);
    }
    return path;
  }

  @override
  Future<String?> writeFileBytes(Uint8List data, String? file) async {
    final path =
        file ?? await FilePicker.platform.saveFile(fileName: "gear_list.pdf");
    if (path != null) {
      await File(path).writeAsBytes(data, flush: true);
    }
    return path;
  }
}

final fileManagerImpl = FileManagerLinux();
