import 'package:gear_list_planner/init/initializer_interface.dart';

class InitializerStub implements Initializer {
  @override
  void enableWarnOnClose() {
    throw Exception("Stub implementation");
  }

  @override
  void setSqfliteFactory() {
    throw Exception("Stub implementation");
  }
}

final initializerImpl = InitializerStub();
