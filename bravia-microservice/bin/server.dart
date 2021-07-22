// @dart=2.12
import 'dart:io';
import 'package:bravia/bravia.dart';
import 'package:debug/debug.dart';
import 'package:hostbase/hostbase.dart';
import 'package:modus_mqtt/modus_mqtt.dart';
import 'package:collection/equality.dart';

final MQTT_HOST = 'nuc1';
//const POLL_TIME = 500;
const POLL_TIME = 15;

class BraviaHost extends HostBase {
  final debug = Debug('BraviaHost');

  late final Bravia _bravia;
  late final _host;
  final _apps = {};
  final _codes = {};
  final _commandQueue = [];
  final _inputs = {};
  late final _tv;

  BraviaHost(Map<String, dynamic> tv, String? device)
      : super(MQTT_HOST, 'bravia/${tv["device"]}', false) {
    _tv = tv;
    _host = device != null ? device : tv['device'];
    _bravia = Bravia(_host);
    debug('New BraviaHost($_host)');
    run();
  }

  bool _running = false;
  Future<void> commandRunner(String command) async {
    _commandQueue.add(command);
    try {
      if (state['codesMap']['POWERON'] != null || _running) {
        return;
      }
    } catch (e) {
      return;
    }
    _running = true;
    while (_running) {
      while (_commandQueue.length > 0) {
        final cmd = _commandQueue.removeAt(0);
        final mapped = state['codesMap'][cmd];
      }
      HostBase.usleep(500);
    }
  }

  @override
  Future<void> command(cmd, arg) async {
    cmd = cmd.toUpperCase();
    debug('command $cmd($arg)');
    if (cmd.startsWith('LAUNCH-')) {
      await this.launchApplication(cmd.substring(7));
    } else if (cmd == 'SPEAKERS') {
      try {
        await _bravia.audio.invoke('setSoundSettintgs', params: [
          {
            "settings": [
              {"value": 'speaker', "target": 'outputTerminal'}
            ]
          }
        ]);
      } catch (e) {
        print('command exception $e');
      }
    } else if (cmd == 'AUDIOSYSTEM') {
      try {
        await _bravia.audio.invoke('setSoundSettintgs', params: [
          {
            "settings": [
              {"value": 'audioSystem', "target": 'outputTerminal'}
            ]
          }
        ]);
      } catch (e) {
        print('command exception $e');
      }
    } else if (cmd == 'POWERON') {
      commandRunner('WakeUp');
    }
    final mapped = state['codesMap'][cmd];
    switch (mangle(mapped)) {
      case 'HDMI1':
        this.state = {'input': 'HDMI 1'};
        break;
      case 'HDMI2':
        this.state = {'input': 'HDMI 2'};
        break;
      case 'HDMI3':
      case 'HDMI3(EARC)':
        this.state = {'input': 'HDMI 3'};
        break;
      case 'HDMI4':
        this.state = {'input': 'HDMI 4'};
        break;
    }
    commandRunner(mapped);
  }

  pollCodes() async {
    if (_codes['codesMap'] == null) {
      final codesList = await _bravia.getIRCCCodes();
      final codesMap = {};
      for (final code in codesList) {
        final name = code['name'].toUpperCase();
        codesMap[name] = code['name'];
        codesMap['POWERON'] = 'WakeUp';
      }
      state = {
        "codes": codesList,
        "codesList": codesList,
        "codesMap": codesMap,
      };
    }
  }

  var _lastVolume;
  pollVolume() async {
    final vol = await _bravia.audio.invoke('getVolumeInformation');
    final volume = vol;
    if (!DeepCollectionEquality().equals(volume, _lastVolume)) {
      state = {"volume": volume};
    }
    _lastVolume = volume;
    final newState = {};
//    debug('$_host volume $volume');
  }

  pollPower() async {
    final power = await _bravia.system.invoke('getPowerStatus');
    state = {"power": power[0]['status'] == 'active'};
  }

  pollInput() async {
    try {
      final info =
          await _bravia.avContent.invoke('getPlayingContentInfo') ?? {};
      if (info['error'] != null) {
        final input = info[0];
        state = {"input": "HDMI 1"};
      } else {
        state = {"input": info['title']};
      }
    } catch (e) {
      state = {"input": "HDMI 1"};
    }
  }

  pollApplicationList() async {
    if (_apps['appsMap'] == null) {
      final appsList = await _bravia.appControl.invoke('getApplicationList');
      final appsMap = {};

      for (final app in appsList[0]) {
        final title = app['title'];
        appsMap[app['title'].toLowerCase()] = app;
      }

      state = {"appsMap": appsMap, "appsList": appsList};
      _apps["appsMap"] = appsMap;
      _apps["appsList"] = appsList;
    }
    return _apps["appsMap"];
  }

  Future<void> launchApplication(String title) async {
    await pollApplicationList();
    title = title.toLowerCase();
    final app = state['appsMap'];
    print("$_host launch app $app");
  }

  pollPlayingContentInfo() async {
    final info = await _bravia.avContent.invoke('getPlayingContentInfo');
//    debug('$_host playingContentInfo ${info}');
    return info;
  }

  pollSpeakers() async {
    final info = await _bravia.audio
        .invoke('getSoundSettings', version: '1.1', params: {});
//    debug('$_host speakers ${info[0]}');
    state = {"speakers": info[0]};
    return info[0];
  }

  @override
  Future<Never> run() async {
    var lastVolume = null;

    for (;;) {
      try {
        await pollSpeakers();
        await pollCodes();
        await pollApplicationList();
        await pollPower();
        await pollInput();
        await pollVolume();
        await pollPlayingContentInfo();
        await HostBase.sleep(POLL_TIME);
      } catch (e) {
        print("Exception run($e)");
      }
    }
  }
}

Future<Never> main(List<String> arguments) async {
  await MQTT.connect();
  final config = await HostBase.getSetting('config') ?? {};
  final tvs = config['bravia']['tvs'];
  final hosts = [];
  for (var tv in tvs) {
    final hostname = tv['device'] + config['domain'];
//    print('hostname $hostname');
    final host = BraviaHost(tv, hostname);
    print('add host ${tv["name"]}');
    hosts.add(host);
  }
  for (;;) {
    await HostBase.sleep(120);
  }
}
