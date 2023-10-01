import 'package:gear_list_planner/file_manager/file_manager_interface.dart';
import 'package:gear_list_planner/file_manager/file_manager_stub.dart'
    if (dart.library.html) 'package:gear_list_planner/file_manager/file_manager_web.dart'
    if (dart.library.io) 'package:gear_list_planner/file_manager/file_manager_linux.dart';

FileManager fileManager = fileManagerImpl;
