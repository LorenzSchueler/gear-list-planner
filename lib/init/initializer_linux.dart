import 'package:gear_list_planner/init/initializer_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class InitializerLinux implements Initializer {
  @override
  void enableWarnOnClose() {}

  @override
  void setSqfliteFactory() {
    databaseFactory = databaseFactoryFfi;
  }
}

final initializerImpl = InitializerLinux();
