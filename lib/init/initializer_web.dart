// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:gear_list_planner/init/initializer_interface.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class InitializerWeb implements Initializer {
  @override
  void enableWarnOnClose() {
    html.window.onBeforeUnload.listen((event) {
      if (event is html.BeforeUnloadEvent) {
        event
          ..preventDefault()
          ..returnValue = "do not close";
      }
    });
  }

  @override
  void setSqfliteFactory() {
    databaseFactory = databaseFactoryFfiWeb;
  }
}

final initializerImpl = InitializerWeb();
