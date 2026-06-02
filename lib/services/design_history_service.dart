import 'package:designwear/models/models.dart';

class DesignHistoryService {
  final List<CustomDesign> _history = [];
  int _currentIndex = -1;
  static const int maxHistorySize = 50;

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }

  void addToHistory(CustomDesign design) {
    // Remove any history after current index (when user makes new changes after undo)
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Add new design to history
    _history.add(design);
    _currentIndex = _history.length - 1;

    // Limit history size
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  CustomDesign? undo() {
    if (canUndo) {
      _currentIndex--;
      return _history[_currentIndex];
    }
    return null;
  }

  CustomDesign? redo() {
    if (canRedo) {
      _currentIndex++;
      return _history[_currentIndex];
    }
    return null;
  }

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  CustomDesign? get currentDesign {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      return _history[_currentIndex];
    }
    return null;
  }

  int get historyLength => _history.length;
  int get currentPosition => _currentIndex + 1;
}
