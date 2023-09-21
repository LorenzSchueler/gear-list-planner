import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

Future<void> writeFile(String data, String filename) async {
  AnchorElement()
    ..href = Uri.dataFromString(
      data,
      mimeType: "application/json",
      encoding: Encoding.getByName("utf-8"),
    ).toString()
    ..style.display = "none"
    ..download = filename
    ..click();
}

Future<void> writeFileBytes(Uint8List data, String filename) async {
  AnchorElement()
    ..href = Uri.dataFromBytes(
      data,
      mimeType: "application/pdf",
    ).toString()
    ..style.display = "none"
    ..download = filename
    ..click();
}
