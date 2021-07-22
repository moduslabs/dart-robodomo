// @dart=2.12

import 'package:dio/dio.dart';
import 'package:env/Env.dart';
import 'package:mqtt/MQTT.dart';
import 'package:debug/debug.dart';
import 'package:hostbase/HostBase.dart';

final debug = Debug('WeatherHost');

final MQTT_HOST = Env.get('MQTT_HOST') ?? 'nuc1',
    TOPIC_ROOT = Env.get('TOPIC_ROOT') ?? 'weather';

final WEATHER_APP_ID = Env.get('WEATHER_APP_ID'),
    WEATHER_APP_CODE = Env.get('WEATHER_APP_CODE'),
    METRIC = Env.get('WEATHER_METRIC') ?? false;

final String WEATHER_POLL_TIME = Env.get('WEATHER_POLL_TIME') ?? '';
final int POLL_TIME =
    WEATHER_POLL_TIME != '' ? int.parse(WEATHER_POLL_TIME) : 60 * 5;

class WeatherHost extends HostBase {
  late String _zipCode, _name, _kind;

  final _responseConversions = {
    'skyInfo': 'int',
    'temperature': 'int',
    'comfort': 'float',
    'highTemperature': 'int',
    'lowTemperature': 'int',
    'humidity': 'float',
    'dewPoint': 'int',
    'windSpeed': 'int',
    'windDirection': 'int',
    'barometerPressure': 'float',
    'visibility': 'float',
    'ageMinutes': 'int',
    'activeAlerts': 'bool',
    'latitude': 'float',
    'longitude': 'float',
    'distance': 'float',
    'elevation': 'float',
    'moonPhase': 'float',
    'precipitationProbability': 'int',
    'dayOfWeek': 'int',
    //  localTime': 'int',
    //  airInfo': 'int',
    'beaufortScale': 'int',
    'utcTime': 'date',
    'timezone': 'int',
    'sunrise': 'sunrise',
    'sunset': 'sunset'
  };

  // late Map<String, dynamic> _device;
  WeatherHost(location)
      : super(MQTT_HOST, '$TOPIC_ROOT/${location["device"]}', false) {
    _name = location['name'];
    _zipCode = location['device'];
    _kind = 'zipcode';

    //
    debug('WeatherHost for $_name ($_zipCode)');
    run();
  }

  @override
  Future<void> command(cmd, args) async {
    print('Weather command received?  $cmd $args');
    return;
  }

  double _celsiusToFahrenheit(double c) {
    return (c * 9) / 5 + 32;
  }

  int _makeTime(String s) {
    final hourMinutes = s.split(':'),
        hour = int.parse(hourMinutes[0]),
        minute = int.parse(hourMinutes[1].replaceAll(RegExp(r'\D+'), '')),
        pm = s.toLowerCase().contains('pm');

    final local = DateTime.now().toLocal();
    final time = DateTime(
        local.year,
        local.month,
        local.day,
        pm ? hour + 12 : hour,
        minute,
        local.second,
        local.millisecond,
        local.microsecond);
    return time.millisecondsSinceEpoch ~/ 1000;
  }

  double _convertDouble(d) {
    if (d == null) {
      return 0.0;
    }
    switch (d.runtimeType.toString()) {
      case 'String':
        return double.parse(d);
      case 'int':
        return 1.0 * d;
      default:
        return d;
    }
  }

  /// process Map and convert the values from String to proper type
  Object _processResponse(o) {
    if (o == null) {
      return o;
    }

    if (o.runtimeType.toString().contains('List')) {
      final ret = [];
      o.forEach((value) {
        ret.add(_processResponse(value));
      });
      return ret;
    } else {
      final ret = {};
      o.forEach((key, value) {
        switch (_responseConversions[key]) {
          case null:
            ret[key] = null;
            break;
          case 'float':
            ret[key] = _convertDouble(value);
            break;
          case 'int':
            // print('value $value ${value.runtimeType}');
            ret[key] = (double.parse(value.toString())).round().toInt();
            break;
          case 'bool':
            ret[key] = value.toUpperCase() == 'TRUE';
            break;
          case 'date':
            ret[key] = DateTime.parse(value).millisecondsSinceEpoch / 1000;
            break;
          case 'sunrise':
          case 'sunset':
            ret[key] = _makeTime(value);
            break;
          default:
            ret[key] = value;
            break;
        }
      });
      return ret;
    }
  }

