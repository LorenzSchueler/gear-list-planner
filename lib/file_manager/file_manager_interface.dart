import 'dart:typed_data';

abstract class FileManager {
  Future<String?> writeFile(String data, String? file);

  Future<String?> writeFileBytes(Uint8List data, String? file);
}
