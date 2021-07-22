// @dart=2.12

library json;

import 'dart:convert';

class json {
  final jsonEncoder = JsonEncoder();
  final jsonDecoder = JsonDecoder();
  String stringify(o) {
    return jsonEncoder.convert(o);
  }
  Map<String, dynamic>? parse(String s) {
    return jsonDecoder.convert(s);
  }
}

json JSON = json();

