# Env - Environment variable helper

Handy method to examine environment variable or dump them all. This is a really simple singleton class.

```dart
import 'package:Env';

final debug = Env.get('DEBUG');
// or
Env.dump(); // prints env variables
```