import 'dart:async';
import 'dart:ui';

class Throttle {
  static final Map<String, Timer> _timers = {};

  static void throttle({
    required String tag,
    Duration duration = const Duration(seconds: 1),
    required VoidCallback func,
  }) {
    if (_timers[tag] != null) {
      return;
    } else {
      func();
      _timers[tag] = Timer(duration, () {
        _timers[tag]?.cancel();
        _timers.remove(tag);
      });
    }
  }

  static void future({
    required String tag,
    Duration timeout = const Duration(seconds: 20),
    required Future future,
  }) {
    if (_timers[tag] != null) {
      return;
    } else {
      future.whenComplete(() {
        cancel(tag);
      });
      _timers[tag] = Timer(timeout, () {
        _timers[tag]?.cancel();
        _timers.remove(tag);
      });
    }
  }

  static void cancel(String tag) {
    _timers[tag]?.cancel();
    _timers.remove(tag);
  }

  static int count() {
    return _timers.length;
  }
}
