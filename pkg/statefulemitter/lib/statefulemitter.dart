///
/// StatefulEmitter class
///
/// This is an EventEmitter that supports a React-like state member and
/// setState() method.
///
/// When setState() is called with a new state object, a statechange event
/// is emitted with oldState as arguments.  Callback can see newState by examining
/// the state member
///
/// Also provides sleep(), usleep(), and wait() methods that can be used within loops
/// to yield back to the event loop.
///

// @dart=2.12

library StatefulEmitter;

import 'package:eventify/eventify.dart';

class StatefulEmitter extends EventEmitter {
  Map<String,dynamic> _state = {};

  // constructor
  StatefulEmitter() {}

  // alias un to off
  void un(Listener listener) {
    off(listener);
  }

  // setter for state
  void set state(Map<String, dynamic>value) {
    final Map<String,dynamic> newState = {};
    _state.keys.forEach((k) => newState[k] = _state[k]);
    value.keys.forEach((k) => newState[k] = value[k]);
    var oldState = _state;
    _state = newState;
    emit('statechange', null, oldState );
  }

  // getter for state
  Map<String, dynamic> get state {
    return _state;
  }

  // React style setState (same as state setter)
  void setState(Map<String, dynamic>newState) {
    state = newState;
  }

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

}
