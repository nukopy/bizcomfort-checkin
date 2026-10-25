import 'package:flutter/foundation.dart';

class UnlockTrace extends ChangeNotifier {
  List<String> _lines = <String>[];

  List<String> get lines => List<String>.unmodifiable(_lines);

  void add(String line) {
    if (_lines.isNotEmpty && _lines.last == line) {
      return;
    }
    _lines = <String>[..._lines, line];
    notifyListeners();
  }

  void reset() {
    if (_lines.isEmpty) {
      return;
    }
    _lines = <String>[];
    notifyListeners();
  }
}
