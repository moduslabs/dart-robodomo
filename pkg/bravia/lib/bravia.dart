/// Bravia class

import 'package:statefulemitter/statefulemitter.dart';
import 'package:debug/debug.dart';
import 'package:modus_json/modus_json.dart';
import 'package:dio/dio.dart';
import 'dart:io';

String mangle(String s) {
  return s.replaceAll(' ', '').toUpperCase();
}

class ServiceProtocol {
  late final Bravia _bravia;
  late final String _protocol;
  final List<dynamic> _methods = [];

  final debug = Debug('Bravia');

  ///
  /// ServiceProtocol
  ///
  /// A ServiceProtocol is just an endpoint/URL for accessing a specific service
  /// in the TV API.
  ///
  /// For example, 'accessControl' URL is http://tv_IP/sony/accessControl.
  ///
  ServiceProtocol(Bravia bravia, String protocol) {
    _bravia = bravia;
    _protocol = protocol;
  }

  ///
  /// final versions = getVersions();
  ///
  /// Returns an array of versions supported by the API, something like ['1.0', '1.1']
  ///
  getVersions() async {
    final versions = await invoke('getVersions');
    return versions[0];
  }

  ///
  /// getMethodTypes(version);
  ///
  /// Each endpoint (and version) has its own distinct methods that can be invoked.  This
  /// method returns a List of method information.
  ///
  getMethodTypes(String? version) async {
    if (_methods.length > 0) {
      if (version != null) {
        return _methods.firstWhere((method) => method['version'] == version);
      } else {
        return _methods;
      }
    }

    var versions = await getVersions();
    var index = 0;
    // local next function
    next(List<dynamic>? results) async {
      if (results != null) {
        Object record = {"version": versions[index - 1], "methods": results};
        _methods.add(record);
      }
      if (index < versions.length) {
        final result = await invoke('getMethodTypes',
            version: '1.0', params: versions[index++]);

        next(result);
      } else if (version != null && _methods.length > 0) {
        return _methods.firstWhere((method) => method['version'] == version);
      } else {
        return _methods;
      }
    }

    next(null);
  }

  ///
  /// invoke(method, version <optional params>);
  ///
  /// Invoke method on the ServiceProtocol URL sending optional params.
  /// The version parameter selects the Sony Bravia TV's API version.
  ///
  invoke(String method, {String version = '1.0', dynamic params}) async {
    params = params != null ? [params] : [];
    final Map<String, dynamic> response = await _bravia.request(_protocol,
        {'id': 3, 'method': method, 'version': version, 'params': params});
    if (response['error'] != null) {
      debug('$method response $response ${response["error"]}');
      return response;
    }
    return response['result'];
  }
}

///
/// Bravia class.
///
/// You can instantiate one of these for each TV to be monitored/controlled.
///
class Bravia extends StatefulEmitter {
  late final String _host, _psk;
  late final _port;
  late final _timeout;
  late final _url;
  var _codes = [];

  // protocols
  late final ServiceProtocol accessControl;
  late final ServiceProtocol appControl;
  late final ServiceProtocol audio;
  late final ServiceProtocol avContent;
  late final ServiceProtocol browser;
  late final ServiceProtocol cec;
  late final ServiceProtocol encryption;
  late final ServiceProtocol guide;
  late final ServiceProtocol recording;
  late final ServiceProtocol system;
  late final ServiceProtocol videoScreen;

  ///
  /// Constructor takes IP address or hostname argument
  ///
  Bravia(String host,
      {int port = 80, String psk = '0000', int timeout = 5000}) {
    if (!host.contains('.')) {
      host += '.';
    }
    _host = host;
    _port = port;
    _psk = psk;
    _timeout = timeout;

    _url = _port != 80 ? 'http://$_host:$_port/sony' : 'http://$_host/sony';

    debug('Construct Bravia $host $psk $timeout $_url');
    accessControl = ServiceProtocol(this, 'accessControl');
    appControl = ServiceProtocol(this, 'appControl');
    audio = ServiceProtocol(this, 'audio');
    avContent = ServiceProtocol(this, 'avContent');
    browser = ServiceProtocol(this, 'browser');
    cec = ServiceProtocol(this, 'cec');
    encryption = ServiceProtocol(this, 'encryption');
    guide = ServiceProtocol(this, 'guide');
    recording = ServiceProtocol(this, 'recording');
    system = ServiceProtocol(this, 'system');
    videoScreen = ServiceProtocol(this, 'videoScreen');
  }

  ///
  /// Object o = request(path, json);
  ///
  /// Send request to path with JSON as post data.  Return JSON parsed result.
  ///
  Future<Map<String, dynamic>> request(String path, dynamic json) async {
    var dio = Dio();
    dio.options.headers['Content-Type'] = 'text/xml; charset=UTF-8';
    dio.options.headers['SOAPACTION'] =
        '"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC"';
    dio.options.headers['X-Auth-PSK'] = _psk;
    final response = await dio.post('$_url/$path', data: JSON.stringify(json));

    return response.data;
  }

  ///
  /// List codes = getIRCCCodes();
  ///
  /// Returns a list of IRCC codes supported by the TV.  IRCC codes are what a remote control (for the TV) app would
  /// send when a button (play, pause, volume up...) is pressed.
  ///
  Future<List<dynamic>> getIRCCCodes() async {
    if (_codes.length <= 0) {
      final result = await system.invoke('getRemoteControllerInfo');
      _codes = result[1];
    }
    return _codes;
  }

  ///
  /// send(code);
  ///
  /// Send IRCC code to TV.  IRCC code is for a remote control button (like play/pause/etc.)
  ///
  Future<void> send(String code) async {
    final codes = await getIRCCCodes();
    final ircc = codes.firstWhere((c) => mangle(c['name']) == mangle(code));
    if (ircc == null) {
      print('IRCC code $code unknown');
      return;
    }
    final body = '''<?xml version="1.0"?>
          <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
              <s:Body>
                  <u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">
                      <IRCCCode>$ircc</IRCCCode>
                  </u:X_SendIRCC>
              </s:Body>
          </s:Envelope>''';

    await request('/IRCC', body);
  }
}
