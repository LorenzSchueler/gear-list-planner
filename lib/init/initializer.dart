import 'package:gear_list_planner/init/initializer_interface.dart';
import 'package:gear_list_planner/init/initializer_stub.dart'
    if (dart.library.html) 'package:gear_list_planner/init/initializer_web.dart'
    if (dart.library.io) 'package:gear_list_planner/init/initializer_linux.dart';

Initializer initializer = initializerImpl;
