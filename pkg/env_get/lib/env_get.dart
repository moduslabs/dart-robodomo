// @dart=2.12
library Env;

import 'dart:io' show Platform;

class Env {
  static String? get(String key) {
    Map<String, String> _envVars = Platform.environment;

    return _envVars[key];
  }

  static void dump() {
    Map<String, String> _envVars = Platform.environment;
    _envVars.forEach((k, v) {
      print('key($k) v($v)');
    });

  }
}
