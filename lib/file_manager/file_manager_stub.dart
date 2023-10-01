import 'dart:typed_data';

import 'package:gear_list_planner/file_manager/file_manager_interface.dart';

class FileManagerStub implements FileManager {
  @override
  Future<String?> writeFile(String data, String? file) {
    throw Exception("Stub implementation");
  }

  @override
  Future<String?> writeFileBytes(Uint8List data, String? file) {
    throw Exception("Stub implementation");
  }
}

final fileManagerImpl = FileManagerStub();
