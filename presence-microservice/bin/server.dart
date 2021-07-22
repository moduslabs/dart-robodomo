/// // @dart=2.9
// @dart=2.12
import 'package:modus_mqtt/modus_mqtt.dart';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;

import 'package:debug/debug.dart';
import 'package:hostbase/hostbase.dart';

final debug = Debug('main');

final MQTT_HOST = 'nuc1';
const POLL_TIME = 5; // in seconds
const FAST_POLL = 1; // in seconds
const TIMEOUT = 15000;

class PresenceHost extends HostBase {
  late String device, person;
  final debug = Debug('PresenceHost');

  PresenceHost(presence)
      : super(MQTT_HOST, "presence/${presence["person"]}", false) {
    //
    device = presence['device'];
    person = presence['person'];
    // debug('Construct PresenceHost $host $_setRoot');
    run();
  }

  @override
  Future<Never> run() async {
    for (;;) {
      // debug('poll $device');
      final Map<String, dynamic> s = {};
      try {
        var dio = Dio();
        dio.options.connectTimeout = TIMEOUT;
        final response = await dio.get('https://$device.');
        debug('response $response');
      } on DioError catch (e) {
        print('DioError, $e');
        
      } catch (e) {
        if (e is String ||
            (e is DioError && e.type == DioErrorType.connectTimeout)) {
          // timeout
          debug('$person away TIMEOUT $TIMEOUT');
          s[person] = false;
          setState(s);
          continue;
        }
        try {
          if (e is DioError) {
            switch (e.error.osError.errorCode) {
              case 121: // no route to host
                debug('$person away');
                s[person] = false;
                setState(s);
                break;
              // case 1225: // connection refused
              // case 10053: // connection aborted
              // case 10054: // connection reset by peer
              default:
                // connection attempted and refused, reset, aborted, etc.
                debug('$person home');
                s[person] = true;
                setState(s);
                break;
            }
          }
        } catch (e) {
          debug('bad $e');
        }
      }

      // if person's phone is present, we don't want to ping it super fast
      // or it might hurt battery life
      final st = state[person];
      if (st == null || st) {
        await HostBase.sleep(POLL_TIME);
      }
    }
  }

  @override
  Future<void> command(cmd, arg) async {
    // presence supports no commands other than restart, which is handled
    // by HostBase
  }
}

void onMessage(String topic, String message) {
  debug('onMessage "$topic" "$message"');
}

Future<int> main() async {
  // final MQTT = Mqtt('nuc1');
  final hosts = [];

  print('Platform ${Platform.isLinux} ${Platform.isWindows}');
  await MQTT.connect();
  var config = await HostBase.getSetting('config') ?? {};
  print('config $config');
  debug('Config ${config["presence"]}');
  for (var person in config['presence']) {
    hosts.add(PresenceHost(person));
  }

  for (;;) {
    await HostBase.sleep(120);
  }
}
