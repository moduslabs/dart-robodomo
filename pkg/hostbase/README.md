# HostBase Module

HostBase is an abstract class that extends StateFulEmitter.

For RoboDomo servers/microservices, we create an instance of a HostBase (inheritor) for each "thing" that the microservice controls or monitors.

For example, you would have a HostBase for each Apple TV in the home/office.

## Usage

```dart
import 'package:hostbase/hostbase.dart';

class AppleTVHost extends HostBase {
  AppleTVHost(String appleTVIpAddress) : super(MQTT_HOST, "appletv", false) {
    // initializations
  }
 
  // this MUST be provided.  It is called once to asynchronously poll
  Never run() async {
    // loop forever
    for (;;) {
      // poll the apple tv
      HostBase.wait(1); // async sleep 1 second
    }
  }
}
```

