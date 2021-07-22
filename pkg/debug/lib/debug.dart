/// debug function
///
/// Instance of local Logger class
///
/// provides debug() functionality similar/identical to the JavaScript one
/// by TJ Holowaychuck
///
/// Use:
///   import 'package:debug/debug.dart';
///   final debug = Debug('identifier');
///   ...
///   debug('print some message');
///
/// If 'identifier' (no quotes) is defined in ENV variable DEBUG, then the
/// message is printed, along with elapsed time.
///
/// DEBUG has the format: id;id;id... TODO: wildcards
///
library debug;

import 'package:dart_console/dart_console.dart';
import 'package:env_get/env_get.dart';

final console = Console();

int Now() {
  var n = DateTime.now().millisecondsSinceEpoch;
  return n;
}

final lastCall = Now();

class Logger {
  var prompt;
  ConsoleColor fg = ConsoleColor.black, bg = ConsoleColor.white;
  var log;

  // foreground/background colors are pairs that work well (e.g. black on white)
  // nextColor defines what color scheme is used for the current/next instance
  // of debug (so each module/identifier gets a unique color scheme)
  static int nextColor = 0;

  /// list of foreground colors
  final List<ConsoleColor> fg_colors = [
    ConsoleColor.brightBlue,
    ConsoleColor.brightRed,
    ConsoleColor.green,
    ConsoleColor.cyan,
    ConsoleColor.blue,
    ConsoleColor.red,
    ConsoleColor.brightCyan,
    ConsoleColor.brightGreen,
    ConsoleColor.black,
    ConsoleColor.brightBlack,
  ];

  /// list of background colors
  final List<ConsoleColor> bg_colors = [
    ConsoleColor.black,
    ConsoleColor.black,
    ConsoleColor.black,
    ConsoleColor.black,
    ConsoleColor.black,
    ConsoleColor.black,
    ConsoleColor.black,
    ConsoleColor.black,
    ConsoleColor.white,
    ConsoleColor.white,
  ];

  /// constructor(key)
  ///
  /// key is the unique identifer defined in DEBUG env variable
  Logger(String key) {
    prompt = key;
    fg = fg_colors[nextColor];
    bg = bg_colors[nextColor];

    if (++nextColor >= fg_colors.length) {
      nextColor = 0;
    }

    final debug = Env.get('DEBUG');
    if (debug == null) {
      log = (s) {};
    } else {
      final parts = debug.split(';');
      if (parts.contains(prompt)) {
        log = (s) {
          var now = Now(), elapsed = now - lastCall;
          console.setForegroundColor(fg);
          console.setBackgroundColor(bg);

          console.write('$now $prompt ');
          console.resetColorAttributes();
          console.write('$s ');
          console.setForegroundColor(fg);
          console.setBackgroundColor(bg);
          console.writeLine('+${elapsed}ms');
          console.resetColorAttributes();
        };
      } else {
        log = (s) {};
      }
    }
  }
}

/// Debug(key)
///
/// returns a debug(s) function that you can call to optionally print
/// out status/debugging messages
Function(String s) Debug(String name) {
  var d = Logger(name);
  return d.log;
}
