///
/// samsung-microservice
///
/// RoboDomo microservice to monitor and control Samsung TVs.
///

// @dart=2.12

import 'dart:io';
import 'dart:io' show Platform;
import 'package:samsung/samsung.dart';
import 'package:debug/debug.dart';
import 'package:hostbase/hostbase.dart';
import 'package:modus_mqtt/modus_mqtt.dart';
import 'package:collection/equality.dart';

final MQTT_HOST = 'nuc1';
const POLL_TIME = 500;

class SamsungHost extends HostBase {
  late final Samsung _samsung;
  final debug = Debug('SamsungHost');
  var _info;
  String? _input;

  SamsungHost(Map<String, dynamic> config)
      : super(MQTT_HOST, 'samsung/${config["device"]}', false) {
    _samsung = Samsung(config);
    _input = config['input'];
    debug('SamsungHost constructor $config');
    run();
  }

  Future<void> _send(key) async {
    return _samsung.sendKey(key);
  }

  Future<Map<String, dynamic>> _getHostInfo() async {
    return _samsung.getHostInfo();
  }

  @override
  Future<void> command(cmd, dynamic arg) async {
    cmd = arg.toLowerCase();
    switch (cmd) {
      case "hdmi":
        state = {"input": "hdmi1"};
        cmd = "KEY_HDMI";
        break;
      case "return":
        cmd = "KEY_RETURN";
        break;
      case "display":
        cmd = "KEY_INFO";
        break;
      case "home":
        cmd = "KEY_HOME";
        break;
      case "menu":
        cmd = "KEY_MENU";
        break;
      case "wakeup":
      case "poweron":
      case "poweroff":
        _samsung.setPower(!state["power"]);
        return;
      case "volumeup":
        cmd = "KEY_VOLUP";
        break;
      case "volumedown":
        cmd = "KEY_VOLDOWN";
        break;
      case "mute":
        cmd = "KEY_MUTE";
        break;
      case "cursorup":
        cmd = "KEY_UP";
        break;
      case "cursordown":
        cmd = "KEY_DOWN";
        break;
      case "cursorleft":
        cmd = "KEY_LEFT";
        break;
      case "cursorright":
        cmd = "KEY_RIGHT";
        break;
      case "confirm":
        cmd = "KEY_ENTER";
        break;
      case "num0":
        cmd = "KEY_0";
        break;
      case "num1":
        cmd = "KEY_1";
        break;
      case "num2":
        cmd = "KEY_2";
        break;
      case "num3":
        cmd = "KEY_3";
        break;
      case "num4":
        cmd = "KEY_4";
        break;
      case "num5":
        cmd = "KEY_5";
        break;
      case "num6":
        cmd = "KEY_6";
        break;
      case "num7":
        cmd = "KEY_7";
        break;
      case "num8":
        cmd = "KEY_8";
        break;
      case "num9":
        cmd = "KEY_9";
        break;
      case "channelup":
        cmd = "KEY_CHUP";
        break;
      case "channeldown":
        cmd = "KEY_CHDOWN";
        break;
      case "clear":
        cmd = "KEY_CLEAR";
        break;
      case "enter":
        cmd = "KEY_ENTER";
        break;
      default:
        return;
    }
    await _send(cmd);
  }

  @override
  Future<Never> run() async {
    try {
      _info = await _getHostInfo();
      state = {"input": _input, "info": _info};
    } catch (e) {}
    debug('info $_info');
    state = {"input": _input, "power": false};
    for (;;) {
      if (_info == null) {
        try {
          _info = await _getHostInfo();
          debug('info $_info');
          state = {"info": _info};
        } catch (e) {}
      }
      final power = await _samsung.getPowerState();
      state = {"power": power, "input": _input};
      await HostBase.usleep(POLL_TIME * 100);
    }
  }
}

Future<Never> main(List<String> arguments) async {
  await MQTT.connect();
  final config = await HostBase.getSetting('config') ?? {};
  final tvs = config['samsung']['tvs'];
  final hosts = [];
  for (var tv in tvs) {
    final hostname = tv['device'] + config['domain'];
    final host = SamsungHost(tv);
    debug('add host ${tv["name"]}');
    hosts.add(host);
  }
  for (;;) {
    await HostBase.sleep(120);
  }
}
