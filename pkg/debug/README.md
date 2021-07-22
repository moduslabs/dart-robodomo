# debug package

This package provides logging facility nearly identical to the one for NodeJS/Browser by TJ Holwaychuck (npm install
debug).

You create a debug function by calling Debug(String identifier). If identifier is present in the DEBUG environment
variable, when you call debug(String s), the string is printed. If identifier is not present in the DEBUG environment
variable, then debug(String s) prints nothing.

Each successive instance of debug() function created gets its own color scheme when printing.  

At the end of each line printed is the elapsed time in milliseconds, so you can time how long between your debug() calls.

## Usage

Sample usage example:

```dart
import 'package:debug/debug.dart';

final debug = Debug('identifier');

main() {
  debug('maybe I get printed');
}
```

## Features and bugs

[comment]: <> (Please file feature requests and bugs at the [issue tracker][tracker].)

[comment]: <> ([tracker]: http://example.com/issues/replaceme)

[comment]: <> ([license]&#40;https://github.com/dart-lang/stagehand/blob/master/LICENSE&#41;.)
