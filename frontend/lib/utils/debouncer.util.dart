import 'dart:async';

import 'package:flutter/foundation.dart';

class Debouncer {
  Debouncer({required this.delay});

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
