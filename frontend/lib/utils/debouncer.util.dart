import 'dart:async';

import 'package:flutter/foundation.dart';

class Debouncer {
  Debouncer({required this._delay});

  final Duration _delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(_delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
