///
/// Samsung class
///
/// Instantiate this class to monitor and control Samsung TVs.
///
/// Known Issues:
///  1) I have found no way to determine the current source/input on the TV
///     (e.g. HDMI1, HDMI2, ...).
///  2) The KEY_HDMI1, KEY_HDMI2, KEY_HDMI3, KEY_HDMI4 keys do not select the
///    expected HDMI input.  However, KEY_HDMI does cycle through the HDMI inputs,
///    as well as TV+ (on my TV).
///  3) HDMI selection might be doable using a sequence of keys
///     (home, then right, then right...).
///  4) Only supports the newer TVs that support WebSocket API.
///  5) Power state is checked by trying to http get to a known open port on then
///     TVs.  If there's a HOSTUNREACH or timeout error, the TV is off.
///
import 'package:statefulemitter/statefulemitter.dart';
import 'package:debug/debug.dart';
import 'package:modus_json/modus_json.dart';
import 'package:dio/dio.dart';
import 'package:wake_on_lan/wake_on_lan.dart';
import 'dart:io';
import 'dart:convert';

class Samsung extends StatefulEmitter {
  late final String _appName;
  late final String _appName_base64;
  late final String _tvHostname;
  late final String _macAddress;
  late final String _powerKey;
  final powerPort = 9110; // known open ports 9110, 9119, 9197
  late int _timeout;
  ///
  String? token;
  late final String _controlUrl;

  final debug = Debug('Samsung');

  /// Constructor
  Samsung(config) {
    debug('config $config');
    _appName = config['appName'] ?? 'robodomo-samsung';
    _appName_base64 = base64.encode(utf8.encode(_appName));
    _tvHostname = config['device'];
    _macAddress = config['macAddress'];
    _powerKey = config['powerKey'] ?? 'KEY_POWER';
    _timeout = config['timeout'] ?? 4000;
    _controlUrl =
        'ws://$_tvHostname:8001/api/v2/channels/samsung.remote.control?name=$_appName_base64';
  }

  Future<bool> wake() async {
    var address = '192.168.255.255'; // broadcast address
    if (MACAddress.validate(_macAddress) == false) {
      print('Samsung::wake() invalid mac');
      return false;
    }
    if (IPv4Address.validate(address) == false) {
      print('Samsung::wake() invalid ip');
      return false;
    }

    final ip = IPv4Address.from(address);
    final mac = MACAddress.from(_macAddress);
    await WakeOnLAN.from(ip, mac, port: 9).wake();
    return true;
  }

  Future<void> send(command) async {
    final url = token != null ? '${_controlUrl}&token=$token' : _controlUrl;

    final ws = await WebSocket.connect(url);
    ws.listen((e) async {
      ws.add(command);
      emit('message', e);
    }, onDone: () => print('done'), onError: (err) => print('err $err'));
  }

  Future<void> sendKey(key) async {
    final packet = JSON.stringify({
      "method": "ms.remote.control",
      "params": {
        "Cmd": "Click",
        "DataOfCmd": key,
        "Option": "false",
        "TypeOfRemote": "SendRemoteKey"
      }
    });

    print('packet ${packet}');
    await send(packet);
  }

  Future<void> setPower(bool on) async {
    if (on) {
      await wake();
    } else {
      await sendKey(_powerKey);
    }
  }

  Future<bool> getPowerState() async {
    try {
      final url = 'http://$_tvHostname:$powerPort';
      BaseOptions options = new BaseOptions(connectTimeout: _timeout);
      final dio = Dio(options);
      final Response response = await dio.get(url);
      return true;
    } on DioError catch (e) {
      if (e.type == DioErrorType.connectTimeout) {
        return false;
      }
      if (e.error.osError.message == 'Connection refused') {
        return true;
      }
      debug('error ${e.error.osError.message}');
      return false;
    } catch (e) {
      print('exception ${e}');
      return false;
    }
  }

  Future<Map<String, dynamic>> getHostInfo() async {
    final url = 'http://$_tvHostname:8001/api/v2/';
    BaseOptions options = new BaseOptions(connectTimeout: 1000);
    final dio = Dio(options);
    final Response response = await dio.get(url);
    return response.data;
  }
}
