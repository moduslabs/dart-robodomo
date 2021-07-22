# Package myq

This is a dart package that provides an API to interact with the MyQ garage door openers and sensors.

## Usage:

Create a MyQ account using the Android or iPhone app.  You will need your credentials: MYQ_EMAIL and MYQ_PASSWORD.  You might want to set these as ENV variables.

### Example
```dart
import 'package: myq';

Future<void>main() async {
  try {
    final account = MyQ();
    final login = account.login(MYQ_EMAIL, MYQ_PASSWORD);
  }
  catch (e) {
    print('MyQ login failed');
    exit(1);
  }

  // Logged in account can call these (examine result with debugger to see their structure):
  final result = await account.getDevices(); // get all devices
  
  final result = await account.getDevice(serial_number); // get one device
  
  final result = await account.setDoorState(serial_number, 'OPEN' | 'CLOSED');
  final result = await account.setLightState(serial_number, 'ON' | 'OFF');
}

```