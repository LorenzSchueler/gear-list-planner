import 'package:flutter/foundation.dart';

class BoolToggle extends ChangeNotifier {
  BoolToggle.on() : _state = true;
  BoolToggle.off() : _state = false;

  bool _state;
  bool get isOn => _state;
  bool get isOff => !_state;

  void setState(bool? newState) {
    if (newState != null) {
      _state = newState;
      notifyListeners();
    }
  }

  void toggle() => setState(!_state);
}
