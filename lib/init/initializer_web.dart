import 'dart:js_interop';

import 'package:gear_list_planner/init/initializer_interface.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:web/web.dart' as web;

class InitializerWeb implements Initializer {
  @override
  void enableWarnOnClose() {
    web.window.onbeforeunload = ((JSAny event) {
      if (event.isA<web.BeforeUnloadEvent>()) {
        (event as web.BeforeUnloadEvent)
          ..preventDefault()
          ..returnValue = "do not close";
      }
    }).toJS;
  }

  @override
  void setSqfliteFactory() {
    databaseFactory = databaseFactoryFfiWeb;
  }
}

final initializerImpl = InitializerWeb();
