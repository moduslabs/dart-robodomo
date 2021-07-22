// @dart=2.12

// import 'dart:io';
import 'package:env_get/env_get.dart';
import 'package:modus_mqtt/modus_mqtt.dart';
import 'package:myq/myq.dart';
import 'package:debug/debug.dart';
import 'package:hostbase/hostbase.dart';

final debug = Debug('MyQHost');

final MQTT_HOST = Env.get('MQTT_HOST') ?? 'nuc1',
    TOPIC_ROOT = Env.get('TOPIC_ROOT') ?? 'myq';

final EMAIL = Env.get('MYQ_EMAIL') ?? '',
    PASSWORD = Env.get('MYQ_PASSWORD') ?? '';

const POLL_TIME = 2 * 1000;

class MyQHost extends HostBase {
  // late Map<String, dynamic> _device;
  late String _name, _type, _serialNumber;
  bool _lowBatteryState = false;
  var _account;

  MyQHost(device) : super(MQTT_HOST, '$TOPIC_ROOT/${device['name']}', false) {
    //
    // _device = device;
    _name = device['name'];
    _type = device['device_family'];
    _serialNumber = device['serial_number'];

    debug('MyQHost: device $_name $_type $_serialNumber');
    run();
  }

  bool _isOpen() {
    final door_state = state['door_state'];
    try {
      return (door_state == true || door_state.toLowerCase() == 'open');
    } catch (e) {
      return false;
    }
  }

  bool _isClosed() {
    final door_state = state['door_state'];
    try {
      return (door_state == false || door_state.toLowerCase() == 'closed');
    } catch (e) {
      return true;
    }
  }

  bool _isOn() {
    final light_state = state['light_state'];
    try {
      return (light_state == true || light_state.toLowerCase() == 'on');
    } catch (e) {
      return false;
    }
  }

  bool _isOff() {
    final light_state = state['light_state'];
    try {
      return (light_state == false || light_state.toLowerCase() == 'off');
    } catch (e) {
      return false;
    }
  }
  /// run()
  /// Forever login, then poll device status
  @override
  Future<Never> run() async {
    for (;;) {
      // keep reconnecting on failure
      final account = MyQ();
      _account = account;
      try {
        final login = await account.login(EMAIL, PASSWORD);
        if (login['code'] != 'OK') {
          print('$_name login failed $login');
          continue;
        }
        print('$_name login succeeded');
      } catch (e) {
        continue;
      }
      // poll
      for (;;) {
        try {
          final result = await account.getDevice(_serialNumber);
          if (result['code'] == 'OK') {
            final device = result['device'], newState = device['state'];

            // this generates warning, but we need to pass this style Map to setState!
            // final Map<String, dynamic> s = {};
            final Map<String, dynamic>s = {};
            newState.keys.forEach((key) {
              if (key != 'physical_devices') {
                s[key] = newState[key];
              }
              switch (key) {
                case 'dps_low_battery_mode':
                  _lowBatteryState = newState[key];
                  s['lowBatteryState'] = _lowBatteryState;
                  break;
                case 'door_state':
                  s['door_state'] = newState[key];
                  break;
                case 'light_state':
                  s['light_state'] = newState[key];
                  break;
              }
              // print('newState $key ${newState[key]}');
            });
            setState(s);
          }
        } catch (e, st) {
          print('$_name getDevice Exception $e');
          print(st);
        }
        await HostBase.wait(POLL_TIME);
      }
    }
  }

  @override
  Future<void> command(cmd, args) async {
    try {
      if (cmd.toUpperCase() == 'DOOR') {
        if (args == 'OPEN') {
          if (_isClosed()) {
            debug('open garage door door ($_name)');
            await _account.setDoorState(_serialNumber, 'OPEN');
          }
        } else if (args == 'CLOSE') {
          if (_isOpen()) {
            debug('close garage door door ($_name)');
            await _account.setDoorState(_serialNumber, 'CLOSE');
          }
        } else {
          print('illegal command "$cmd');
        }
      } else if (cmd.toUpperCase() == 'LIGHT') {
        if (args == 'ON') {
          if (_isOff()) {
            debug('Turn on light for door ($_name)');
            await _account.setLightState(_serialNumber, 'ON');
          }
        } else if (args == 'OFF') {
          if (_isOn()) {
            debug('Turn off light for door ($_name)');
            await _account.setLightState(_serialNumber, 'OFF');
          }
        } else {
          print('illegal command "$cmd');
        }
      }
    } catch (e) {
      print('$_name command exception $e');
    }
  }
}

Future<Never> main(List<String> arguments) async {
  final hosts = [];

  await MQTT.connect();

  final account = MyQ();
  for (;;) {
    final loggedIn = await account.login(EMAIL, PASSWORD);
    if (loggedIn['code'] != 'OK') {
      print('login failed ${loggedIn['code']}');
    } else {
      print('login succeeded');
      break;
    }
    await HostBase.sleep(1);
  }
  for (;;) {
    try {
      final devices = await account.getDevices();

      if (devices['devices'] != null) {
        devices['devices'].forEach((device) {
          final host = MyQHost(device);
          hosts.add(host);
        });
        break;
      } else {
        print('device error  ${devices['code']}');
      }
    } catch (e) {
      //
    }
  }

  for (;;) {
    await HostBase.sleep(120);
  }
}