  Future<Map<String, dynamic>> _report(Map<String, dynamic> parameters) async {
    try {
      var url =
          'https://weather.api.here.com/weather/1.0/report.json?app_id=$WEATHER_APP_ID&app_code=$WEATHER_APP_CODE';
      parameters.forEach((String key, dynamic value) {
        url += '&$key=$value';
      });
      url += '&metric=$METRIC';
      final dio = Dio();
      final response = await dio.get(url);
      // print('response ${response.data["observations"]}');
      if (response.data == null) {
        HostBase.abort('NULL response data $url');
      }
      return response.data;
    } catch (e) {
      print('Exception in $_zipCode report: $e');
    }
    return {};
  }

  Future<Map<dynamic, dynamic>> _pollObservation() async {
    final res = await _report(
        {'product': 'observation', _kind: _zipCode, 'oneobservation': true});
    final o =
        _processResponse(res['observations']['location'][0]['observation'][0])
            as Map<dynamic, dynamic>;
    o['temperature'] = _celsiusToFahrenheit(o['temperature'].toDouble());
    return o;
  }

  Future<Object?> _pollWeekly() async {
    final res = await _report({
      'product': 'forecast_7days_simple',
      _kind: _zipCode,
      'oneobservation': true
    });
    var o =
        _processResponse(res['dailyForecasts']['forecastLocation']['forecast']);
    return o;
  }

  Future<Object?> _pollHourly() async {
    final res = await _report({
      'product': 'forecast_hourly',
      _kind: _zipCode,
      'oneobservation': true
    });
    var o = _processResponse(
        res['hourlyForecasts']['forecastLocation']['forecast']);
    return o;
  }

  Future<Object?> _pollForecast() async {
    final res = await _report(
        {'product': 'forecast_7days', _kind: _zipCode, 'oneobservation': true});
    var o = _processResponse(res['forecasts']['forecastLocation']['forecast']);
    return o;
  }

  Future<Map<dynamic, dynamic>> _pollAstronomy() async {
    final res = await _report({
      'product': 'forecast_astronomy',
      _kind: _zipCode,
      'oneobservation': true
    });
    var o = _processResponse(res['astronomy']['astronomy'][0]);
    return o as Map<dynamic, dynamic>;
  }

  Future<Map<dynamic, dynamic>> _pollAlerts() async {
    try {
      final res = await _report(
          {'product': 'alerts', _kind: _zipCode, 'oneobservation': true});
      var o = _processResponse(res['alerts']);
      return o as Map<dynamic, dynamic>;
    }
    catch (e, st) {
      print('pollAlerts $e');
      print(st);
    }
    return {};
  }

  /// run()
  /// Forever login, then poll device status
  @override
  Future<Never> run() async {
    for (;;) {
      final observation = await _pollObservation();
      final weekly = await _pollWeekly();
      final hourly = await _pollHourly();
      final forecast = await _pollForecast();
      final astronomy = await _pollAstronomy();
      final alerts = await _pollAlerts();
      // observation['sunrise'] = astronomy['sunrise'];
      // observation['sunset'] = astronomy['sunset'];
      state = {
        'sunrise': astronomy['sunrise'],
        'sunset': astronomy['sunset'],
        'astronomy': astronomy,
        'observation': {
          ...observation,
          'sunrise': astronomy['sunrise'],
          'sunset': astronomy['sunset'],
        },
        'hourly': hourly,
        'forecast': forecast,
        'alerts': alerts,
        'weekly': weekly,
      };
      // examine(a);
      // print('o $o');
      await HostBase.wait(POLL_TIME);
    }
  }
}

Future<Never> main(List<String> arguments) async {
  final hosts = [];

  if (WEATHER_APP_ID == null) {
    HostBase.abort('Env variable WEATHER_APP_ID is required');
  }
  if (WEATHER_APP_CODE == null) {
    HostBase.abort('Env variable WEATHER_APP_CODE is required');
  }

  await MQTT.connect();
  var config = await HostBase.getSetting('config') ?? {};
  examine('Config', config['weather']);
  // print('config ${config["weather"]}');
  //
  final locations = config['weather']['locations'];
  locations.forEach((location) {
    hosts.add(WeatherHost(location));
  });

  for (;;) {
    await HostBase.sleep(120);
  }
}
