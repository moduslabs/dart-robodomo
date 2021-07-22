// @dart=2.12

library modus_mqtt;

import 'dart:collection';
import 'dart:math';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:debug/debug.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:modus_json/modus_json.dart';
import 'package:statefulemitter/statefulemitter.dart';
import 'package:typed_data/src/typed_buffer.dart';

typedef Callback = Future<void> Function(String topic, String message);

const KEEP_ALIVE = 20;

class Mqtt extends StatefulEmitter {
  final debug = Debug('MQTT');
  final AnsiPen pen = AnsiPen(), redPen = AnsiPen(), bluePen = AnsiPen();
  var client;
  var broker;

  final subscriptions = HashMap<String, List<Callback>>();

  Mqtt(String broker) {
    this.broker = broker;
  }

  Future<void> connect() async {
    client = MqttServerClient(broker, '');

    client.logging(on: false);
    client.keepAlivePeriod = KEEP_ALIVE;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
    client.pongCallback = pong;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .keepAliveFor(
            KEEP_ALIVE) // Must agree with the keep alive set above or not set
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    debug('Mosquitto client connecting....');
    client.connectionMessage = connMess;

    /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
    /// never send malformed messages.
    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      debug('client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      debug('socket exception - $e');
      client.disconnect();
    }

    /// Check we are connected
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      debug('Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      debug(
          'ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      exit(-1);
    }

    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      try {
        final recMess = c[0].payload as MqttPublishMessage;
        var b = recMess.payload.message;
        if (b == null) {
          b = [] as Uint8Buffer;
        }
        final pt = MqttPublishPayload.bytesToStringAsString(b);
        final topic = c[0].topic;

        ansiColorDisabled = false;

        pen
          ..reset()
          ..white(bold: true);
        redPen
          ..reset()
          ..red(bold: true);
        bluePen
          ..reset()
          ..blue(bold: true);

        // pen.black(bold: true)(
        final hl = pt.substring(0, min(pt.length, 40));
        print('${Now()} message ${pen('<<<')} ${redPen(topic)} ${bluePen(hl)}');
        // debug('message <<< $topic $pt');
        var l = subscriptions[topic];
        if (l != null) {
          l.forEach((cb) async {
            await cb(topic, pt);
          });
        }
        emit('message', null, {"topic": topic, "message": pt});
      } catch (e) {}
    });
  }

  int Now() {
    var n = DateTime.now().millisecondsSinceEpoch;
    return n;
  }

  Future<void> publish(String topic, message, {bool retain = true}) async {
    try {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      final String s = message is String ? message : JSON.stringify(message);
      final MqttQos r = retain ? MqttQos.atLeastOnce : MqttQos.atMostOnce;

      builder.addString(s);

      ansiColorDisabled = false;

      pen
        ..reset()
        ..white(bold: true);
      redPen
        ..reset()
        ..red(bold: true);
      bluePen
        ..reset()
        ..blue(bold: true);

      // pen.black(bold: true)(
      final hl = s.substring(0, min(s.length, 40));
      print('${Now()} message ${pen('>>>')} ${redPen(topic)} ${bluePen(hl)}');
      return client.publishMessage(topic, r, builder.payload);
    } catch (e, st) {
      print('publish ($topic, $message) exception $e $st');
    }
  }

  void subscribe(String topic, Callback? callback) {
    var l = subscriptions[topic];
    if (l == null) {
      subscriptions[topic] = [];
      l = subscriptions[topic];
    }
    if (callback != null) {
      subscriptions[topic]?.add(callback);
    }
    debug('subscribe $topic');
    int len = subscriptions[topic]?.length ?? 0;
    if (len == 1 || (len == 0 && callback == null)) {
      client.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  void unsubscribe(String topic, Callback callback) {
    var l = subscriptions[topic];
    if (l != null) {
      l.forEach((cb) {
        if (cb == callback) {
          l.remove(callback);
        }
      });
      if (l.isEmpty) {
        client.unsubscribe(topic, MqttQos.atMostOnce);
      }
    }
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    debug('subscribe $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    debug('OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus?.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      debug('OnDisconnected callback is solicited, this is correct');
    }
    exit(-1);
  }

  /// The successful connect callback
  void onConnected() {
    debug('OnConnected client callback - Client connection was sucessful');
    emit("connect", null, null);
  }

  /// Pong callback
  void pong() {
    //  debug('Ping response client callback invoked');
  }
}

final MQTT = Mqtt('nuc1');
