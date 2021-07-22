///
/// HostBase class
///
/// Abstract class for implementing server side "hosts".  A host monitors and/or controls a single device, such as a TV (you might have multiple TVs in the home/office).
///
/// The run()

// @dart=2.12

library HostBase;

import 'package:collection/equality.dart';
import "dart:io";
import 'package:mongo_dart/mongo_dart.dart';
import 'package:statefulemitter/statefulemitter.dart';
import 'package:debug/debug.dart';
import 'package:env_get/env_get.dart';
import 'package:modus_mqtt/modus_mqtt.dart';
import 'package:modus_json/modus_json.dart';

final debug = Debug('HostBase');

abstract class HostBase extends StatefulEmitter {
  var retain = false;
  String? host, topic;
  bool? custom;
  late String _setRoot, _statusRoot;
  late int _setRootLength;

  HostBase(String host, String topic, bool custom) {
    retain = true;
    this.host = host;
    this.topic = topic;
    this.custom = custom;
    _setRoot = topic + "/set";
    _setRootLength = _setRoot.length;
    _statusRoot = topic + "/status";

    //
    MQTT.on('message', null, (evt, ctx) async {
      final e = evt.eventData as Map<String, String>;
      final topic = e['topic'] ?? 'no topic';
      final message = e['message'] ?? 'no message';
      if (topic.substring(0, _setRootLength) == _setRoot) {
        evt.handled = true;
        if (message.indexOf("__RESTART__") != -1) {
          MQTT.publish(topic, null, retain: true);
          MQTT.publish(topic, null, retain: false);
          exit(0);
        }
        final command = topic.substring(_setRootLength + 1);
        await this.command(command.toUpperCase(), message);
      }
    });

    MQTT.subscribe("${_setRoot}/#", null);

    this.on("statechange", null, (ev, context) {
      try {
        Map<dynamic, dynamic> oldState = ev.eventData as Map<dynamic, dynamic>,
            newState = state;

        bool save = retain;
        newState.keys.forEach((k) {
          // ignore mongodb's generated _id field
          if (!DeepCollectionEquality().equals(oldState[k], newState[k])) {
            state[k] = newState[k];
            publish(k, newState[k]);
//            if (k == 'input') {
//              print('$topic old $k ${oldState[k]}');
//              print('$topic new $k ${newState[k]}');
//            }
          }
        });
        retain = save;
      } catch (e, trace) {
        print('statechange exception $e $trace');
      }
    });
  }

  ///
  /// abstract (async) function run().  In your child class, you override this and implement the guts of your polling/WebSocket monitoring, etc.
  ///
  Future<Never> run();

  ///
  /// abstract (async) function command(command, args) is called when a command is received via MQTT.
  ///
  /// The HostBase class subscribes to $topic/set/# and passes the value of # as cmd and the message as args.
  ///
  /// The RESET command is handled automatically (program exits so something like forever will restart it).
  ///
  Future<void> command(cmd, args);

  ///
  /// General purpose async static wait(milliseconds) functions.
  ///
  /// If you want to wait in a loop inside an async function, you can call this.
  ///
  static Future<void> wait(int microseconds) =>
      Future<void>.delayed(Duration(microseconds: microseconds));

  ///
  /// General purpose async static wait(milliseconds) functions.
  ///
  /// If you want to wait in a loop inside an async function, you can call this.
  ///
  static Future<void> usleep(int microseconds) =>
      Future<void>.delayed(Duration(microseconds: microseconds));

  ///
  /// General purpose async static wait(seconds) functions.
  ///
  /// If you want to wait in a loop inside an async function, you can call this.
  ///
  static Future<void> sleep(int seconds) =>
      Future<void>.delayed(Duration(seconds: seconds));

  ///
  /// publish(key, value)
  ///
  /// publishes to topic $topic/status/$key, message is value.
  ///
  /// if value is an object, it is converted as JSON before sending.
  ///
  void publish(String key, value) {
    final t = '${_statusRoot}/${key}';
    if (value is bool) {
      MQTT.publish(t, value);
      return;
    }
    final String val = value is String ? value : JSON.stringify(value);

    // debug("publish ${t} >>> ${val}");
    MQTT.publish(t, val);
  }

  static Never abort(String s) {
    print("");
    print('***ABORT!!!');
    print(s);
    exit(1);
  }

  ///
  /// var settings = await getSetting(String key);
  ///
  /// Fetches the setting identified by key from the MongoDB.
  ///
  /// Caller must JSON.parse() it if it is expected to be an Object/Map.
  ///
  static Future<Map<String, dynamic>>? getSetting(String? setting) async {
    if (setting == null) {
      return {};
    }
    var host = Env.get('MONGODB_HOST');
    if (host == null) {
      debug('getSetting: no MONGODB_HOST');
      host = 'nuc1';
    }
    if (host.contains('mongodb:')) {
      host += ':27017/settings';
    } else {
      host = 'mongodb://${host}:27017/settings';
    }
    final db = Db(host);
    await db.open();
    final collection = await db.collection('config');
    final s = await collection.findOne({"_id": setting}) ?? {};
    await db.close();
    return Future.value(s);
  }
}
